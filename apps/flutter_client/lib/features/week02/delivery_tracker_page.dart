import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week02_patterns/observer.dart';

// 옵저버 패턴 데모 페이지:
// - 주문 상태 업데이트 버튼을 누르면 DeliveryTracker가 Stream 이벤트를 브로드캐스트하고,
//   Riverpod Provider가 타임라인과 SnackBar 알림을 동시에 갱신합니다.
// - 실제 서비스에서는 배송/알림/재고 등 다수 구독자에게 동일 이벤트를 뿌리는 상황을
//   간단한 UI 인터랙션으로 체험하도록 구성했습니다.

class DeliveryTrackerPage extends ConsumerStatefulWidget {
  const DeliveryTrackerPage({super.key});

  @override
  ConsumerState<DeliveryTrackerPage> createState() =>
      _DeliveryTrackerPageState();
}

class _DeliveryTrackerPageState extends ConsumerState<DeliveryTrackerPage> {
  static const _orderId = 'ORDER-DEMO';

  final TextEditingController _noteController = TextEditingController();
  DeliveryStatus _selectedStatus = DeliveryStatus.requested;

  @override
  void initState() {
    super.initState();
    // 스트림 Provider를 구독해 이벤트 발생 시 SnackBar로 알림을 띄움.
    ref.listen<AsyncValue<DeliveryEvent>>(
      deliveryStreamProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }
        if (next.isLoading) {
          return;
        }
        if (next case AsyncData<DeliveryEvent>(value: final event)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${event.orderId} · ${event.status.name}'),
              duration: const Duration(milliseconds: 1200),
            ),
          );
        } else if (next case AsyncError(:final error)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류 발생: $error'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _pushSelectedStatus() {
    final tracker = ref.read(deliveryTrackerProvider);
    tracker.pushStatus(
      orderId: _orderId,
      status: _selectedStatus,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );
    _noteController.clear();
  }

  void _pushError() {
    final tracker = ref.read(deliveryTrackerProvider);
    tracker.reportError(DeliveryException('배송 파트너 연결 실패'));
  }

  @override
  Widget build(BuildContext context) {
    final timeline = ref.watch(deliveryTimelineProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('옵저버 패턴 · 배송 추적'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주문 상태를 전파하면 Stream을 통해 모든 구독자(UI, 로거 등)가 동시에 반응합니다.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _StatusPicker(
              selected: _selectedStatus,
              onSelected: (status) {
                setState(() {
                  _selectedStatus = status;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '이벤트 메모',
                hintText: '예: 라이더 픽업 완료',
              ),
              onSubmitted: (_) => _pushSelectedStatus(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _pushSelectedStatus,
                  icon: const Icon(Icons.send),
                  label: const Text('상태 전파'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pushError,
                  icon: const Icon(Icons.error_outline),
                  label: const Text('오류 전파'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _TimelineList(
                events: timeline.events,
                errors: timeline.errors,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({
    required this.selected,
    required this.onSelected,
  });

  final DeliveryStatus selected;
  final ValueChanged<DeliveryStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DeliveryStatus.values.map((status) {
        final isSelected = status == selected;
        return ChoiceChip(
          label: Text(_statusLabel(status)),
          selected: isSelected,
          onSelected: (_) => onSelected(status),
        );
      }).toList(),
    );
  }

  String _statusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.requested:
        return '주문 접수';
      case DeliveryStatus.preparing:
        return '상품 준비';
      case DeliveryStatus.shipping:
        return '배송 중';
      case DeliveryStatus.delivered:
        return '배송 완료';
      case DeliveryStatus.cancelled:
        return '취소';
    }
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.events,
    required this.errors,
  });

  final List<DeliveryEvent> events;
  final List<Object> errors;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty && errors.isEmpty) {
      return const Center(
        child: Text('아직 수신한 이벤트가 없습니다. 버튼을 눌러 전파를 시작하세요.'),
      );
    }

    final items = <_TimelineItem>[
      ...events.map((event) => _TimelineItem.event(event)),
      ...errors.map((error) => _TimelineItem.error(error)),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.error != null) {
          return ListTile(
            leading: const Icon(Icons.error, color: Colors.redAccent),
            title: Text('오류: ${item.error}'),
            subtitle: Text(item.timestamp.toLocal().toIso8601String()),
          );
        }
        final event = item.event!;
        return ListTile(
          leading: const Icon(Icons.local_shipping_outlined),
          title: Text('${event.orderId} · ${event.status.name}'),
          subtitle: Text(
            '${event.timestamp.toLocal().toIso8601String()}'
            '${event.note != null ? '\n메모: ${event.note}' : ''}',
          ),
        );
      },
    );
  }
}

class _TimelineItem {
  _TimelineItem.event(DeliveryEvent event)
      : event = event,
        error = null,
        timestamp = event.timestamp;

  _TimelineItem.error(Object error)
      : event = null,
        error = error,
        timestamp = DateTime.now();

  final DeliveryEvent? event;
  final Object? error;
  final DateTime timestamp;
}
