import 'package:riverpod/riverpod.dart';

import 'support_suite.dart';

void main() {
  final ProviderContainer standardContainer = ProviderContainer(
    overrides: [
      // 표준 지원 플로우를 생성하도록 설정 주입.
      supportConfigProvider.overrideWithValue(
        const SupportConfig(
          tier: SupportTier.standard,
          locale: 'ko',
        ),
      ),
    ],
  );
  final SupportExperience standardExperience =
      standardContainer.read(supportExperienceProvider);
  final SupportSession standardSession = standardExperience.openSession(
    customerId: 'cust-1001',
    topic: 'billing',
  );

  _printSession('Standard support', standardSession);
  standardContainer.dispose();

  final ProviderContainer premiumContainer = ProviderContainer(
    overrides: [
      // 컨시어지 옵션이 활성화된 프리미엄 플로우 예시.
      supportConfigProvider.overrideWithValue(
        const SupportConfig(
          tier: SupportTier.premium,
          locale: 'ko',
          enableConcierge: true,
        ),
      ),
    ],
  );
  final SupportExperience premiumExperience =
      premiumContainer.read(supportExperienceProvider);
  final SupportSession premiumSession = premiumExperience.openSession(
    customerId: 'cust-9000',
    topic: 'incident-response',
  );

  _printSession('Premium support', premiumSession);
  premiumContainer.dispose();
}

void _printSession(String label, SupportSession session) {
  print('=== $label ===');
  print('greeting: ${session.greeting}');
  print('topic: ${session.topic}');
  print('priorityLane: ${session.priorityLane}');
  print(
    'channels: ${session.channels.join(', ')} · SLA=${session.estimatedResponse.inMinutes}분',
  );
  print('article: ${session.recommendedArticlePath}');
}
