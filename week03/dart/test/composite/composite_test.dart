import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import 'package:week03_patterns/composite.dart';
import 'package:week03_patterns/shared.dart';

void main() {
  group('ThemeTreeNotifier', () {
    test('initial composition merges cost and attributes', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final StyleSnapshot snapshot = container.read(themeTreeProvider);

      expect(snapshot.attributes['padding'], 12);
      expect(snapshot.attributes['background'], '#FAFAFA');
      expect(snapshot.attributes['headlineFontSize'], 20);
      expect(snapshot.attributes['captionFontSize'], 12);
      expect(snapshot.attributes['color'], '#FF8A65');
      expect(snapshot.totalCost, closeTo(2.6, 0.001));
      expect(snapshot.totalLatency, const Duration(milliseconds: 9));
      expect(
          snapshot.costBreakdown.keys,
          containsAll(<String>[
            'root',
            'typography',
            'headline',
            'caption',
            'badge',
            'container'
          ]));
    });

    test('swapLeaf applies updates immutably and records rebuilds', () {
      final RebuildCounterObserver observer = RebuildCounterObserver();
      final ProviderContainer container =
          ProviderContainer(observers: <ProviderObserver>[observer]);
      addTearDown(container.dispose);

      final ThemeTreeNotifier notifier =
          container.read(themeTreeProvider.notifier);

      notifier.swapLeaf(
        targetName: 'headline',
        replacement: ThemeLeaf(
          name: 'headline',
          attributes: <String, Object?>{
            'headlineFontSize': 24,
            'headlineWeight': 'w800',
          },
          rebuildCost: 0.95,
          latency: Duration(milliseconds: 4),
        ),
      );

      final StyleSnapshot snapshot = container.read(themeTreeProvider);
      expect(snapshot.attributes['headlineFontSize'], 24);
      expect(snapshot.costBreakdown['headline'], closeTo(0.95, 0.001));
      expect(snapshot.totalLatency.inMilliseconds, greaterThan(9));
      expect(observer.countFor(themeTreeProvider) >= 2, isTrue);
    });

    test('swapLeaf throws when the target leaf does not exist', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final ThemeTreeNotifier notifier =
          container.read(themeTreeProvider.notifier);

      expect(
        () => notifier.swapLeaf(
          targetName: 'missing',
          replacement:
              ThemeLeaf(name: 'missing', attributes: <String, Object?>{}),
        ),
        throwsA(
          isA<ThemeTargetNotFound>().having(
              (error) => error.toString(), 'toString', contains('missing')),
        ),
      );
    });

    test('outline renders full hierarchy for debugging', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final ThemeTreeNotifier notifier =
          container.read(themeTreeProvider.notifier);

      final String outline = notifier.outline();

      expect(outline, contains('branch root'));
      expect(outline, contains('leaf headline'));
      expect(outline, contains('leaf badge'));
    });

    test('ThemeBranch.replaceLeaf preserves the original branch immutably', () {
      final ThemeBranch root = ThemeBranch(
        name: 'root',
        overheadCost: 0.1,
        latency: const Duration(milliseconds: 1),
        children: <ThemeNode>[
          ThemeLeaf(
            name: 'headline',
            attributes: <String, Object?>{'size': 20},
          ),
          ThemeBranch(
            name: 'typography',
            children: <ThemeNode>[
              ThemeLeaf(
                name: 'caption',
                attributes: <String, Object?>{'size': 12},
              ),
            ],
          ),
        ],
      );

      final ThemeLeaf newCaption = ThemeLeaf(
        name: 'caption',
        attributes: <String, Object?>{'size': 14},
        rebuildCost: 0.4,
      );

      final ThemeBranch updated =
          root.replaceLeaf('caption', newCaption) as ThemeBranch;

      expect(identical(root, updated), isFalse);
      final ThemeBranch updatedTypography = updated.children[1] as ThemeBranch;
      expect(
        (updatedTypography.children.first as ThemeLeaf).attributes['size'],
        14,
      );

      final ThemeBranch originalTypography = root.children[1] as ThemeBranch;
      expect(
        (originalTypography.children.first as ThemeLeaf).attributes['size'],
        12,
      );
    });

    test('ThemeLeaf.replaceLeaf returns the provided replacement', () {
      final ThemeLeaf source = ThemeLeaf(
        name: 'badge',
        attributes: <String, Object?>{'color': '#FF8A65'},
      );
      final ThemeLeaf replacement = ThemeLeaf(
        name: 'badge',
        attributes: <String, Object?>{'color': '#FF7043'},
      );

      final ThemeNode result = source.replaceLeaf('badge', replacement);

      expect(result, same(replacement));
    });
  });
}
