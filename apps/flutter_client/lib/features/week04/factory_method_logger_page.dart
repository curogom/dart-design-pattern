import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week04_patterns/factory_method.dart';

class FactoryMethodLoggerPage extends ConsumerStatefulWidget {
  const FactoryMethodLoggerPage({super.key});

  @override
  ConsumerState<FactoryMethodLoggerPage> createState() =>
      _FactoryMethodLoggerPageState();
}

class _FactoryMethodLoggerPageState
    extends ConsumerState<FactoryMethodLoggerPage> {
  AuditLogTarget _target = AuditLogTarget.buffered;
  final StringBuffer _buffer = StringBuffer();
  final List<String> _consoleOutput = <String>[];
  int _sequence = 0;

  void _appendConsole(String line) {
    setState(() {
      _consoleOutput.insert(0, line);
      if (_consoleOutput.length > 16) {
        _consoleOutput.removeLast();
      }
    });
  }

  void _changeTarget(AuditLogTarget target) {
    if (_target == target) {
      return;
    }
    setState(() {
      _target = target;
      _buffer.clear();
      _consoleOutput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ProviderScope override로 싱크 전략을 학습자가 직접 바꿔본다.
    final overrides = [
      auditLogConfigProvider.overrideWithValue(
        AuditLogConfig(target: _target),
      ),
      if (_target == AuditLogTarget.console)
        auditLogConsoleWriterProvider.overrideWithValue(_appendConsole)
      else
        auditLogBufferProvider.overrideWithValue(_buffer),
    ];

    return ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          final AuditLogService service = ref.watch(auditLogServiceProvider);
          final List<String> logLines = switch (_target) {
            AuditLogTarget.console => List<String>.unmodifiable(_consoleOutput),
            AuditLogTarget.buffered => _buffer.toString().trim().isEmpty
                ? const <String>[]
                : _buffer
                    .toString()
                    .trim()
                    .split('\n')
                    .reversed
                    .toList(growable: false),
          };

          Future<void> recordEvent() async {
            final ScaffoldMessengerState messenger =
                ScaffoldMessenger.of(context);
            final int nextSequence = _sequence + 1;
            final LoggedEvent event = await service.record(
              'demo.log.$nextSequence',
              context: <String, Object?>{'sequence': nextSequence},
            );
            if (!mounted) {
              return;
            }
            _sequence = nextSequence;
            // 버퍼 모드에서는 setState만 호출해 Provider 재평가 흐름을 관찰.
            if (_target == AuditLogTarget.buffered) {
              setState(() {
                // 버퍼 내용을 다시 읽도록 빌드만 트리거.
              });
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text('기록 완료 · ${event.action}'),
                duration: const Duration(milliseconds: 900),
              ),
            );
          }

          return _FactoryMethodLoggerView(
            target: _target,
            logLines: logLines,
            onTargetChanged: _changeTarget,
            onRecord: recordEvent,
          );
        },
      ),
    );
  }
}

class _FactoryMethodLoggerView extends StatelessWidget {
  const _FactoryMethodLoggerView({
    required this.target,
    required this.logLines,
    required this.onTargetChanged,
    required this.onRecord,
  });

  final AuditLogTarget target;
  final List<String> logLines;
  final ValueChanged<AuditLogTarget> onTargetChanged;
  final Future<void> Function() onRecord;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Method · 감사 로그'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Provider override로 로그 싱크를 교체하면서 동일한 record API를 사용합니다.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<AuditLogTarget>(
              segments: const <ButtonSegment<AuditLogTarget>>[
                ButtonSegment<AuditLogTarget>(
                  value: AuditLogTarget.console,
                  label: Text('Console'),
                  icon: Icon(Icons.terminal),
                ),
                ButtonSegment<AuditLogTarget>(
                  value: AuditLogTarget.buffered,
                  label: Text('Buffered'),
                  icon: Icon(Icons.storage),
                ),
              ],
              selected: <AuditLogTarget>{target},
              onSelectionChanged: (Set<AuditLogTarget> values) {
                onTargetChanged(values.first);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRecord,
              icon: const Icon(Icons.add),
              label: const Text('샘플 이벤트 기록'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: logLines.isEmpty
                    ? const Center(
                        child: Text('아직 기록이 없습니다. 버튼을 눌러 이벤트를 남겨보세요.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: logLines.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final String line = logLines[index];
                          return Text(
                            line,
                            style: const TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
