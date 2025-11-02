import 'package:riverpod/riverpod.dart';

import '../shared/rebuild_counter.dart';

class ThemeTargetNotFound implements Exception {
  ThemeTargetNotFound(this.target);

  final String target;

  @override
  String toString() => 'ThemeTargetNotFound(target: $target)';
}

class StyleSnapshot {
  const StyleSnapshot({
    required this.name,
    required this.appliedOrder,
    required this.attributes,
    required this.totalCost,
    required this.totalLatency,
    required this.costBreakdown,
  });

  final String name;
  final List<String> appliedOrder;
  final Map<String, Object?> attributes;
  final double totalCost;
  final Duration totalLatency;
  final Map<String, double> costBreakdown;
}

sealed class ThemeNode {
  const ThemeNode({required this.name});

  final String name;

  StyleSnapshot compose();

  ThemeNode replaceLeaf(String targetName, ThemeLeaf replacement);

  void describe(StringBuffer buffer, {int depth = 0});
}

class ThemeLeaf extends ThemeNode {
  ThemeLeaf({
    required super.name,
    required Map<String, Object?> attributes,
    this.rebuildCost = 0.2,
    this.latency = const Duration(milliseconds: 1),
  }) : _attributes = Map.unmodifiable(attributes);

  final Map<String, Object?> _attributes;
  final double rebuildCost;
  final Duration latency;

  Map<String, Object?> get attributes => _attributes;

  @override
  StyleSnapshot compose() {
    return StyleSnapshot(
      name: name,
      appliedOrder: <String>[name],
      attributes: _attributes,
      totalCost: rebuildCost,
      totalLatency: latency,
      costBreakdown: <String, double>{name: rebuildCost},
    );
  }

  @override
  ThemeNode replaceLeaf(String targetName, ThemeLeaf replacement) {
    if (name == targetName) {
      return replacement;
    }
    throw ThemeTargetNotFound(targetName);
  }

  @override
  void describe(StringBuffer buffer, {int depth = 0}) {
    buffer.writeln(
      '${'  ' * depth}- leaf $name attrs=${_attributes.keys.join(', ')} cost=${rebuildCost.toStringAsFixed(2)}',
    );
  }
}

class ThemeBranch extends ThemeNode {
  ThemeBranch({
    required super.name,
    required List<ThemeNode> children,
    this.overheadCost = 0,
    this.latency = Duration.zero,
  }) : _children = List<ThemeNode>.unmodifiable(children);

  final List<ThemeNode> _children;
  final double overheadCost;
  final Duration latency;

  List<ThemeNode> get children => _children;

  @override
  StyleSnapshot compose() {
    final Map<String, Object?> aggregated = <String, Object?>{};
    final Map<String, double> breakdown = <String, double>{
      name: overheadCost,
    };
    var totalCost = overheadCost;
    var totalLatency = latency;
    final List<String> order = <String>[name];

    for (final ThemeNode child in _children) {
      final StyleSnapshot snapshot = child.compose();
      aggregated.addAll(snapshot.attributes);
      totalCost += snapshot.totalCost;
      totalLatency += snapshot.totalLatency;
      order.addAll(snapshot.appliedOrder);
      snapshot.costBreakdown.forEach((String key, double value) {
        breakdown.update(key, (double previous) => previous + value,
            ifAbsent: () => value);
      });
    }

    return StyleSnapshot(
      name: name,
      appliedOrder: order,
      attributes: aggregated,
      totalCost: totalCost,
      totalLatency: totalLatency,
      costBreakdown: breakdown,
    );
  }

  @override
  ThemeNode replaceLeaf(String targetName, ThemeLeaf replacement) {
    final (ThemeBranch updated, bool replaced) =
        _replaceLeafInternal(targetName, replacement);
    if (!replaced) {
      throw ThemeTargetNotFound(targetName);
    }
    return updated;
  }

  (ThemeBranch, bool) _replaceLeafInternal(
      String targetName, ThemeLeaf replacement) {
    final List<ThemeNode> updatedChildren = <ThemeNode>[];
    var replaced = false;

    for (final ThemeNode child in _children) {
      switch (child) {
        case ThemeLeaf leaf:
          if (leaf.name == targetName) {
            updatedChildren.add(replacement);
            replaced = true;
          } else {
            updatedChildren.add(leaf);
          }
          break;
        case ThemeBranch branch:
          final (ThemeBranch nextBranch, bool childReplaced) =
              branch._replaceLeafInternal(targetName, replacement);
          updatedChildren.add(nextBranch);
          replaced = replaced || childReplaced;
          break;
      }
    }

    return (
      ThemeBranch(
        name: name,
        children: updatedChildren,
        overheadCost: overheadCost,
        latency: latency,
      ),
      replaced,
    );
  }

