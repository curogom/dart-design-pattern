# Composite 패턴 요약 (Week 03)

## 10줄 요약
1. 컴포지트는 계층 구조를 단일 인터페이스(`ThemeNode`)로 통합해 재귀적 연산을 단순화한다.
2. `ThemeLeaf`가 실질 스타일(속성, 비용, 지연)을 정의하고, `ThemeBranch`가 자식 노드를 보유한다.
3. `compose()`는 모든 하위 노드를 순회해 속성을 병합하고, 비용/지연을 누적한다.
4. 브랜치마다 `overheadCost`와 `latency`를 두어 레이아웃 래퍼의 추가 부담을 표현한다.
5. `StyleSnapshot`은 플랫한 스타일 맵과 비용 분해(`costBreakdown`)를 함께 제공한다.
6. `replaceLeaf`는 불변 복제 방식을 사용해 기존 트리를 손상시키지 않고 업데이트를 적용한다.
7. `ThemeTreeNotifier`는 Riverpod `Notifier`로 루트 트리를 소유하고 상태를 노출한다.
8. `swapLeaf`는 타깃 노드를 찾아 새 `ThemeLeaf`로 교체하며 리빌드 횟수를 1회로 유지한다.
9. `outline()`은 디버깅을 위해 트리 구조를 텍스트로 시각화한다.
10. 콘솔 `main()`은 초기/갱신 스냅샷과 리빌드 카운트를 출력해 흐름을 검증한다.

## UML 텍스트 다이어그램
```text
            +-----------------+
            |   ThemeNode     |
            | +compose()      |
            | +replaceLeaf()  |
            +--------+--------+
                     ^
        +------------+-------------+
        |                          |
+---------------+        +--------------------+
| ThemeLeaf     |        | ThemeBranch        |
| -attributes   |        | -children          |
| -rebuildCost  |        | -overheadCost      |
| -latency      |        | -latency           |
+---------------+        +--------------------+
```

## Riverpod Provider 관계
| Provider | 타입 | 역할 |
| --- | --- | --- |
| `themeTreeProvider` | `NotifierProvider<ThemeTreeNotifier, StyleSnapshot>` | 루트 스타일 트리를 보유하고 스냅샷 상태를 노출한다. |
| `ThemeTreeNotifier.swapLeaf` | `Notifier` 메서드 | 특정 리프 노드를 교체해 커스텀 스타일을 적용한다. |
| `RebuildCounterObserver` | `ProviderObserver` | 갱신 시점에서 리빌드 횟수와 타이밍을 기록한다. |

## 안티패턴 비교 (5줄)
- 딕셔너리 중첩만 사용: 타입 안정성이 없고, 부분 업데이트 시 어디까지 영향을 미치는지 추적이 어렵다.
- 부모가 자식을 직접 new로 생성: 테스트에서 가짜 트리를 주입하기 힘들고 재사용성이 낮다.
- 지연 비용 무시: 하위 요소 개수와 무관하게 동일 비용을 가정하면 최적화 포인트를 놓친다.
- 가변 리스트 공유: 자식 리스트를 그대로 노출하면 외부에서 구조를 깨트릴 위험이 생긴다.
- 탐색 시 `for` 대신 인덱스 접근: 계층형 구조에서 index 기반 접근은 버그를 유발하고 가독성을 떨어뜨린다.

## 연습 문제 (Hints 포함)
1. **부분 트리 지연 분석** – 특정 브랜치(`typography`)만의 총 지연을 계산하는 메서드를 추가하라. *Hint: `ThemeBranch.compose` 반환값에서 `costBreakdown`을 활용할 수 있다.*
2. **다중 교체 지원** – 한 번의 호출로 여러 리프를 갱신하는 `swapLeaves(Map<String, ThemeLeaf>)`를 작성해라. *Hint: 내부적으로 `_replaceLeafInternal`을 반복 호출하거나 배치 알고리즘을 도입한다.*
3. **Diff 시각화** – 이전/이후 `StyleSnapshot`을 비교해 변경된 키만 출력하는 함수를 추가하라. *Hint: `MapEquality` 혹은 간단한 반복으로 변경된 속성을 수집하면 된다.*
