# Singleton 패턴 요약 (Week 05)

## 10줄 요약
1. `TelemetryCenter`는 전역 싱글턴으로 상태 머신 전이와 카운터를 한 곳에서 집계한다.
2. private 생성자와 factory를 통해 애플리케이션 어디서나 동일 인스턴스를 공유한다.
3. 전이 이벤트는 `TransitionLogEntry`로 추상화되어 UI·로그·테스트가 동일한 구조를 사용한다.
4. `StreamController.broadcast()`를 사용해 여러 구독자가 동시에 리스닝할 수 있다.
5. 카운터 맵은 lazy 업데이트로 성능 부담 없이 지표를 누적한다.
6. Riverpod 상태 머신은 싱글턴의 `ingestTransition`을 sink로 주입한다.
7. 테스트에서는 `reset()`을 호출해 전역 상태를 초기화하고 독립성을 확보한다.
8. 콘솔 `main()`은 단일 세션에서 여러 전이를 기록해 동기화 흐름을 보여준다.
9. `snapshotCounters()`와 `snapshotMachineCounts()`가 관측용 불변 맵을 제공한다.
10. 싱글턴 + 전이 로그 구조 덕분에 상태 패턴, 위젯, 백엔드 로그가 같은 지표를 공유한다.

## 전역 지표 테이블
| Counter | 의미 | 증가 조건 |
| --- | --- | --- |
| `boot` | 세션/머신 초기화 횟수 | 시스템 시작 또는 재설정 |
| `ticket:<id>_<state>` | 티켓별 상태 전이 누계 | `SupportTicketMachine.transition` 호출 이후 |
| `custom:*` | 팀에서 정의한 임의 지표 | `incrementCounter` 호출 시 |

## 싱글턴 구현 체크포인트
- private 생성자 + static 인스턴스로 재생성 방지.
- 스트림은 broadcast로 열어 위젯/로거가 독립적으로 구독.
- 리셋 시 카운터와 전이 집계 둘 다 초기화.

## 안티패턴 비교 (5줄)
- DI 컨테이너 없이 전역 변수를 사용하면 테스트에서 초기화 순서를 제어하기 어렵다.
- 멀티톤으로 여러 Telemetry 인스턴스를 만들면 지표가 분산되어 분석이 힘들다.
- 스트림을 single-subscription으로 만들면 UI와 로거가 동시에 관측하지 못한다.
- `Map`을 외부에 직접 노출하면 동시 접근 시 뮤테이션 버그가 발생할 수 있다.
- 상태 머신에서 Telemetry 호출을 잊으면 지표 불일치로 QA가 힘들다.

## 연습 문제 (Hints 포함)
1. **지표 영속화 추가** – `TelemetryCenter` 스트림을 파일로 flush하는 리스너를 구현하라. *Hint: `transitions.listen`으로 `IOSink`에 append하고, 앱 종료 시 `subscription.cancel()`을 잊지 않는다.*
2. **커스텀 메트릭 분리** – 카운터 이름 공간(namespace)을 모듈별로 분리해 충돌을 줄여라. *Hint: `incrementCounter` 내부에서 prefix를 강제하거나 wrapper 클래스를 도입한다.*
3. **Flutter 연동** – `StreamProvider`로 전이 스트림을 감싸 위젯에서 실시간 로그를 보여줘라. *Hint: `StreamProvider.autoDispose`로 구독을 관리하고, `ListView`에 `TransitionLogEntry`를 렌더링한다.*