  @override
  void describe(StringBuffer buffer, {int depth = 0}) {
    buffer.writeln(
      '${'  ' * depth}- branch $name cost=${overheadCost.toStringAsFixed(2)} latency=${latency.inMilliseconds}ms',
    );
    for (final ThemeNode child in _children) {
      child.describe(buffer, depth: depth + 1);
    }
  }
}

class ThemeTreeNotifier extends Notifier<StyleSnapshot> {
  late ThemeBranch _root;

  @override
  StyleSnapshot build() {
    _root = ThemeBranch(
      name: 'root',
      overheadCost: 0.4,
      latency: const Duration(milliseconds: 2),
      children: <ThemeNode>[
        ThemeLeaf(
          name: 'container',
          attributes: <String, Object?>{
            'padding': 12,
            'background': '#FAFAFA',
          },
          rebuildCost: 0.6,
          latency: const Duration(milliseconds: 2),
        ),
        ThemeBranch(
          name: 'typography',
          overheadCost: 0.2,
          latency: const Duration(milliseconds: 1),
          children: <ThemeNode>[
            ThemeLeaf(
              name: 'headline',
              attributes: <String, Object?>{
                'headlineFontSize': 20,
                'headlineWeight': 'w600',
              },
              rebuildCost: 0.7,
              latency: const Duration(milliseconds: 2),
            ),
            ThemeLeaf(
              name: 'caption',
              attributes: <String, Object?>{
                'captionFontSize': 12,
                'letterSpacing': 0.2,
              },
              rebuildCost: 0.3,
              latency: const Duration(milliseconds: 1),
            ),
          ],
        ),
        ThemeLeaf(
          name: 'badge',
          attributes: <String, Object?>{
            'color': '#FF8A65',
            'borderRadius': 8,
          },
          rebuildCost: 0.4,
          latency: const Duration(milliseconds: 1),
        ),
      ],
    );
    return _root.compose();
  }

  void swapLeaf({required String targetName, required ThemeLeaf replacement}) {
    final (ThemeBranch updatedRoot, bool replaced) =
        _root._replaceLeafInternal(targetName, replacement);
    if (!replaced) {
      throw ThemeTargetNotFound(targetName);
    }
    _root = updatedRoot;
    state = _root.compose();
  }

  String outline() {
    final StringBuffer buffer = StringBuffer();
    _root.describe(buffer);
    return buffer.toString();
  }
}

final themeTreeProvider = NotifierProvider<ThemeTreeNotifier, StyleSnapshot>(
  ThemeTreeNotifier.new,
  name: 'themeTreeProvider',
);

void main() {
  final RebuildCounterObserver observer = RebuildCounterObserver();
  final ProviderContainer container =
      ProviderContainer(observers: <ProviderObserver>[observer]);

  final StyleSnapshot initial = container.read(themeTreeProvider);
  final ThemeTreeNotifier notifier = container.read(themeTreeProvider.notifier);

  print('Initial style');
  print('  order=${initial.appliedOrder.join(' -> ')}');
  print('  cost=${initial.totalCost.toStringAsFixed(2)}');
  print('  latency=${initial.totalLatency.inMilliseconds}ms');
  print('Tree outline:\n${notifier.outline()}');

  notifier.swapLeaf(
    targetName: 'headline',
    replacement: ThemeLeaf(
      name: 'headline',
      attributes: <String, Object?>{
        'headlineFontSize': 22,
        'headlineWeight': 'w700',
        'headlineLineHeight': 1.3,
      },
      rebuildCost: 0.85,
      latency: Duration(milliseconds: 3),
    ),
  );

  final StyleSnapshot updated = container.read(themeTreeProvider);
  print('Updated style');
  print('  order=${updated.appliedOrder.join(' -> ')}');
  print('  cost=${updated.totalCost.toStringAsFixed(2)}');
  print('  latency=${updated.totalLatency.inMilliseconds}ms');
  print('Provider rebuild counts: ${observer.snapshot()}');

  container.dispose();
}
