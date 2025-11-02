import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import 'package:week03_patterns/decorator.dart';
import 'package:week03_patterns/shared.dart';

void main() {
  group('Decorator pipeline', () {
    test('composes layers, hooks, and metrics deterministically', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final WidgetFeature feature = container.read(widgetFeatureProvider);
      final StyledWidget result =
          feature.build(const RenderRequest(widgetId: 'feed-card'));

      expect(result.layers,
          <String>['base:feed-card', 'spacing:12px', 'surface:elevation=6']);
      expect(result.serviceHooks, <String>['analytics']);
      expect(result.estimatedBuildCost, closeTo(1.84, 0.001));
      expect(result.estimatedLatency.inMicroseconds, 8870);
    });

    test('profiling decorator records elapsed time and provider rebuilds', () {
      final RebuildCounterObserver observer = RebuildCounterObserver();
      final ProviderContainer container =
          ProviderContainer(observers: <ProviderObserver>[observer]);
      addTearDown(container.dispose);

      final WidgetFeature feature = container.read(widgetFeatureProvider);
      final PerformanceLog log = container.read(performanceLogProvider);

      feature.build(const RenderRequest(widgetId: 'feed-card'));

      expect(log.entries, isNotEmpty);
      expect(log.entries.single.decorator, 'feed-card.pipeline');
      expect(observer.countFor(widgetFeatureProvider) >= 1, isTrue);
    });

    test('service hook decorator ignores duplicate hooks', () {
      WidgetFeature feature = BaseWidgetFeature();
      feature = ServiceHookDecorator(feature, hook: 'analytics');
      feature = ServiceHookDecorator(feature, hook: 'analytics');

      final StyledWidget result =
          feature.build(const RenderRequest(widgetId: 'feed-card'));

      expect(result.serviceHooks, <String>['analytics']);
      expect(result.estimatedBuildCost, closeTo(1.3, 0.001));
      expect(result.estimatedLatency.inMilliseconds, 8);
    });

    test('performance log aggregates totals and supports clear', () {
      final PerformanceLog log = PerformanceLog()
        ..record(
          const PerformanceEntry(
            decorator: 'spacing',
            elapsed: Duration(milliseconds: 2),
            layerCount: 2,
            estimatedCost: 1.2,
          ),
        )
        ..record(
          const PerformanceEntry(
            decorator: 'surface',
            elapsed: Duration(milliseconds: 3),
            layerCount: 3,
            estimatedCost: 1.6,
          ),
        );

      expect(log.totalElapsed, const Duration(milliseconds: 5));
      expect(log.entries.length, 2);

      log.clear();
      expect(log.entries, isEmpty);
    });
  });
}
