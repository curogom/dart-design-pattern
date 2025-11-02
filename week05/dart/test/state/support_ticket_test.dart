import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:week05_patterns/state.dart';
import 'package:week05_patterns/singleton.dart';

void main() {
  setUp(() {
    TelemetryCenter.instance.reset();
  });

  group('SupportTicketMachine', () {
    test('follows happy path with logging', () {
      final SupportTicketMachine machine = SupportTicketMachine(
        ticketId: 'demo',
        clock: () => DateTime.utc(2024, 1, 1, 12),
      );

      machine.transition(
        TicketEvent.assign,
        note: 'agent-1',
      );
      expect(machine.availableEvents,
          containsAllInOrder(<TicketEvent>[TicketEvent.escalate, TicketEvent.resolve]));
      machine.transition(TicketEvent.resolve);
      machine.transition(TicketEvent.close);

      expect(machine.state.name, 'closed');
      expect(machine.timeline.where((String item) => item.startsWith('note')),
          contains('note:agent-1'));
      expect(machine.transitions.map((entry) => entry.event), <String>[
        'assign',
        'resolve',
        'close',
      ]);
      expect(TelemetryCenter.instance.snapshotMachineCounts()['ticket:demo'], 3);

      final SupportTicketSnapshot snapshot = machine.snapshot();
      expect(snapshot.availableEvents, <TicketEvent>[TicketEvent.reopen]);
    });

    test('throws on invalid transition', () {
      final SupportTicketMachine machine = SupportTicketMachine(ticketId: 'x');
      expect(
        () => machine.transition(TicketEvent.resolve),
        throwsA(isA<StateTransitionError>()),
      );
    });
  });

  group('SupportTicketController', () {
    test('updates state when dispatching events', () {
      final ProviderContainer container = ProviderContainer(overrides: <Override>[
        ticketConfigProvider.overrideWithValue(
          const TicketConfig(ticketId: 'ticket-100', subject: 'login issue'),
        ),
      ]);

      final SupportTicketController controller =
          container.read(supportTicketControllerProvider.notifier);
      controller.dispatch(TicketEvent.assign);
      controller.dispatch(TicketEvent.escalate, note: 'hand off to L2');

      final SupportTicketSnapshot snapshot =
          container.read(supportTicketControllerProvider);

      expect(snapshot.state, 'escalated');
      expect(snapshot.transitions.length, 2);
      expect(snapshot.availableEvents,
          containsAll(<TicketEvent>[TicketEvent.resolve]));

      container.dispose();
    });
  });
}
