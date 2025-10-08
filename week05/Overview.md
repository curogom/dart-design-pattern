# 5주차 Overview

## 학습 목표
- 싱글턴과 상태(State) 패턴으로 상태 전이 로직을 모듈화한다.
- Riverpod와 Provider를 활용해 UI 상태를 일관되게 추적한다.
- 상태 전환 시점의 부작용과 로깅 전략을 설계한다.

## 준비 사항
- `lib/src/singleton/`, `lib/src/state/`에 콘솔·위젯 예제 배치
- 상태 머신 도식과 전이 표를 README에 추가
- `test/singleton/`, `test/state/`에서 happy/edge/에러 케이스 검증

## 산출물 체크리스트
- 상태 전환 로그를 수집하는 헬퍼 또는 믹스인 제공
- README 10줄 요약, 안티패턴 비교 5줄, 과제 3개
- 커버리지 85% 이상 유지, 부족 시 PR에서 사유와 보완 계획 기재
