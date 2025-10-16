import 'dart:async';

import 'package:riverpod/riverpod.dart';

// 옵저버 패턴에서는 주제(subject)가 상태 변화를 알리고, 구독자는 비동기적으로 이벤트를 수신합니다.
// 여기서는 배송 추적을 예시로 삼아 Stream 기반 브로드캐스트와 구독 해제를 모두 다룹니다.

enum DeliveryStatus {
  requested,
  preparing,
  shipping,
  delivered,
  cancelled,
}

class DeliveryEvent {
  const DeliveryEvent({
    required this.orderId,
    required this.status,
    required this.timestamp,
    this.note,
  });

  final String orderId;
  final DeliveryStatus status;
  final DateTime timestamp;
  final String? note;

  DeliveryEvent copyWith({
    String? orderId,
    DeliveryStatus? status,
    DateTime? timestamp,
    String? note,
  }) {
    return DeliveryEvent(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'DeliveryEvent(orderId: $orderId, status: $status, '
        'timestamp: $timestamp, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return other is DeliveryEvent &&
        other.orderId == orderId &&
        other.status == status &&
        other.timestamp == timestamp &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(orderId, status, timestamp, note);
}

class DeliveryException implements Exception {
  DeliveryException(this.message);

  final String message;

  @override
  String toString() => 'DeliveryException($message)';
}

abstract class DeliveryObserver {
  void onStatus(DeliveryEvent event);

  void onError(Object error, StackTrace stackTrace) {}

  void onDone() {}
}

typedef ObserverDisposer = Future<void> Function();

class DeliveryTracker {
  DeliveryTracker({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        _controller = StreamController<DeliveryEvent>.broadcast(sync: true);

  final DateTime Function() _clock;
  final StreamController<DeliveryEvent> _controller;
  final Map<DeliveryObserver, StreamSubscription<DeliveryEvent>> _observers = {};

  Stream<DeliveryEvent> get stream => _controller.stream;

  bool get hasListeners => _observers.isNotEmpty;

  ObserverDisposer attach(DeliveryObserver observer) {
    if (_controller.isClosed) {
      throw StateError('Cannot attach observers after tracker is closed.');
    }
    if (_observers.containsKey(observer)) {
      throw StateError('Observer already attached.');
    }
    final subscription = _controller.stream.listen(
      observer.onStatus,
      onError: observer.onError,
      onDone: observer.onDone,
      cancelOnError: false,
    );
    _observers[observer] = subscription;
    return () async {
      await detach(observer);
    };
  }

  Future<void> detach(DeliveryObserver observer) async {
    final subscription = _observers.remove(observer);
    if (subscription != null) {
      await subscription.cancel();
    }
  }

  void pushStatus({
    required String orderId,
    required DeliveryStatus status,
    String? note,
    DateTime? timestamp,
  }) {
    final event = DeliveryEvent(
      orderId: orderId,
      status: status,
      timestamp: timestamp ?? _clock(),
      note: note,
    );
    _controller.add(event);
  }

  void reportError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  Future<void> close() async {
    final futures = _observers.values.map((subscription) => subscription.cancel());
    await Future.wait(futures);
    _observers.clear();
    await _controller.close();
  }
}

class ConsoleDeliveryObserver extends DeliveryObserver {
  ConsoleDeliveryObserver(this.label);

  final String label;

  @override
  void onStatus(DeliveryEvent event) {
    // 실전에서는 스낵바나 상태 표시줄로 연결할 수 있다.
    print('[$label] ${event.orderId} -> ${event.status} (${event.note ?? 'no note'})');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('[$label] error: $error');
  }

  @override
  void onDone() {
    print('[$label] completed');
  }
}

class DeliveryTimeline {
  const DeliveryTimeline({
    this.events = const [],
    this.errors = const [],
  });

  final List<DeliveryEvent> events;
  final List<Object> errors;

  DeliveryTimeline appendEvent(DeliveryEvent event) {
    return DeliveryTimeline(
      events: [...events, event],
      errors: errors,
    );
  }

  DeliveryTimeline appendError(Object error) {
    return DeliveryTimeline(
      events: events,
      errors: [...errors, error],
    );
  }
}

/// Riverpod 연동: Stream을 UI 상태로 축약해 리스트 갱신과 에러 알림을 동시에 관리한다.
class DeliveryTimelineNotifier extends Notifier<DeliveryTimeline> {
  StreamSubscription<DeliveryEvent>? _subscription;

  @override
  DeliveryTimeline build() {
    final tracker = ref.watch(deliveryTrackerProvider);
    _subscription?.cancel();
    _subscription = tracker.stream.listen(
      (event) => state = state.appendEvent(event),
      onError: (error, stackTrace) {
        state = state.appendError(error);
      },
    );
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    return const DeliveryTimeline();
  }
}

final deliveryTrackerProvider = Provider<DeliveryTracker>((ref) {
  final tracker = DeliveryTracker();
  ref.onDispose(tracker.close);
  return tracker;
});

final deliveryTimelineProvider = NotifierProvider.autoDispose<DeliveryTimelineNotifier, DeliveryTimeline>(
  DeliveryTimelineNotifier.new,
);

final deliveryStreamProvider = StreamProvider.autoDispose<DeliveryEvent>(
  (ref) => ref.watch(deliveryTrackerProvider).stream,
);

Future<void> main() async {
  final tracker = DeliveryTracker();
  final consoleObserver = ConsoleDeliveryObserver('console');
  final disposer = tracker.attach(consoleObserver);

  tracker.pushStatus(
    orderId: 'ORDER-100',
    status: DeliveryStatus.requested,
    note: '새 주문 생성',
  );
  await Future<void>.delayed(const Duration(milliseconds: 10));
  tracker.pushStatus(
    orderId: 'ORDER-100',
    status: DeliveryStatus.shipping,
    note: '픽업 완료',
  );
  tracker.pushStatus(
    orderId: 'ORDER-100',
    status: DeliveryStatus.delivered,
    note: '배송 완료',
  );

  await disposer();
  await tracker.close();
}
