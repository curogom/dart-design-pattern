import 'dart:async';

import 'package:test/test.dart';
import 'package:week02_patterns/src/observer/observer_example.dart';

class RecordingObserver extends DeliveryObserver {
  final events = <DeliveryEvent>[];
  final errors = <Object>[];
  bool completed = false;

  @override
  void onStatus(DeliveryEvent event) {
    events.add(event);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    errors.add(error);
  }

  @override
  void onDone() {
    completed = true;
  }
}

Future<void> pumpEventQueue() => Future<void>.delayed(Duration.zero);

void main() {
  group('DeliveryTracker', () {
    test('broadcasts updates to all observers in order', () async {
      final baseTime = DateTime(2024, 1, 1, 9);
      var ticks = 0;
      final tracker = DeliveryTracker(
        clock: () => baseTime.add(Duration(minutes: ticks++)),
      );
      final firstObserver = RecordingObserver();
      final secondObserver = RecordingObserver();

      final disposeFirst = tracker.attach(firstObserver);
      final disposeSecond = tracker.attach(secondObserver);

      tracker.pushStatus(
        orderId: 'ORDER-1',
        status: DeliveryStatus.requested,
        note: '고객 주문 생성',
      );
      tracker.pushStatus(
        orderId: 'ORDER-1',
        status: DeliveryStatus.preparing,
        note: '상품 준비 중',
      );
      tracker.pushStatus(
        orderId: 'ORDER-1',
        status: DeliveryStatus.delivered,
        note: '배송 완료',
      );

      await pumpEventQueue();

      final expectedEvents = [
        DeliveryEvent(
          orderId: 'ORDER-1',
          status: DeliveryStatus.requested,
          timestamp: baseTime.add(const Duration(minutes: 0)),
          note: '고객 주문 생성',
        ),
        DeliveryEvent(
          orderId: 'ORDER-1',
          status: DeliveryStatus.preparing,
          timestamp: baseTime.add(const Duration(minutes: 1)),
          note: '상품 준비 중',
        ),
        DeliveryEvent(
          orderId: 'ORDER-1',
          status: DeliveryStatus.delivered,
          timestamp: baseTime.add(const Duration(minutes: 2)),
          note: '배송 완료',
        ),
      ];

      expect(firstObserver.events, expectedEvents);
      expect(secondObserver.events, expectedEvents);

      await disposeFirst();
      await disposeSecond();
      await tracker.close();
    });

    test('stops sending events after observer disposes', () async {
      final tracker = DeliveryTracker(
        clock: () => DateTime(2024, 1, 1, 12),
      );
      final observer = RecordingObserver();
      final dispose = tracker.attach(observer);

      tracker.pushStatus(
        orderId: 'ORDER-2',
        status: DeliveryStatus.requested,
      );
      await pumpEventQueue();

      await dispose();

      tracker.pushStatus(
        orderId: 'ORDER-2',
        status: DeliveryStatus.shipping,
      );
      await pumpEventQueue();

      expect(observer.events.length, 1);
      expect(observer.events.first.status, DeliveryStatus.requested);

      await tracker.close();
    });

    test('propagates errors to observers', () async {
      final tracker = DeliveryTracker(
        clock: () => DateTime(2024, 1, 1, 15),
      );
      final observer = RecordingObserver();
      tracker.attach(observer);

      final error = DeliveryException('드라이버 오프라인');
      tracker.reportError(error);

      await pumpEventQueue();

      expect(observer.errors, [error]);
      expect(observer.completed, isFalse);

      await tracker.close();
    });
  });
}
