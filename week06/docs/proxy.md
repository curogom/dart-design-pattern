# Proxy 패턴 요약 (Week 06)

## 10줄 요약
1. `CachedKnowledgeBaseClient`가 원격 KB API 앞에서 캐시/통계를 제공하는 보호 프록시 역할을 한다.
2. 실제 호출은 `RemoteKnowledgeBaseClient`가 담당하고, 프록시가 TTL과 지연을 설정한다.
3. `CacheStats`는 총 요청, 히트, 미스를 기록하고 손쉽게 히트율을 계산한다.
4. 프록시는 `Map` 기반 캐시로 작은 샘플을 빠르게 확인할 수 있게 구성되어 있다.
5. TTL 검사는 fetch 이전에 수행해 만료 항목은 즉시 재요청한다.
6. `pruneExpired()`로 백그라운드 관리 작업을 쉽게 붙일 수 있다.
7. Riverpod `knowledgeBaseClientProvider`가 프록시를 주입해 위젯과 테스트가 동일한 구성을 공유한다.
8. `articleProvider`는 `FutureProvider.family`로 특정 slug를 조회하고, autoDispose로 리소스를 회수한다.
9. 테스트는 캐시 히트/미스, TTL 만료, Provider 동작을 모두 검증한다.
10. 콘솔 `main()`은 두 번의 요청을 통해 캐시 적중률을 출력하고 지연 효과를 시각화한다.

## 캐시 상태 테이블
| 필드 | 설명 |
| --- | --- |
| `_cache` | slug → Article 매핑 |
| `_expiry` | slug → 만료 시각 |
| `_requests` | 총 요청 수 |
| `_hits` | 캐시 적중 수 |
| `_misses` | 캐시 미스 수 |

## 프록시 행동 시퀀스
1. `fetch(slug)` 호출 → `_requests` 증가.
2. 캐시·만료 검사 → 히트면 `_hits` 증가 후 Article 반환.
3. 미스면 원격 클라이언트 호출 → `_misses` 증가, 캐시에 저장.
4. `stats`로 현황 리포트, `pruneExpired`로 TTL 관리.

## 안티패턴 비교 (5줄)
- 원격 API를 직접 호출하면 반복 요청에서 지연이 누적된다.
- 캐시가 없는 상태에서 테스트하면 실제 API 모킹이 필요해 복잡해진다.
- TTL을 두지 않으면 오래된 가이드가 계속 노출된다.
- 캐시 통계를 수집하지 않으면 최적화 여부를 판단하기 어렵다.
- Provider 없이 전역 변수에 프록시를 저장하면 멀티 인스턴스 테스트가 힘들다.

## 연습 문제 (Hints 포함)
1. **LRU 캐시 적용** – `_cache`를 LRU 전략으로 교체해 메모리 사용량을 제한하라. *Hint: `LinkedHashMap` 기반으로 접근 순서를 추적하고, 용량 초과 시 첫 항목을 제거한다.*
2. **Prefetch 전략** – 미리 정의된 인기 슬러그를 `fetch` 전에 warm-up 하라. *Hint: 프록시 생성 시 `Future.wait`로 delegate 호출을 선행하고, 결과를 캐시에 넣는다.*
3. **지연 모니터링** – `fetch` 지연 시간 분포를 수집해 Telemetry 싱크에 전송하라. *Hint: `Stopwatch`를 사용하고, 싱글턴 Telemetry에 기록하도록 훅을 추가한다.*
