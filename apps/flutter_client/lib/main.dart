import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/week01/task_report_page.dart';
import 'features/week01/theme_switcher_page.dart';
import 'features/week02/delivery_tracker_page.dart';
import 'features/week03/decorator_composite_page.dart';
import 'features/week04/factory_method_logger_page.dart';
import 'features/week04/support_suite_page.dart';
import 'features/week05/support_state_machine_page.dart';
import 'features/week06/support_review_page.dart';

void main() {
  runApp(const ProviderScope(child: PatternDemoApp()));
}

class PatternDemoApp extends StatelessWidget {
  const PatternDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Head First Patterns',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A237E),
      ),
      home: const PatternHomePage(),
    );
  }
}

class PatternHomePage extends StatelessWidget {
  const PatternHomePage({super.key});

  static final _demos = <PatternDemo>[
    PatternDemo(
      title: '1주차 · 전략 패턴: 테마 스위처',
      description: 'SegmentedButton으로 런타임 테마 전략을 교체합니다.',
      builder: (_) => const ThemeSwitcherPage(),
    ),
    PatternDemo(
      title: '1주차 · 템플릿 메서드: 업무 보고서',
      description: 'Dropdown으로 정렬 템플릿을 바꿔 보고서를 생성합니다.',
      builder: (_) => const TaskReportPage(),
    ),
    PatternDemo(
      title: '2주차 · 옵저버 패턴',
      description: '배송 상태 전파와 오류 알림을 Stream으로 체험합니다.',
      builder: (_) => const DeliveryTrackerPage(),
    ),
    PatternDemo(
      title: '3주차 · 데코레이터 & 컴포지트',
      description: '레이어 비용과 스타일 트리를 인터랙티브하게 조정합니다.',
      builder: (_) => const Week03DecoratorCompositePage(),
    ),
    PatternDemo(
      title: '4주차 · 팩토리 메서드: 감사 로그',
      description: 'Provider override로 로그 싱크를 교체해 봅니다.',
      builder: (_) => const FactoryMethodLoggerPage(),
    ),
    PatternDemo(
      title: '4주차 · 추상 팩토리: Support Suite',
      description: 'Tier/Locale에 맞춰 에이전트와 채널 구성을 생성합니다.',
      builder: (_) => const SupportSuitePage(),
    ),
    PatternDemo(
      title: '5주차 · 상태 & 싱글턴',
      description: '티켓 상태 머신과 Telemetry 싱글턴을 실시간 체험합니다.',
      builder: (_) => const SupportStateMachinePage(),
    ),
    PatternDemo(
      title: '6주차 · 어댑터 & 프록시',
      description: '대화 로그 변환과 KB 프록시 캐시를 확인합니다.',
      builder: (_) => const SupportReviewPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Head First Design Patterns 스터디'),
      ),
      body: ListView.separated(
        itemCount: _demos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final demo = _demos[index];
          return ListTile(
            title: Text(demo.title),
            subtitle: Text(demo.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: demo.builder),
              );
            },
          );
        },
      ),
    );
  }
}

class PatternDemo {
  const PatternDemo({
    required this.title,
    required this.description,
    required this.builder,
  });

  final String title;
  final String description;
  final WidgetBuilder builder;
}
