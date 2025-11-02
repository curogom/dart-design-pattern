# Adapter 패턴 요약 (Week 06)

## 10줄 요약
1. `SupportChatAdapter`가 레거시 채팅 로그를 현대적인 `ConversationThread` 모델로 변환한다.
2. 레거시 메시지는 `_`와 공백이 혼재해 있으므로 어댑터가 저작자 이름을 정규화한다.
3. 내부 메모 플래그를 `MessageVisibility.internal`로 매핑해 UI가 즉시 구분하도록 설계했다.
4. 시간은 epoch seconds → `DateTime`으로 변환하며, Duration 계산으로 상담 길이를 측정한다.
5. `ConversationThread`는 참가자 집합을 제공해 분석/보고서에서 바로 활용할 수 있다.
6. 어댑터는 비어 있는 로그도 안정적으로 처리해 에지 케이스를 방지한다.
7. 도메인 모델은 불변으로 설계해 테스트와 캐싱 시 안전하게 공유할 수 있다.
8. 통합 파사드(`SupportReviewFacade`)가 어댑터 결과를 기반으로 지식 베이스와 연동한다.
9. 테스트는 참가자·가시성·Duration 등 핵심 속성을 검증한다.
10. 콘솔 `main()`은 대화 로그를 변환해 요약을 출력하며 피드백 루프를 빠르게 확인시킨다.

## 변환 맵핑 예시
| Legacy 필드 | 변환 필드 | 설명 |
| --- | --- | --- |
| `sender` | `author` | `_` → 공백, trim 처리 |
| `body` | `content` | 앞뒤 공백 제거 |
| `epochSeconds` | `timestamp` | `DateTime.fromMillisecondsSinceEpoch` |
| `internal` | `visibility` | `true` → `internal`, `false` → `public` |

## 어댑터 체크리스트
- 입력이 비어 있어도 Duration 0으로 반환.
- 참가자 목록은 `Set`으로 추려 중복 제거.
- 확장성을 위해 인터페이스(`ChatTranscriptAdapter`)로 추상화.

## 안티패턴 비교 (5줄)
- UI가 직접 레거시 모델을 파싱하면 화면마다 서로 다른 파싱 로직이 생긴다.
- adapter 없이 Map → Map 복사만 하면 타입 안정성이 떨어진다.
- 타임스탬프를 문자열로 유지하면 시간대 계산에서 오류가 발생한다.
- 내부 메모 플래그를 무시하면 고객에게 노출될 수 있는 치명적 실수가 생긴다.
- 참가자 목록을 배열로 유지하면 중복으로 인해 KPI가 부정확해진다.

## 연습 문제 (Hints 포함)
1. **다국어 처리** – 메시지 본문에서 언어 태그를 추출해 `ConversationMessage`에 필드로 추가하라. *Hint: 정규식으로 `lang=en:` 패턴을 파싱하고 기본값을 `ko`로 둔다.*
2. **Thread Statistics** – 어댑터가 응답 시간 평균을 계산해 `ConversationThread`에 포함시키라. *Hint: 메시지를 pair로 순회하며 고객→상담원 간 간격을 누적하고, `Duration`으로 반환한다.*
3. **Flutter Widget** – 변환된 메시지를 `ListView`로 렌더링하고 `visibility`에 따라 배경색을 바꿔라. *Hint: `Map` 대신 도메인 객체를 그대로 위젯에 전달한다.*
