import 'package:riverpod/riverpod.dart';

enum SupportTier {
  standard,
  premium,
}

class SupportConfig {
  const SupportConfig({
    required this.tier,
    required this.locale,
    this.enableConcierge = false,
  });

  final SupportTier tier;
  final String locale;
  final bool enableConcierge;
}

// 추상 팩토리가 공급하는 제품군 #1: 상담 에이전트.
abstract class SupportAgent {
  String greet(String customerId);

  String suggestArticle(String topic);
}

// 추상 팩토리가 함께 제공하는 제품군 #2: 티켓 워크플로우.
abstract class TicketWorkflow {
  bool get priorityRouting;

  Duration estimatedResponse();

  List<String> channels();
}

abstract class SupportSuiteFactory {
  // 패턴 핵심: 관련 객체를 함께 생성.
  SupportAgent createAgent();

  TicketWorkflow createWorkflow();
}

class StandardSupportAgent implements SupportAgent {
  StandardSupportAgent(String locale) : locale = _validate(locale);

  final String locale;

  static String _validate(String locale) {
    if (locale != 'ko' && locale != 'en') {
      throw UnsupportedError(
          'Locale $locale is not supported for standard tier.');
    }
    return locale;
  }

  @override
  String greet(String customerId) {
    switch (locale) {
      case 'ko':
        return '안녕하세요, $customerId 고객님. 무엇을 도와드릴까요?';
      case 'en':
        return 'Hello $customerId, how can we help you today?';
      default:
        throw StateError('Unexpected locale: $locale');
    }
  }

  @override
  String suggestArticle(String topic) {
    return 'faq/$locale/$topic';
  }
}

class PremiumSupportAgent implements SupportAgent {
  PremiumSupportAgent({
    required String locale,
    required this.conciergeEnabled,
  }) : locale = _validate(locale);

  final String locale;
  final bool conciergeEnabled;

  static String _validate(String locale) {
    if (locale != 'ko' && locale != 'en' && locale != 'ja') {
      throw UnsupportedError(
          'Locale $locale is not supported for premium tier.');
    }
    return locale;
  }

  @override
  String greet(String customerId) {
    final String salutation = switch (locale) {
      'ko' => 'VIP 고객님 $customerId, 빠르게 도와드릴게요.',
      'en' => 'Welcome back VIP $customerId, we are on it.',
      'ja' => 'VIP $customerId 様、すぐに対応いたします。',
      _ => throw StateError('Unexpected locale: $locale'),
    };
    return conciergeEnabled ? '$salutation (컨시어지 연결 준비 중)' : salutation;
  }

  @override
  String suggestArticle(String topic) {
    final String language = switch (locale) {
      'ko' => 'ko-KR',
      'en' => 'en-US',
      'ja' => 'ja-JP',
      _ => 'en-US',
    };
    return 'playbook/$language/$topic';
  }
}

class StandardTicketWorkflow implements TicketWorkflow {
  const StandardTicketWorkflow();

  @override
  bool get priorityRouting => false;

  @override
  Duration estimatedResponse() => const Duration(minutes: 25);

  @override
  List<String> channels() => const <String>['email', 'community'];
}

class PremiumTicketWorkflow implements TicketWorkflow {
  PremiumTicketWorkflow({required this.conciergeEnabled});

  final bool conciergeEnabled;

  @override
  bool get priorityRouting => true;

  @override
  Duration estimatedResponse() => conciergeEnabled
      ? const Duration(minutes: 3)
      : const Duration(minutes: 8);

  @override
  List<String> channels() {
    if (conciergeEnabled) {
      return const <String>['priority-chat', 'phone', 'slack-connect'];
    }
    return const <String>['priority-chat', 'phone'];
  }
}

class StandardSupportFactory implements SupportSuiteFactory {
  StandardSupportFactory(this.config);

  final SupportConfig config;

  @override
  SupportAgent createAgent() {
    return StandardSupportAgent(config.locale);
  }

  @override
  TicketWorkflow createWorkflow() {
    return const StandardTicketWorkflow();
  }
}

class PremiumSupportFactory implements SupportSuiteFactory {
  PremiumSupportFactory(this.config);

  final SupportConfig config;

  @override
  SupportAgent createAgent() {
    return PremiumSupportAgent(
      locale: config.locale,
      conciergeEnabled: config.enableConcierge,
    );
  }

  @override
  TicketWorkflow createWorkflow() {
    return PremiumTicketWorkflow(conciergeEnabled: config.enableConcierge);
  }
}

class SupportSession {
  const SupportSession({
    required this.customerId,
    required this.topic,
    required this.greeting,
    required this.recommendedArticlePath,
    required this.priorityLane,
    required this.channels,
    required this.estimatedResponse,
  });

  final String customerId;
  final String topic;
  final String greeting;
  final String recommendedArticlePath;
  final bool priorityLane;
  final List<String> channels;
  final Duration estimatedResponse;
}

class SupportExperience {
  SupportExperience(this.factory);

  final SupportSuiteFactory factory;

  // 팩토리에서 받은 제품군으로 도메인 세션을 조립한다.
  SupportSession openSession({
    required String customerId,
    required String topic,
  }) {
    final SupportAgent agent = factory.createAgent();
    final TicketWorkflow workflow = factory.createWorkflow();
    return SupportSession(
      customerId: customerId,
      topic: topic,
      greeting: agent.greet(customerId),
      recommendedArticlePath: agent.suggestArticle(topic),
      priorityLane: workflow.priorityRouting,
      channels: workflow.channels(),
      estimatedResponse: workflow.estimatedResponse(),
    );
  }
}

/// Support 경험 구성을 위한 tier/locale 설정 Provider.
final supportConfigProvider = Provider<SupportConfig>(
  (ref) {
    return const SupportConfig(
      tier: SupportTier.standard,
      locale: 'en',
    );
  },
  name: 'supportConfigProvider',
);

/// SupportSuiteFactory를 tier에 따라 선택하는 Provider.
final supportSuiteFactoryProvider = Provider<SupportSuiteFactory>(
  (ref) {
    final SupportConfig config = ref.watch(supportConfigProvider);
    switch (config.tier) {
      case SupportTier.standard:
        return StandardSupportFactory(config);
      case SupportTier.premium:
        return PremiumSupportFactory(config);
    }
  },
  name: 'supportSuiteFactoryProvider',
);

/// SupportExperience 파사드를 제공하는 Provider.
final supportExperienceProvider = Provider<SupportExperience>(
  (ref) {
    final SupportSuiteFactory factory = ref.watch(supportSuiteFactoryProvider);
    return SupportExperience(factory);
  },
  name: 'supportExperienceProvider',
);
