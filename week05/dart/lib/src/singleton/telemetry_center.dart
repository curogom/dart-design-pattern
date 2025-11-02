import 'dart:async';

import '../shared/state_log.dart';

/// 애플리케이션 전역에서 상태 전환·카운터 정보를 집계하는 싱글턴.
class TelemetryCenter {
  TelemetryCenter._internal();

  static final TelemetryCenter _instance = TelemetryCenter._internal();

  factory TelemetryCenter() => _instance;

  static TelemetryCenter get instance => _instance;

  final Map<String, int> _counters = <String, int>{};
  final Map<String, int> _machineTransitionCounts = <String, int>{};
  final StreamController<TransitionLogEntry> _transitionStreamController =
      StreamController<TransitionLogEntry>.broadcast();

  Stream<TransitionLogEntry> get transitions =>
      _transitionStreamController.stream;

  Map<String, int> snapshotCounters() =>
      Map<String, int>.unmodifiable(_counters);

  Map<String, int> snapshotMachineCounts() =>
      Map<String, int>.unmodifiable(_machineTransitionCounts);

  void incrementCounter(String name, {int by = 1}) {
    _counters.update(name, (value) => value + by, ifAbsent: () => by);
  }

  int counter(String name) => _counters[name] ?? 0;

  void ingestTransition(TransitionLogEntry entry) {
    _machineTransitionCounts.update(
      entry.machine,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    _transitionStreamController.add(entry);
  }

  void reset() {
    _counters.clear();
    _machineTransitionCounts.clear();
  }

  Future<void> dispose() async {
    await _transitionStreamController.close();
  }
}
