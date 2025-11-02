# Abstract Factory 패턴 요약 (Week 04)

## 10줄 요약
1. `SupportSuiteFactory`가 Support 에이전트와 티켓 워크플로우를 한 번에 생성한다.
2. 표준/프리미엄 팩토리가 동일한 인터페이스를 구현해 DI 컨테이너에서 손쉽게 교체된다.
3. `SupportAgent`는 로케일별 인사/추천 경로를, `TicketWorkflow`는 SLA와 채널 구성을 담당한다.
4. 프리미엄 팩토리는 컨시어지 옵션을 읽어 응답 속도·채널 목록을 즉시 조정한다.
5. Riverpod `supportSuiteFactoryProvider`가 tier/locale 설정을 읽어 올바른 팩토리를 선택한다.
6. `SupportExperience` 파사드가 생성된 제품군을 묶어 `SupportSession`을 만든다.
7. 테스트는 프리미엄 세션이 우선순위 라우팅과 Slack Connect 채널을 포함하는지 검증한다.
8. 표준 tier에서 미지원 로케일을 요청하면 생성 단계에서 `UnsupportedError`로 빠르게 실패한다.
9. `main()`은 같은 API로 표준/프리미엄 세션을 생성해 차이를 콘솔에 출력한다.
10. 패턴을 통해 위젯·서비스 샘플에서 생성 책임을 한 곳에 모아 의존성 그래프를 단순화한다.

## 생성 경로 표
| tier | locale | 팩토리 | 에이전트 | 워크플로우 |
| --- | --- | --- | --- | --- |
| `standard` | `ko` | `StandardSupportFactory` | `StandardSupportAgent('ko')` | `StandardTicketWorkflow` |
| `premium` | `ko` + concierge | `PremiumSupportFactory` | `PremiumSupportAgent('ko', concierge: true)` | `PremiumTicketWorkflow(concierge: true)` |
| `premium` | `ja` | `PremiumSupportFactory` | `PremiumSupportAgent('ja')` | `PremiumTicketWorkflow(concierge: false)` |

## Riverpod Provider 관계
| Provider | 타입 | 역할 |
| --- | --- | --- |
| `supportConfigProvider` | `Provider<SupportConfig>` | tier/locale/컨시어지 설정을 중앙에서 관리한다. |
| `supportSuiteFactoryProvider` | `Provider<SupportSuiteFactory>` | 설정을 읽어 표준/프리미엄 팩토리를 선택한다. |
| `supportExperienceProvider` | `Provider<SupportExperience>` | 팩토리를 주입받아 세션 파사드를 노출한다. |

## 생성 캐시 전략 설명
- 팩토리는 무상태이므로 Provider가 기본적으로 싱글턴처럼 재사용하며 비용이 없다.
- 컨시어지 여부가 바뀌면 Provider override를 이용해 새 팩토리를 주입하고, 세션 단위로 제품을 다시 생성한다.
- 다국어 지원 확장을 대비해 팩토리 단계에서 로케일을 검증해 잘못된 조합을 초기에 차단한다.

## 안티패턴 비교 (5줄)
- 조건문으로 로케일별 분기를 직접 작성하면 에이전트/워크플로우 변경 시 중복이 발생한다.
- 하나의 거대 팩토리에서 모든 제품 타입을 switch로 생성하면 테스트 격리가 어려워진다.
- 위젯 코드에서 `PremiumSupportAgent`를 직접 new 하면 tier 전환이 불가능하다.
- 전역 상수로 채널 목록을 관리하면 컨시어지 옵션을 반영하기 어렵다.
- 서비스 레이어가 로케일 검증을 중복 수행하면 책임이 분산되고 유지보수가 힘들다.

## 연습 문제 (Hints 포함)
1. **에이전트 타입 추가** – `SupportAgent`를 상속받는 `DeveloperSupportAgent`를 추가해 버그 리포트만 처리하도록 설계하라. *Hint: `SupportConfig`에 카테고리 필드를 추가하고 팩토리에서 분기한다.*
2. **지식 베이스 제품군 확장** – 팩토리가 `KnowledgeBase`까지 생성하도록 인터페이스를 확장하라. *Hint: 표준/프리미엄이 서로 다른 캐싱 정책을 가지도록 build-time 전략을 비교한다.*
3. **Flutter 위젯 연동** – `SupportSession` 데이터를 카드 위젯으로 표현하고 tier에 따라 아이콘/색상을 바꿔라. *Hint: `supportExperienceProvider`를 `flutter_riverpod`에서 watch해 `ListView`에 바인딩한다.*
