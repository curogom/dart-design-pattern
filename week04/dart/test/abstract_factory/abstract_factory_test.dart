import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:week04_patterns/abstract_factory.dart';

void main() {
  group('AbstractFactory.supportExperience', () {
    test('creates premium session with concierge priority', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          supportConfigProvider.overrideWithValue(
            const SupportConfig(
              tier: SupportTier.premium,
              locale: 'ja',
              enableConcierge: true,
            ),
          ),
        ],
      );

      final SupportExperience experience =
          container.read(supportExperienceProvider);
      final SupportSession session = experience.openSession(
        customerId: 'vip-001',
        topic: 'data-loss',
      );

      expect(session.priorityLane, isTrue);
      expect(session.channels, contains('slack-connect'));
      expect(session.estimatedResponse, const Duration(minutes: 3));
      expect(session.greeting, contains('VIP'));
      container.dispose();
    });

    test('throws when standard tier uses unsupported locale', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          supportConfigProvider.overrideWithValue(
            const SupportConfig(
              tier: SupportTier.standard,
              locale: 'fr',
            ),
          ),
        ],
      );

      final SupportExperience experience =
          container.read(supportExperienceProvider);
      expect(
        () => experience.openSession(
          customerId: 'cust-fr',
          topic: 'integration',
        ),
        throwsA(isA<UnsupportedError>()),
      );
      container.dispose();
    });
  });
}
