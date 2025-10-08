# 6주차 Overview

## 학습 목표
- 어댑터와 프록시 패턴으로 외부 API와 내부 모델을 연결한다.
- 이전 주차 패턴들을 복습하며 통합 아키텍처를 설계한다.
- HTTP 모킹, 캐싱, 지연 평가 전략을 실습한다.

## 준비 사항
- `lib/src/adapter/`, `lib/src/proxy/`, `lib/src/review/` 등 통합 샘플 구성
- 콘솔/위젯 예제에 네트워크 모킹과 캐싱 계층 포함
- `test/adapter/`, `test/proxy/`에서 happy/edge/timeout 시나리오 검증

## 산출물 체크리스트
- 외부 API ↔ 내부 모델 매핑 표 추가
- README 10줄 요약, 안티패턴 비교 5줄, 과제 3개
- 성능 지표(응답 시간, 캐시 적중률 등)를 PR에 첨부
