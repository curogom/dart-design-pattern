import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'audit_log.dart';

Future<void> main() async {
  final ProviderContainer consoleContainer = ProviderContainer(
    overrides: [
      // 실제 서비스 상황: 콘솔 타겟으로 팩토리 분기.
      auditLogConfigProvider.overrideWithValue(
          const AuditLogConfig(target: AuditLogTarget.console)),
      auditLogConsoleWriterProvider.overrideWithValue(stdout.writeln),
    ],
  );
  final AuditLogService consoleService =
      consoleContainer.read(auditLogServiceProvider);

  await consoleService.record(
    'user.login',
    context: <String, Object?>{'userId': 'u-001', 'origin': 'web'},
  );
  await consoleService.record(
    'user.export',
    context: <String, Object?>{'format': 'csv'},
  );
  consoleContainer.dispose();

  final StringBuffer buffer = StringBuffer();
  final ProviderContainer bufferedContainer = ProviderContainer(
    overrides: [
      // 테스트/미리보기 상황: 버퍼 타겟으로 교체.
      auditLogConfigProvider.overrideWithValue(
          const AuditLogConfig(target: AuditLogTarget.buffered)),
      auditLogBufferProvider.overrideWithValue(buffer),
      logTimestampProvider.overrideWithValue(
        () => DateTime.utc(2024, 10, 1, 12, 0),
      ),
    ],
  );
  final AuditLogService bufferedService =
      bufferedContainer.read(auditLogServiceProvider);
  await bufferedService.record(
    'orders.export.start',
    context: <String, Object?>{'batch': 42},
  );
  await bufferedService.record(
    'orders.export.finish',
    context: <String, Object?>{'batch': 42, 'durationMs': 830},
  );

  stdout
    ..writeln('Buffered audit log output:')
    ..writeln(buffer.toString());
  bufferedContainer.dispose();
}
