import 'dart:async';

import '../shared/state_log.dart';
import 'telemetry_center.dart';

class TelemetrySession {
  TelemetrySession(this.name);

  final String name;
  final DateTime startedAt = DateTime.now();
  final List<TransitionLogEntry> _localTransitions = <TransitionLogEntry>[];

  List<TransitionLogEntry> get transitions =>
      List<TransitionLogEntry>.unmodifiable(_localTransitions);

  void recordTransition({
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
      metadata: metadata,
      timestamp: timestamp ?? DateTime.now(),
    );
    _localTransitions.add(entry);
    TelemetryCenter.instance.ingestTransition(entry);
  }
}

Future<void> observeTransitions({
  required Stream<TransitionLogEntry> stream,
  required Duration duration,
  void Function(TransitionLogEntry entry)? onEvent,
}) async {
  final Completer<void> completer = Completer<void>();
  final StreamSubscription<TransitionLogEntry> subscription =
      stream.listen(onEvent);
  Future<void>.delayed(duration).then((_) async {
    await subscription.cancel();
    completer.complete();
  });
  await completer.future;
}

void main() async {
  final TelemetryCenter telemetry = TelemetryCenter.instance;
  telemetry.reset();

  final TelemetrySession session = TelemetrySession('demo-session');
  telemetry.incrementCounter('boot');

  session.recordTransition(
    machine: 'ticket:100',
    event: 'assign',
    from: 'new',
    to: 'inProgress',
    metadata: <String, Object?>{'assignee': 'agentA'},
  );

  session.recordTransition(
    machine: 'ticket:100',
    event: 'resolve',
    from: 'inProgress',
    to: 'resolved',
    metadata: <String, Object?>{'durationMs': 4200},
  );

  telemetry.incrementCounter('boot');

  await observeTransitions(
    stream: telemetry.transitions,
    duration: const Duration(milliseconds: 10),
    onEvent: (TransitionLogEntry entry) {
      print('Transition observed -> $entry');
    },
  );

  print('Counters: ${telemetry.snapshotCounters()}');
  print('Machine totals: ${telemetry.snapshotMachineCounts()}');
  print('Session transitions: ${session.transitions.length}');
}
