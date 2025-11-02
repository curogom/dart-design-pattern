import 'package:test/test.dart';
import 'package:week05_patterns/singleton.dart';
import 'package:week05_patterns/src/shared/state_log.dart';

void main() {
  group('TelemetryCenter', () {
    test('returns the same instance across calls', () {
      final TelemetryCenter first = TelemetryCenter.instance;
      final TelemetryCenter second = TelemetryCenter();
      expect(identical(first, second), isTrue);
    });

    test('aggregates counters and transitions', () async {
      final TelemetryCenter telemetry = TelemetryCenter.instance;
      telemetry.reset();
      telemetry.incrementCounter('boot');
      telemetry.incrementCounter('boot');

      expect(telemetry.counter('boot'), 2);

      final TransitionLogEntry entry = TransitionLogEntry(
        machine: 'ticket:1',
        event: 'assign',
        fromState: 'new',
        toState: 'inProgress',
        timestamp: DateTime.utc(2024, 1, 1),
      );

      final Future<List<TransitionLogEntry>> future =
          telemetry.transitions.take(1).toList();
      telemetry.ingestTransition(entry);

      final List<TransitionLogEntry> received = await future;
      expect(received.single, entry);
      expect(telemetry.snapshotMachineCounts()['ticket:1'], 1);
    });
  });
}
