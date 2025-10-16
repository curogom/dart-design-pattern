import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/common/coming_soon_page.dart';
import 'features/week01/task_report_page.dart';
import 'features/week01/theme_switcher_page.dart';
import 'features/week02/delivery_tracker_page.dart';

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
      description: '위젯 트리 확장 데모 (구현 예정).',
      builder: (_) => const ComingSoonPage(weekLabel: '3주차'),
    ),
    PatternDemo(
      title: '4주차 · 팩토리 메서드 & 추상 팩토리',
      description: '생성 패턴 활용 예시 (구현 예정).',
      builder: (_) => const ComingSoonPage(weekLabel: '4주차'),
    ),
    PatternDemo(
      title: '5주차 · 상태 관리 패턴',
      description: '상태 전환과 로깅 데모 (구현 예정).',
      builder: (_) => const ComingSoonPage(weekLabel: '5주차'),
    ),
    PatternDemo(
      title: '6주차 · 종합 응용',
      description: '어댑터·프록시 모킹 예시 (구현 예정).',
      builder: (_) => const ComingSoonPage(weekLabel: '6주차'),
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
