import 'package:riverpod/riverpod.dart';

import '../shared/rebuild_counter.dart';

class RenderRequest {
  const RenderRequest({
    required this.widgetId,
    this.baseCost = 1.0,
    this.initialLatency = const Duration(milliseconds: 2),
    this.userSegments = const <String>[],
  });

  final String widgetId;
  final double baseCost;
  final Duration initialLatency;
  final List<String> userSegments;
}

class StyledWidget {
  const StyledWidget({
    required this.id,
    required this.layers,
    required this.serviceHooks,
    required this.estimatedBuildCost,
    required this.estimatedLatency,
  });

  final String id;
  final List<String> layers;
  final List<String> serviceHooks;
  final double estimatedBuildCost;
  final Duration estimatedLatency;

  StyledWidget appendLayer(
    String layer, {
    double costDelta = 0,
    Duration latencyDelta = Duration.zero,
  }) {
    return StyledWidget(
      id: id,
      layers: <String>[...layers, layer],
      serviceHooks: serviceHooks,
      estimatedBuildCost: estimatedBuildCost + costDelta,
      estimatedLatency: estimatedLatency + latencyDelta,
    );
  }

  StyledWidget appendHook(
    String hook, {
    double costDelta = 0,
    Duration latencyDelta = Duration.zero,
  }) {
    if (serviceHooks.contains(hook)) {
      return StyledWidget(
        id: id,
        layers: layers,
        serviceHooks: serviceHooks,
        estimatedBuildCost: estimatedBuildCost,
        estimatedLatency: estimatedLatency,
      );
    }
    return StyledWidget(
      id: id,
      layers: layers,
      serviceHooks: <String>[...serviceHooks, hook],
      estimatedBuildCost: estimatedBuildCost + costDelta,
      estimatedLatency: estimatedLatency + latencyDelta,
    );
  }
}

abstract class WidgetFeature {
  StyledWidget build(RenderRequest request);
}

class BaseWidgetFeature implements WidgetFeature {
  @override
  StyledWidget build(RenderRequest request) {
    return StyledWidget(
      id: request.widgetId,
      layers: <String>['base:${request.widgetId}'],
      serviceHooks: const <String>[],
      estimatedBuildCost: request.baseCost,
      estimatedLatency: request.initialLatency,
    );
  }
}

abstract class WidgetFeatureDecorator implements WidgetFeature {
  WidgetFeatureDecorator(this.inner);

  final WidgetFeature inner;

  @override
  StyledWidget build(RenderRequest request) {
    final StyledWidget base = inner.build(request);
    return transform(base, request);
  }

  StyledWidget transform(StyledWidget base, RenderRequest request);
}

class SpacingDecorator extends WidgetFeatureDecorator {
  SpacingDecorator(super.inner, {required this.spacing});

  final double spacing;

  @override
  StyledWidget transform(StyledWidget base, RenderRequest request) {
    final double costDelta = spacing * 0.02;
    final Duration latencyDelta =
        Duration(microseconds: (spacing * 40).round());
    return base.appendLayer(
      'spacing:${spacing.toStringAsFixed(0)}px',
      costDelta: costDelta,
      latencyDelta: latencyDelta,
    );
  }
}

class SurfaceDecorator extends WidgetFeatureDecorator {
  SurfaceDecorator(super.inner, {required this.elevation});

  final int elevation;

  @override
  StyledWidget transform(StyledWidget base, RenderRequest request) {
    return base.appendLayer(
      'surface:elevation=$elevation',
      costDelta: elevation * 0.05,
      latencyDelta: Duration(microseconds: elevation * 65),
    );
  }
}

class ServiceHookDecorator extends WidgetFeatureDecorator {
  ServiceHookDecorator(
    super.inner, {
    required this.hook,
    this.costPenalty = 0.3,
    this.latencyPenalty = const Duration(milliseconds: 6),
  });

