import 'package:riverpod/riverpod.dart';

import '../shared/state_log.dart';
import 'support_ticket.dart';

class TicketConfig {
  const TicketConfig({
    required this.ticketId,
    required this.subject,
  });

  final String ticketId;
  final String subject;
}

/// 상태 머신 데모에서 티켓 메타데이터를 공급한다.
final ticketConfigProvider = Provider<TicketConfig>(
  (ref) => const TicketConfig(ticketId: 'ticket-001', subject: 'billing'),
);

/// 상태 전이와 타임라인을 노출하는 Riverpod 노티파이어.
class SupportTicketController
    extends AutoDisposeNotifier<SupportTicketSnapshot> {
  late SupportTicketMachine _machine;

  @override
  SupportTicketSnapshot build() {
    final TicketConfig config = ref.watch(ticketConfigProvider);
    _machine = SupportTicketMachine(ticketId: config.ticketId);
    ref.onDispose(() {
      // 테스트 환경에서 글로벌 카운터 오염을 방지.
      _machine.resetHistory();
    });
    return _machine.snapshot();
  }

  void dispatch(TicketEvent event, {String? note}) {
    _machine.transition(event, note: note);
    state = _machine.snapshot();
  }
}

final supportTicketControllerProvider =
    AutoDisposeNotifierProvider<SupportTicketController, SupportTicketSnapshot>(
  SupportTicketController.new,
);

void main() {
  final ProviderContainer container = ProviderContainer(overrides: <Override>[
    ticketConfigProvider.overrideWithValue(
      const TicketConfig(ticketId: 'ticket-818', subject: 'refund'),
    ),
  ]);

  final SupportTicketController controller =
      container.read(supportTicketControllerProvider.notifier);

  controller.dispatch(
    TicketEvent.assign,
    note: 'Assigned to Agent-42',
  );
  controller.dispatch(
    TicketEvent.resolve,
    note: 'Refund approved',
  );
  controller.dispatch(TicketEvent.close);

  final SupportTicketSnapshot snapshot =
      container.read(supportTicketControllerProvider);

  print('Ticket ${snapshot.ticketId} state -> ${snapshot.state}');
  for (final TransitionLogEntry entry in snapshot.transitions) {
    print(' - ${entry.event}: ${entry.fromState} -> ${entry.toState}');
  }

  container.dispose();
}
