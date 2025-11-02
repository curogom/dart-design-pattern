import 'package:riverpod/riverpod.dart';

/// ProviderObserver 구현체로 리빌드 횟수를 기록한다.
/// 위젯이나 서비스의 재계산 횟수를 정량화해 리빌드 최적화 학습에 활용한다.
class RebuildCounterObserver extends ProviderObserver {
  RebuildCounterObserver({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, int> _counts = <String, int>{};
  final List<RebuildLogEntry> _entries = <RebuildLogEntry>[];

  /// 현재까지 기록된 로그를 반환한다.
  List<RebuildLogEntry> get entries => List.unmodifiable(_entries);

  /// 특정 provider 라벨의 누적 리빌드 횟수를 조회한다.
  int countFor(ProviderBase<Object?> provider) {
    return _counts[_labelOf(provider)] ?? 0;
  }

  /// 내부 상태를 초기화한다. 테스트 시 편의용으로 사용한다.
  void reset() {
    _counts.clear();
    _entries.clear();
  }

  Map<String, int> snapshot() => Map.unmodifiable(_counts);

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    _record(provider: provider, event: RebuildEventType.added, value: value);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    _record(
        provider: provider, event: RebuildEventType.updated, value: newValue);
  }

  @override
  void didDisposeProvider(
      ProviderBase<Object?> provider, ProviderContainer container) {
    _record(provider: provider, event: RebuildEventType.disposed, value: null);
  }

  void _record({
    required ProviderBase<Object?> provider,
    required RebuildEventType event,
    required Object? value,
  }) {
    final label = _labelOf(provider);
    final nextCount = (_counts[label] ?? 0) + 1;
    _counts[label] = nextCount;
    _entries.add(
      RebuildLogEntry(
        label: label,
        count: nextCount,
        event: event,
        value: value,
        timestamp: _clock(),
      ),
    );
  }

  String _labelOf(ProviderBase<Object?> provider) {
    return provider.name ?? provider.runtimeType.toString();
  }
}

enum RebuildEventType { added, updated, disposed }

class RebuildLogEntry {
  const RebuildLogEntry({
    required this.label,
    required this.count,
    required this.event,
    required this.value,
    required this.timestamp,
  });

  final String label;
  final int count;
  final RebuildEventType event;
  final Object? value;
  final DateTime timestamp;
}
