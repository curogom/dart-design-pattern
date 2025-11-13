# Review 통합 요약 (Week 06)

## 10줄 요약
1. `SupportReviewFacade`는 어댑터(`SupportChatAdapter`)와 프록시(`CachedKnowledgeBaseClient`)를 묶어 일관된 리뷰 보고서를 생성한다.
2. `ReviewRequest`는 `LegacyChatTranscript`와 연관 아티클 slug 배열을 수집해 입력을 표준화한다.
3. 파사드는 `Stopwatch`로 채팅 변환＋기사 페치에 걸린 총 지연 시간을 측정해 리포트에 기록한다.
4. 대화 로그는 어댑터를 거쳐 `ConversationThread`로 변환되며 참가자/가시성/Duration 정보가 정규화된다.
5. 지식 베이스 조회는 프록시 클라이언트가 TTL, hit/miss 카운터를 추적해 재호출 비용을 줄인다.
6. `ReviewReport`는 변환된 스레드, 가져온 기사 목록, 누적 지연 시간으로 구성된 불변 DTO다.
7. `reviewFacadeProvider`가 두 컴포넌트를 조합하고, 필요 시 Riverpod override로 상황별 설정을 주입한다.
8. `reviewReportProvider`는 `FutureProvider.family`로 구현되어 티켓별로 독립적인 비동기 상태를 노출한다.
9. 통합 테스트는 파사드가 기사 수·메시지 수·지연 시간을 모두 채우는지 검증해 회귀를 차단한다.
10. 콘솔 `main()`은 샘플 티켓에 대해 참여자, 기사 목록, 총 지연 시간을 출력해 흐름을 빠르게 확인시킨다.

## 외부 ↔ 내부 매핑
| 외부 입력 | 내부 모델 | 설명 |
| --- | --- | --- |
| `LegacyChatTranscript` | `ConversationThread` | `SupportChatAdapter`가 작성자/가시성/타임라인을 표준화한다. |
| `List<String> relatedArticles` | `List<Article>` | 프록시 클라이언트가 slug마다 원격 문서를 가져오고 캐시한다. |
| 원격 응답 지연 | `ReviewReport.totalLatency` | 파사드가 Stopwatch로 측정한 누적 시간으로 보고한다. |

## Riverpod Provider 관계
| Provider | 타입 | 역할 |
| --- | --- | --- |
| `knowledgeBaseConfigProvider` | `Provider<KnowledgeBaseConfig>` | KB TTL, 지연 시간을 주입해 프록시 동작을 제어한다. |
| `knowledgeBaseClientProvider` | `Provider<KnowledgeBaseClient>` | 원본 클라이언트를 프록시로 감싸 캐시/통계를 제공한다. |
| `reviewFacadeProvider` | `Provider<SupportReviewFacade>` | 어댑터와 프록시 클라이언트를 합성해 파사드를 노출한다. |
| `reviewReportProvider` | `FutureProvider.family<ReviewReport, ReviewRequest>` | 티켓별 리뷰 보고서를 비동기로 생성한다. |

## 안티패턴 비교 (5줄)
- UI에서 직접 레거시 로그와 KB API를 호출하면 중복 파싱·캐싱 코드가 생기고 테스트가 어려워진다.
- 캐시 없이 매번 원격 기사를 요청하면 텍스트 재활용 시에도 네트워크 비용이 반복된다.
- 지연 시간 측정을 무시하면 SLA 회귀나 캐시 적중률 비교가 불가능하다.
- Provider 없이 전역 싱글턴으로 파사드를 생성하면 테스트마다 상태가 공유되어 예측 불가능해진다.
- 요청·응답 DTO를 가변 객체로 유지하면 async 작업 중 데이터가 엉뚱하게 덮어써질 수 있다.

## 연습 문제 (Hints 포함)
1. **지연 경보 임계값 추가** – `ReviewReport`에 `Duration budget`을 포함하고 초과 시 경고 플래그를 세팅하라. *Hint: `SupportReviewFacade.buildReview`에서 Stopwatch 종료 후 비교하고, Provider override로 budget을 주입한다.*
2. **아티클 점수화** – 각 slug에 우선순위를 매겨 정렬된 기사 리스트를 반환하라. *Hint: `ReviewRequest`에 `Map<String, int>` 옵션을 추가하고 프록시 결과를 정렬한다.*
3. **오류 내성 강화** – 특정 기사 fetch가 실패해도 나머지를 계속 수집하도록 파사드를 확장하라. *Hint: `knowledgeBase.fetch` 호출을 `try/catch`로 감싸고 에러를 별도 리스트에 누적해 보고서에 포함한다.*
