import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:week04_patterns/factory_method.dart';

void main() {
  group('FactoryMethod.auditLogService', () {
    test('records events to buffer when buffered target selected', () async {
      final StringBuffer buffer = StringBuffer();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          auditLogConfigProvider.overrideWithValue(
            const AuditLogConfig(target: AuditLogTarget.buffered),
          ),
          auditLogBufferProvider.overrideWithValue(buffer),
          logTimestampProvider.overrideWithValue(
            () => DateTime.utc(2024, 1, 1, 9),
          ),
        ],
      );

      final AuditLogService service = container.read(auditLogServiceProvider);
      final LoggedEvent event = await service.record(
        'order.create',
        context: <String, Object?>{'orderId': 42},
      );

      expect(event.timestamp, DateTime.utc(2024, 1, 1, 9));
      expect(
        buffer.toString(),
        contains('"action":"order.create"'),
      );

      container.dispose();
    });

    test('throws when console writer missing', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          auditLogConfigProvider.overrideWithValue(
            const AuditLogConfig(target: AuditLogTarget.console),
          ),
        ],
      );

      expect(
        () => container.read(auditLogServiceProvider),
        throwsA(
          isA<Object>().having(
            (Object error) => error.toString(),
            'message',
            contains('콘솔 로그 writer'),
          ),
        ),
      );
      container.dispose();
    });
  });
}
