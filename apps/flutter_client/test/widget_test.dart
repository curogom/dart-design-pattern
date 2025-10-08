// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:headfirst_flutter_client/main.dart';

void main() {
  testWidgets('홈 화면에서 1주차 패턴 리스트를 노출하고 상세로 이동한다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PatternDemoApp()),
    );

    expect(find.text('1주차 · 전략 패턴: 테마 스위처'), findsOneWidget);
    expect(find.text('1주차 · 템플릿 메서드: 업무 보고서'), findsOneWidget);

    await tester.tap(find.text('1주차 · 전략 패턴: 테마 스위처'));
    await tester.pumpAndSettle();

    expect(find.textContaining('전략 패턴 ·'), findsOneWidget);
    expect(find.text('프리뷰'), findsOneWidget);
  });
}
