import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week03_patterns/composite.dart';
import 'package:week03_patterns/decorator.dart';

class Week03DecoratorCompositePage extends StatelessWidget {
  const Week03DecoratorCompositePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _Week03DecoratorCompositeView());
  }
}

class _Week03DecoratorCompositeView extends ConsumerWidget {
  const _Week03DecoratorCompositeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3주차 · Decorator & Composite'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const <Widget>[
          _DecoratorSection(),
          SizedBox(height: 24),
          _CompositeSection(),
        ],
      ),
    );
  }
}

class _DecoratorSection extends ConsumerWidget {
  const _DecoratorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DecoratorPreviewState state = ref.watch(_decoratorPreviewProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Decorator · 위젯 파이프라인', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Spacing ${state.config.spacing.toStringAsFixed(0)} px'),
            Slider(
              min: 4,
              max: 40,
              divisions: 18,
              label: '${state.config.spacing.toStringAsFixed(0)}px',
              value: state.config.spacing,
              onChanged: (double value) {
                ref
                    .read(_decoratorPreviewProvider.notifier)
                    .updateSpacing(value);
              },
            ),
            const SizedBox(height: 8),
            Text('Elevation ${state.config.elevation} dp'),
            Slider(
              min: 0,
              max: 12,
              divisions: 12,
              label: '${state.config.elevation}dp',
              value: state.config.elevation.toDouble(),
              onChanged: (double value) {
                ref
                    .read(_decoratorPreviewProvider.notifier)
                    .updateElevation(value.round());
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Analytics hook 적용'),
              subtitle: const Text('ServiceHookDecorator로 API 비용을 시뮬레이션'),
              value: state.config.includeAnalytics,
              onChanged: (bool value) {
                ref
                    .read(_decoratorPreviewProvider.notifier)
                    .toggleAnalytics(value);
              },
            ),
            const Divider(height: 32),
            Text('Layers', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: state.widget.layers
                  .map((String layer) => Chip(label: Text(layer)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text('Service Hooks', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            if (state.widget.serviceHooks.isEmpty)
              const Text('등록된 훅이 없습니다.')
            else
              Wrap(
                spacing: 6,
                children: state.widget.serviceHooks
                    .map((String hook) => Chip(label: Text(hook)))
                    .toList(),
              ),
            const SizedBox(height: 12),
            Text(
              '예상 비용: ${state.widget.estimatedBuildCost.toStringAsFixed(2)} ms · '
              '레이턴시: ${state.widget.estimatedLatency.inMilliseconds} ms',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Performance log', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Column(
              children: state.entries
                  .map(
                    (PerformanceEntry entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.decorator),
                      subtitle: Text(
                        '${entry.elapsed.inMicroseconds}µs · '
                        'layers=${entry.layerCount} · '
                        'cost=${entry.estimatedCost.toStringAsFixed(2)}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompositeSection extends ConsumerWidget {
  const _CompositeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StyleSnapshot snapshot = ref.watch(themeTreeProvider);
    final HeadlineVariant variant = ref.watch(_headlineVariantProvider);
    final bool badgeAlert = ref.watch(_badgeAlertProvider);
    final ThemeTreeNotifier notifier = ref.read(themeTreeProvider.notifier);
    final outline = notifier.outline();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Composite · 스타일 트리', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('헤드라인 스타일 선택'),
            const SizedBox(height: 8),
            SegmentedButton<HeadlineVariant>(
              segments: const <ButtonSegment<HeadlineVariant>>[
                ButtonSegment<HeadlineVariant>(
                  value: HeadlineVariant.regular,
                  label: Text('기본'),
                ),
                ButtonSegment<HeadlineVariant>(
                  value: HeadlineVariant.emphasis,
                  label: Text('강조'),
                ),
                ButtonSegment<HeadlineVariant>(
                  value: HeadlineVariant.accessibility,
                  label: Text('가독성'),
                ),
              ],
              selected: <HeadlineVariant>{variant},
              onSelectionChanged: (Set<HeadlineVariant> selection) {
                if (selection.isEmpty) {
                  return;
                }
                final HeadlineVariant next = selection.first;
                ref.read(_headlineVariantProvider.notifier).state = next;
                _swapLeaf(
                  context,
                  notifier,
                  targetName: 'headline',
                  replacement: _headlineLeaf(next),
                );
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Badge 경고 강조'),
              subtitle: const Text('위험 티켓일 때 색상/라운드를 변경'),
              value: badgeAlert,
              onChanged: (bool value) {
                ref.read(_badgeAlertProvider.notifier).state = value;
                _swapLeaf(
                  context,
                  notifier,
                  targetName: 'badge',
                  replacement: _badgeLeaf(alert: value),
                );
              },
            ),
            const Divider(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text('총 레이어 ${snapshot.appliedOrder.length}개')),
                Chip(
                  label: Text(
                    '비용 ${snapshot.totalCost.toStringAsFixed(2)} · '
                    '지연 ${snapshot.totalLatency.inMilliseconds}ms',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Attributes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: snapshot.attributes.entries
                  .map(
                    (MapEntry<String, Object?> entry) => Text(
                      '${entry.key}: ${entry.value}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Tree outline', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                outline.trim(),
                style: const TextStyle(fontFamily: 'monospace', height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum HeadlineVariant { regular, emphasis, accessibility }

final _decoratorPreviewProvider = StateNotifierProvider.autoDispose<
    _DecoratorPreviewController, DecoratorPreviewState>(
  (Ref ref) => _DecoratorPreviewController(),
);

final _headlineVariantProvider = StateProvider.autoDispose<HeadlineVariant>(
  (Ref ref) => HeadlineVariant.regular,
);

final _badgeAlertProvider = StateProvider.autoDispose<bool>(
  (Ref ref) => false,
);

class DecoratorPreviewState {
  const DecoratorPreviewState({
    required this.config,
    required this.widget,
    required this.entries,
  });

  final DecoratorConfig config;
  final StyledWidget widget;
  final List<PerformanceEntry> entries;
}

class DecoratorConfig {
  const DecoratorConfig({
    this.spacing = 12,
    this.elevation = 6,
    this.includeAnalytics = true,
  });

  final double spacing;
  final int elevation;
  final bool includeAnalytics;

  DecoratorConfig copyWith({
    double? spacing,
    int? elevation,
    bool? includeAnalytics,
  }) {
    return DecoratorConfig(
      spacing: spacing ?? this.spacing,
      elevation: elevation ?? this.elevation,
      includeAnalytics: includeAnalytics ?? this.includeAnalytics,
    );
  }
}

class _DecoratorPreviewController extends StateNotifier<DecoratorPreviewState> {
  _DecoratorPreviewController() : super(_buildState(const DecoratorConfig()));

  void updateSpacing(double spacing) {
    state = _buildState(state.config.copyWith(spacing: spacing));
  }

  void updateElevation(int elevation) {
    state = _buildState(state.config.copyWith(elevation: elevation));
  }

  void toggleAnalytics(bool enabled) {
    state = _buildState(state.config.copyWith(includeAnalytics: enabled));
  }
}

DecoratorPreviewState _buildState(DecoratorConfig config) {
  final PerformanceLog log = PerformanceLog();
  WidgetFeature feature = BaseWidgetFeature();
  feature = SpacingDecorator(feature, spacing: config.spacing);
  feature = SurfaceDecorator(feature, elevation: config.elevation);
  if (config.includeAnalytics) {
    feature = ServiceHookDecorator(feature, hook: 'analytics');
  }
  feature = ProfilingDecorator(
    inner: feature,
    label: 'ui.feed-card.pipeline',
    log: log,
  );

  final StyledWidget widget = feature.build(
    const RenderRequest(
      widgetId: 'feed-card',
      baseCost: 1.2,
      initialLatency: Duration(milliseconds: 3),
      userSegments: <String>['premium'],
    ),
  );

  return DecoratorPreviewState(
    config: config,
    widget: widget,
    entries: log.entries,
  );
}

void _swapLeaf(
  BuildContext context,
  ThemeTreeNotifier notifier, {
  required String targetName,
  required ThemeLeaf replacement,
}) {
  try {
    notifier.swapLeaf(targetName: targetName, replacement: replacement);
  } on ThemeTargetNotFound catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${error.target} 노드를 찾지 못했습니다.')),
    );
  }
}

ThemeLeaf _headlineLeaf(HeadlineVariant variant) {
  switch (variant) {
    case HeadlineVariant.regular:
      return ThemeLeaf(
        name: 'headline',
        attributes: <String, Object?>{
          'headlineFontSize': 20,
          'headlineWeight': 'w600',
        },
        rebuildCost: 0.7,
        latency: const Duration(milliseconds: 2),
      );
    case HeadlineVariant.emphasis:
      return ThemeLeaf(
        name: 'headline',
        attributes: <String, Object?>{
          'headlineFontSize': 24,
          'headlineWeight': 'w700',
          'headlineGradient': 'primary→secondary',
        },
        rebuildCost: 0.95,
        latency: const Duration(milliseconds: 3),
      );
    case HeadlineVariant.accessibility:
      return ThemeLeaf(
        name: 'headline',
        attributes: <String, Object?>{
          'headlineFontSize': 22,
          'headlineWeight': 'w500',
          'headlineLineHeight': 1.4,
        },
        rebuildCost: 0.8,
        latency: const Duration(milliseconds: 3),
      );
  }
}

ThemeLeaf _badgeLeaf({required bool alert}) {
  if (!alert) {
    return ThemeLeaf(
      name: 'badge',
      attributes: <String, Object?>{
        'color': '#FF8A65',
        'borderRadius': 8,
      },
      rebuildCost: 0.4,
      latency: const Duration(milliseconds: 1),
    );
  }
  return ThemeLeaf(
    name: 'badge',
    attributes: <String, Object?>{
      'color': '#E53935',
      'borderRadius': 4,
      'icon': 'warning',
    },
    rebuildCost: 0.55,
    latency: const Duration(milliseconds: 2),
  );
}
