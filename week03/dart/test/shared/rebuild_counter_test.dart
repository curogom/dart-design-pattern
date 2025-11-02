import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import 'package:week03_patterns/shared.dart';

final StateProvider<int> _demoProvider = StateProvider<int>(
  (ref) => 0,
  name: 'demoProvider',
);

void main() {
  group('RebuildCounterObserver', () {
    test('records add, update, and dispose events with reset support', () {
      final RebuildCounterObserver observer = RebuildCounterObserver();
      final ProviderContainer container = ProviderContainer(
        observers: <ProviderObserver>[observer],
      );

      final ProviderSubscription<int> subscription =
          container.listen(_demoProvider, (_, __) {});

      expect(observer.countFor(_demoProvider), 1);
      expect(observer.entries.last.event, RebuildEventType.added);

      container.read(_demoProvider.notifier).state = 1;
      expect(observer.countFor(_demoProvider), greaterThanOrEqualTo(2));
      expect(observer.entries.last.event, RebuildEventType.updated);

      final Map<String, int> snapshot = observer.snapshot();
      expect(snapshot['demoProvider'], greaterThanOrEqualTo(2));

      observer.reset();
      expect(observer.snapshot(), isEmpty);

      subscription.close();
      container.dispose();
      expect(observer.entries.last.event, RebuildEventType.disposed);
    });
  });
}
