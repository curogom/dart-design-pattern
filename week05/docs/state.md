# State 패턴 요약 (Week 05)

## 10줄 요약
1. `SupportTicketMachine`은 티켓 상태 전이를 캡슐화한 컨텍스트 객체다.
2. 각 상태(`New`, `InProgress`, `Escalated`, `Resolved`, `Closed`)는 전환 가능한 이벤트만 처리한다.
3. 유효하지 않은 이벤트는 `StateTransitionError`를 던져 실수로 인한 잘못된 전이를 차단한다.
4. `TransitionLoggerMixin`이 상태 전환을 기록하고 Telemetry 싱크에 전달한다.
5. 전이는 `timeline` 리스트로도 축적되어 UI에서 히스토리 라인을 쉽게 렌더링할 수 있다.
6. Riverpod `SupportTicketController`가 상태 머신을 감싸고 UI가 사용할 스냅샷을 제공한다.
7. Provider override로 `TicketConfig`를 바꿔 여러 티켓을 독립적으로 시뮬레이션한다.
8. 테스트에서는 happy-path, escalated-path, invalid-path를 모두 검증해 회귀를 방지한다.
9. 싱글턴 Telemetry는 상태 패턴과 결합해 전역 지표를 자동으로 누적한다.
10. `main()`은 할당→해결→종료 흐름을 출력해 패턴 구조를 콘솔에서 확인하게 한다.

## 전이 표
| 현재 상태 | 이벤트 | 다음 상태 | 부가 설명 |
| --- | --- | --- | --- |
| `new` | `assign` | `inProgress` | 초기 담당자 배정 |
| `inProgress` | `escalate` | `escalated` | L2/전문가에게 전달 |
| `inProgress` | `resolve` | `resolved` | 문제 해결 |
| `inProgress` | `close` | `closed` | 바로 종료(긴급 차단) |
| `escalated` | `resolve` | `resolved` | 상향 지원 후 해결 |
| `resolved` | `close` | `closed` | 고객 확인 후 종료 |
| `resolved` | `reopen` | `inProgress` | 고객이 재오픈 |
| `closed` | `reopen` | `inProgress` | 종합 점검 후 재작업 |

## Riverpod Provider 관계
| Provider | 타입 | 역할 |
| --- | --- | --- |
| `ticketConfigProvider` | `Provider<TicketConfig>` | 티켓 식별자·주제 메타데이터 공급 |
| `supportTicketControllerProvider` | `AutoDisposeNotifierProvider<SupportTicketController, SupportTicketSnapshot>` | 상태 전이·로그를 UI 스냅샷으로 노출 |

## 로그 예시
```
TransitionLogEntry(machine: ticket:818, event: assign, from: new, to: inProgress, metadata: {note: Assigned to Agent-42}, timestamp: ...)
TransitionLogEntry(machine: ticket:818, event: resolve, from: inProgress, to: resolved, metadata: {note: Refund approved}, timestamp: ...)
TransitionLogEntry(machine: ticket:818, event: close, from: resolved, to: closed, metadata: {}, timestamp: ...)
```

## 안티패턴 비교 (5줄)
- 거대 switch 문으로 상태를 분기하면 새 상태 추가 때마다 조건이 기하급수적으로 늘어난다.
- 상태 객체 없이 문자열 비교만 하면 오타/중복으로 인해 런타임 버그가 잦아진다.
- 전이 로깅을 UI 레이어에서 직접 수행하면 로깅 누락이 발생한다.
- 전역 변수를 통해 현재 상태를 저장하면 병렬 처리 시 경합이 생긴다.
- 테스트에서 전이 경로를 나열하지 않으면 리팩터링 시 회귀를 탐지하기 어렵다.

## 연습 문제 (Hints 포함)
1. **SLA 타이머 추가** – 각 상태별 타임아웃을 설정하고 초과 시 자동으로 `escalate` 이벤트를 발생시키라. *Hint: 상태 객체에 `Duration? timeout`을 두고, Riverpod `ref.onDispose`를 활용해 타이머를 관리한다.*
2. **Webhook 연동** – 전이가 발생할 때 외부 웹훅을 호출하는 어댑터를 추가하라. *Hint: `TransitionSink`를 compose해 Telemetry와 Webhook을 동시에 호출한다.*
3. **Flutter 대시보드** – `supportTicketControllerProvider`를 `ConsumerWidget`에서 구독해 상태 배지와 로그 타임라인을 렌더링하라. *Hint: `ListView.separated`로 전이 로그를 시각화하고, 상태별 색상을 지정한다.*
