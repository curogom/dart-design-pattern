import 'dart:convert';

import 'package:riverpod/riverpod.dart';

enum AuditLogTarget {
  console,
  buffered,
}

// 생성 패턴 학습 포인트: 환경 설정을 묶어 Provider override로 쉽게 교체.
class AuditLogConfig {
  const AuditLogConfig({
    required this.target,
  });

  final AuditLogTarget target;
}

class LoggedEvent {
  const LoggedEvent({
    required this.timestamp,
    required this.action,
    required this.context,
  });

  final DateTime timestamp;
  final String action;
  final Map<String, Object?> context;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'timestamp': timestamp.toUtc().toIso8601String(),
      'action': action,
      'context': context,
    };
  }

  String serialize() => jsonEncode(toJson());
}

abstract class LogSink {
  Future<void> write(LoggedEvent event);
}

class ConsoleLogSink implements LogSink {
  ConsoleLogSink(this._writer);

  final void Function(String) _writer;

  @override
  Future<void> write(LoggedEvent event) async {
    _writer(event.serialize());
  }
}

class BufferedLogSink implements LogSink {
  BufferedLogSink(this._buffer);

  final StringBuffer _buffer;

  @override
  Future<void> write(LoggedEvent event) async {
    _buffer.writeln(event.serialize());
  }
}

abstract class AuditLogService {
  AuditLogService({required DateTime Function() now}) : _now = now;

  final DateTime Function() _now;

  // 팩토리 메서드: 하위 클래스가 구체 싱크를 결정.
  LogSink createSink();

  Future<LoggedEvent> record(
    String action, {
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    final LoggedEvent event = LoggedEvent(
      timestamp: _now(),
      action: action,
      context: context,
    );
    final LogSink sink = createSink();
    await sink.write(event);
    return event;
  }
}

class ConsoleAuditLogService extends AuditLogService {
  ConsoleAuditLogService({
    required this.writer,
    required super.now,
  });

  final void Function(String) writer;

  @override
  LogSink createSink() {
    return ConsoleLogSink(writer);
  }
}

class BufferedAuditLogService extends AuditLogService {
  BufferedAuditLogService({
    required this.buffer,
    required super.now,
  });

  final StringBuffer buffer;

  @override
  LogSink createSink() {
    return BufferedLogSink(buffer);
  }
}

/// 감사 로그 전송 설정을 노출하는 Provider.
final auditLogConfigProvider = Provider<AuditLogConfig>(
  (ref) {
    return const AuditLogConfig(target: AuditLogTarget.console);
  },
  name: 'auditLogConfigProvider',
);

/// 콘솔로 로그를 출력하는 함수 주입용 Provider.
final auditLogConsoleWriterProvider = Provider<void Function(String)>(
  (ref) {
    throw StateError('콘솔 로그 writer가 등록되지 않았습니다.');
  },
  name: 'auditLogConsoleWriterProvider',
);

/// 메모리 버퍼 기반 로그 수집기에 버퍼를 제공하는 Provider.
final auditLogBufferProvider = Provider<StringBuffer>(
  (ref) {
    throw StateError('버퍼 기반 감사 로그는 테스트에서만 활성화하세요.');
  },
  name: 'auditLogBufferProvider',
);

/// 감사 로그 타임스탬프용 Clock 주입 Provider.
final logTimestampProvider = Provider<DateTime Function()>(
  (ref) {
    return DateTime.now;
  },
  name: 'logTimestampProvider',
);

/// 감사 로그 서비스를 의존성 주입으로 선택하는 Provider.
final auditLogServiceProvider = Provider<AuditLogService>(
  (ref) {
    final AuditLogConfig config = ref.watch(auditLogConfigProvider);
    final DateTime Function() now = ref.watch(logTimestampProvider);
    switch (config.target) {
      case AuditLogTarget.console:
        final void Function(String) writer =
            ref.watch(auditLogConsoleWriterProvider);
        return ConsoleAuditLogService(writer: writer, now: now);
      case AuditLogTarget.buffered:
        final StringBuffer buffer = ref.watch(auditLogBufferProvider);
        return BufferedAuditLogService(buffer: buffer, now: now);
    }
  },
  name: 'auditLogServiceProvider',
);
