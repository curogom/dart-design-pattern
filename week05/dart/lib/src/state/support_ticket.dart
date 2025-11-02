import '../shared/state_log.dart';
import '../singleton/telemetry_center.dart';

enum TicketEvent {
  assign,
  escalate,
  resolve,
  close,
  reopen,
}

class StateTransitionError implements Exception {
  StateTransitionError(this.current, this.event);

  final String current;
  final TicketEvent event;

  @override
  String toString() {
    return 'StateTransitionError(current: $current, event: $event)';
  }
}

abstract class SupportTicketState {
  const SupportTicketState();

  String get name;

  SupportTicketState handle(SupportTicketMachine machine, TicketEvent event);
}

class NewTicketState extends SupportTicketState {
  const NewTicketState();

  @override
  String get name => 'new';

  @override
  SupportTicketState handle(SupportTicketMachine machine, TicketEvent event) {
    return switch (event) {
      TicketEvent.assign => const InProgressState(),
      _ => throw StateTransitionError(name, event),
    };
  }
}

class InProgressState extends SupportTicketState {
  const InProgressState();

  @override
  String get name => 'inProgress';

  @override
  SupportTicketState handle(SupportTicketMachine machine, TicketEvent event) {
    return switch (event) {
      TicketEvent.escalate => const EscalatedState(),
      TicketEvent.resolve => const ResolvedState(),
      TicketEvent.close => const ClosedState(),
      _ => throw StateTransitionError(name, event),
    };
  }
}

class EscalatedState extends SupportTicketState {
  const EscalatedState();

  @override
  String get name => 'escalated';

  @override
  SupportTicketState handle(SupportTicketMachine machine, TicketEvent event) {
    return switch (event) {
      TicketEvent.resolve => const ResolvedState(),
      TicketEvent.escalate => const EscalatedState(),
      _ => throw StateTransitionError(name, event),
    };
  }
}

class ResolvedState extends SupportTicketState {
  const ResolvedState();

  @override
  String get name => 'resolved';

  @override
  SupportTicketState handle(SupportTicketMachine machine, TicketEvent event) {
    return switch (event) {
      TicketEvent.close => const ClosedState(),
      TicketEvent.reopen => const InProgressState(),
      _ => throw StateTransitionError(name, event),
    };
  }
}

class ClosedState extends SupportTicketState {
  const ClosedState();

  @override
  String get name => 'closed';

  @override
  SupportTicketState handle(SupportTicketMachine machine, TicketEvent event) {
    return switch (event) {
      TicketEvent.reopen => const InProgressState(),
      _ => throw StateTransitionError(name, event),
    };
  }
}

class SupportTicketSnapshot {
  const SupportTicketSnapshot({
    required this.ticketId,
    required this.state,
    required this.timeline,
    required this.transitions,
    required this.availableEvents,
  });

  final String ticketId;
  final String state;
  final List<String> timeline;
  final List<TransitionLogEntry> transitions;
  final List<TicketEvent> availableEvents;

  SupportTicketSnapshot copyWith({
    String? state,
    List<String>? timeline,
    List<TransitionLogEntry>? transitions,
    List<TicketEvent>? availableEvents,
  }) {
    return SupportTicketSnapshot(
      ticketId: ticketId,
      state: state ?? this.state,
      timeline: timeline ?? this.timeline,
      transitions: transitions ?? this.transitions,
      availableEvents: availableEvents ?? this.availableEvents,
    );
  }
}

class SupportTicketMachine with TransitionLoggerMixin {
  SupportTicketMachine({
    required this.ticketId,
    SupportTicketState? initialState,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _state = initialState ?? const NewTicketState();
    sink = TelemetryCenter.instance.ingestTransition;
    _timeline.add('created:${_clock().toIso8601String()}');
  }

  final String ticketId;
  final DateTime Function() _clock;
  late SupportTicketState _state;
  final List<String> _timeline = <String>[];

  SupportTicketState get state => _state;

  List<String> get timeline => List<String>.unmodifiable(_timeline);

  List<TicketEvent> get availableEvents {
    return switch (_state) {
      NewTicketState() => const <TicketEvent>[TicketEvent.assign],
      InProgressState() => const <TicketEvent>[
          TicketEvent.escalate,
          TicketEvent.resolve,
          TicketEvent.close,
        ],
      EscalatedState() => const <TicketEvent>[TicketEvent.resolve, TicketEvent.escalate],
      ResolvedState() => const <TicketEvent>[TicketEvent.close, TicketEvent.reopen],
      ClosedState() => const <TicketEvent>[TicketEvent.reopen],
      _ => const <TicketEvent>[],
    };
  }

  void transition(TicketEvent event, {String? note}) {
    final SupportTicketState previous = _state;
    final SupportTicketState next = _state.handle(this, event);
    _state = next;
    _timeline.add('${event.name}:${_clock().toIso8601String()}');
    if (note != null && note.isNotEmpty) {
      _timeline.add('note:$note');
    }
    logTransition(
      machine: 'ticket:$ticketId',
      event: event.name,
      from: previous.name,
      to: next.name,
      metadata: <String, Object?>{
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    TelemetryCenter.instance.incrementCounter(
      'ticket:${ticketId}_${next.name}',
    );
  }

  SupportTicketSnapshot snapshot() {
    return SupportTicketSnapshot(
      ticketId: ticketId,
      state: _state.name,
      timeline: timeline,
      transitions: transitions,
      availableEvents: availableEvents,
    );
  }

  void resetHistory({SupportTicketState? toState}) {
    clearTransitions();
    _timeline.clear();
    _timeline.add('reset:${_clock().toIso8601String()}');
    _state = toState ?? const NewTicketState();
  }
}
