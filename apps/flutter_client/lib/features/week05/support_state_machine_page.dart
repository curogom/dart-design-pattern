import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week05_patterns/shared.dart';
import 'package:week05_patterns/singleton.dart';
import 'package:week05_patterns/state.dart';

class SupportStateMachinePage extends StatelessWidget {
  const SupportStateMachinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[
        ticketConfigProvider.overrideWithValue(
          const TicketConfig(ticketId: 'ticket-ui', subject: '결제 실패'),
        ),
      ],
      child: const _SupportStateMachineView(),
    );
  }
}

class _SupportStateMachineView extends ConsumerStatefulWidget {
  const _SupportStateMachineView();

  @override
  ConsumerState<_SupportStateMachineView> createState() =>
      _SupportStateMachineViewState();
}

class _SupportStateMachineViewState
    extends ConsumerState<_SupportStateMachineView> {
  late Map<String, int> _machineCounts;
  StreamSubscription<TransitionLogEntry>? _subscription;

  @override
  void initState() {
    super.initState();
    TelemetryCenter.instance.reset();
    _machineCounts = TelemetryCenter.instance.snapshotMachineCounts();
    _subscription = TelemetryCenter.instance.transitions.listen((_) {
      setState(() {
        _machineCounts = TelemetryCenter.instance.snapshotMachineCounts();
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _dispatch(TicketEvent event) {
    final SupportTicketController controller =
        ref.read(supportTicketControllerProvider.notifier);
    try {
      controller.dispatch(event);
    } on StateTransitionError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전이 불가: ${error.event} (현재 ${error.current})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SupportTicketSnapshot snapshot =
        ref.watch(supportTicketControllerProvider);
    final List<TransitionLogEntry> entries = snapshot.transitions.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('State · Support Ticket Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '티켓 ID: ${snapshot.ticketId} · 상태: ${snapshot.state}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: snapshot.availableEvents
                  .map(
                    (TicketEvent event) => ElevatedButton(
                      onPressed: () => _dispatch(event),
                      child: Text(event.name),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Telemetry counters', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (_machineCounts.isEmpty)
                      const Text('아직 기록된 전이가 없습니다.')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _machineCounts.entries
                            .map(
                              (MapEntry<String, int> entry) => Text(
                                '${entry.key}: ${entry.value}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('전이 로그가 없습니다.'))
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (BuildContext context, int index) {
                        final TransitionLogEntry entry = entries[index];
                        return ListTile(
                          title: Text('${entry.event}: ${entry.fromState} → ${entry.toState}'),
                          subtitle: Text('${entry.timestamp.toIso8601String()} ${entry.metadata.isEmpty ? '' : entry.metadata}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
