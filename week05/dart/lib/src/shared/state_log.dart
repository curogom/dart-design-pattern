import 'package:collection/collection.dart';

/// 전이 기록을 외부 저장소로 전달할 때 사용되는 콜백 정의.
typedef TransitionSink = void Function(TransitionLogEntry entry);

class TransitionLogEntry {
  TransitionLogEntry({
    required this.machine,
    required this.event,
    required this.fromState,
    required this.toState,
    required this.timestamp,
    Map<String, Object?>? metadata,
  }) : metadata = Map.unmodifiable(metadata ?? const <String, Object?>{});

  final String machine;
  final String event;
  final String fromState;
  final String toState;
  final DateTime timestamp;
  final Map<String, Object?> metadata;

  @override
  String toString() {
    return 'TransitionLogEntry(machine: $machine, event: $event, '
        'from: $fromState, to: $toState, metadata: $metadata, '
        'timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return other is TransitionLogEntry &&
        other.machine == machine &&
        other.event == event &&
        other.fromState == fromState &&
        other.toState == toState &&
        const DeepCollectionEquality().equals(other.metadata, metadata) &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
        machine,
        event,
        fromState,
        toState,
        const DeepCollectionEquality().hash(metadata),
        timestamp,
      );
}

mixin TransitionLoggerMixin {
  final List<TransitionLogEntry> _entries = <TransitionLogEntry>[];

  TransitionSink? sink;

  List<TransitionLogEntry> get transitions =>
      List<TransitionLogEntry>.unmodifiable(_entries);

  void logTransition({
    required String machine,
    required String event,
    required String from,
    required String to,
    Map<String, Object?> metadata = const <String, Object?>{},
    DateTime? timestamp,
  }) {
    final entry = TransitionLogEntry(
      machine: machine,
      event: event,
      fromState: from,
      toState: to,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
    _entries.add(entry);
    sink?.call(entry);
  }

  void clearTransitions() {
    _entries.clear();
  }
}
