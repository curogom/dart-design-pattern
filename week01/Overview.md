# 1주차 Overview

## 학습 목표
- 전략 패턴으로 런타임 전략 교체 흐름을 이해한다.
- 템플릿 메서드 패턴으로 공통 알고리즘 뼈대를 분리한다.
- Flutter 테마/스타일 변경 예제를 통해 위 패턴을 체득한다.

## 준비 사항
- `week01/dart/lib/strategy/`, `week01/dart/lib/template_method/` 구조 유지
- 실행 가능한 `main()`과 동일 로직의 Flutter 위젯 샘플을 준비
- `week01/dart/test/` 아래에서 happy/edge 테스트 구성

## 산출물 체크리스트
- Riverpod 3 provider 구조 정의 및 주석
- README 10줄 요약, 안티패턴 비교 5줄, 과제 3개
- 골든 테스트 시 `flutter test --update-goldens` 수행 로그 첨부

## 산출물 경로
- 순수 Dart 코드: `week01/dart/lib/src/strategy/theme_strategy.dart`, `week01/dart/lib/src/template_method/task_report.dart`
- 테스트: `week01/dart/test/strategy/theme_strategy_test.dart`, `week01/dart/test/template_method/task_report_test.dart`
- 문서: `week01/docs/strategy.md`, `week01/docs/template_method.md`
- Q&A 답변: `week01/docs/strategy_qna.md`, `week01/docs/template_method_qna.md`
- 과제 모범답안: `week01/docs/strategy_assignments.md`, `week01/docs/template_method_assignments.md`
- Flutter 데모: `apps/flutter_client/lib/features/week01/`