  final String hook;
  final double costPenalty;
  final Duration latencyPenalty;

  @override
  StyledWidget transform(StyledWidget base, RenderRequest request) {
    return base.appendHook(
      hook,
      costDelta: costPenalty,
      latencyDelta: latencyPenalty,
    );
  }
}

class PerformanceEntry {
  const PerformanceEntry({
    required this.decorator,
    required this.elapsed,
    required this.layerCount,
    required this.estimatedCost,
  });

  final String decorator;
  final Duration elapsed;
  final int layerCount;
  final double estimatedCost;
}

class PerformanceLog {
  final List<PerformanceEntry> _entries = <PerformanceEntry>[];

  List<PerformanceEntry> get entries => List.unmodifiable(_entries);

  void record(PerformanceEntry entry) {
    _entries.add(entry);
  }

  Duration get totalElapsed {
    return _entries.fold<Duration>(
      Duration.zero,
      (Duration acc, PerformanceEntry entry) => acc + entry.elapsed,
    );
  }

  void clear() => _entries.clear();
}

class ProfilingDecorator extends WidgetFeatureDecorator {
  ProfilingDecorator({
    required WidgetFeature inner,
    required this.label,
    required this.log,
  }) : super(inner);

  final String label;
  final PerformanceLog log;

  @override
  StyledWidget build(RenderRequest request) {
    final Stopwatch stopwatch = Stopwatch()..start();
    final StyledWidget result = super.build(request);
    stopwatch.stop();
    log.record(
      PerformanceEntry(
        decorator: label,
        elapsed: stopwatch.elapsed,
        layerCount: result.layers.length,
        estimatedCost: result.estimatedBuildCost,
      ),
    );
    return result;
  }

  @override
  StyledWidget transform(StyledWidget base, RenderRequest request) {
    // 체인 구조를 변경하지 않고 성능만 기록한다.
    return base;
  }
}

final performanceLogProvider = Provider<PerformanceLog>(
  (ref) {
    final PerformanceLog log = PerformanceLog();
    ref.onDispose(log.clear);
    return log;
  },
  name: 'performanceLogProvider',
);

final widgetFeatureProvider = Provider<WidgetFeature>(
  (ref) {
    final PerformanceLog log = ref.watch(performanceLogProvider);
    WidgetFeature feature = BaseWidgetFeature();
    feature = SpacingDecorator(feature, spacing: 12);
    feature = SurfaceDecorator(feature, elevation: 6);
    feature = ServiceHookDecorator(feature, hook: 'analytics');
    feature = ProfilingDecorator(
      inner: feature,
      label: 'feed-card.pipeline',
      log: log,
    );
    return feature;
  },
  name: 'widgetFeatureProvider',
);

void main() {
  final RebuildCounterObserver observer = RebuildCounterObserver();
  final ProviderContainer container =
      ProviderContainer(observers: <ProviderObserver>[observer]);
  final WidgetFeature feature = container.read(widgetFeatureProvider);

  final RenderRequest request = RenderRequest(
    widgetId: 'feed-card',
    userSegments: const <String>['premium'],
    baseCost: 1.2,
    initialLatency: const Duration(milliseconds: 3),
  );
  final StyledWidget result = feature.build(request);
  final PerformanceLog log = container.read(performanceLogProvider);

  print('Decorated widget:');
  print('  id=${result.id} layers=${result.layers.join(' > ')}');
  print('  hooks=${result.serviceHooks.join(', ')}');
  print('  cost=${result.estimatedBuildCost.toStringAsFixed(2)}ms');
  print('  latency=${result.estimatedLatency.inMilliseconds}ms');

  print('Performance log:');
  for (final PerformanceEntry entry in log.entries) {
    print(
        '  ${entry.decorator}: ${entry.elapsed.inMicroseconds}µs, layers=${entry.layerCount}');
  }

  print('Provider rebuild counts: ${observer.snapshot()}');
  container.dispose();
}
