# Decorator 패턴 요약 (Week 03)

## 10줄 요약
1. 데코레이터는 공통 인터페이스(`WidgetFeature`)를 유지하면서 기능을 단계적으로 확장한다.
2. `BaseWidgetFeature`가 카드 기본 스타일을 정의하고, 각 데코레이터가 가로질러(layer)를 추가한다.
3. `SpacingDecorator`, `SurfaceDecorator`, `ServiceHookDecorator`는 위젯·서비스 요구사항을 각각 해결한다.
4. 체인에 `ProfilingDecorator`를 마지막으로 추가해 전체 파이프라인의 총합 비용을 측정한다.
5. `StyledWidget`은 누적 레이어, 서비스 훅, 예측 비용을 담는 불변 데이터 전송 객체다.
6. 새 데코레이터는 `WidgetFeatureDecorator`를 상속받아 `transform`만 구현하면 된다.
7. `appendLayer`, `appendHook` 유틸 덕분에 불변성을 유지한 채 단계적 변형을 적용한다.
8. 리빌드 최적화를 위해 `RebuildCounterObserver`가 Provider 이벤트를 로그로 남긴다.
9. 파이프라인은 Riverpod `Provider`로 선언되어 테스트에서 동일하게 재사용된다.
10. 콘솔 `main()`은 체인 실행 결과와 성능 로그를 출력해 실습 흐름을 명확히 보여 준다.

## UML 텍스트 다이어그램
```text
+--------------------+       +-------------------------+
| WidgetFeature      |<------+ WidgetFeatureDecorator  |
| +build(request)    |       | +transform(base, req)   |
+--------------------+       +-----------+-------------+
             ^                          ^
             |                          |
             |                          +-------------------------------+
+--------------------------+   +-------------------+   +----------------+
| BaseWidgetFeature        |   | SpacingDecorator  |   | SurfaceDecorator|
+--------------------------+   +-------------------+   +----------------+
                                                       |
                                                       v
                                             +-----------------------+
                                             | ServiceHookDecorator  |
                                             +-----------------------+
                                                       |
                                                       v
                                             +----------------------+ 
                                             | ProfilingDecorator   |
                                             +----------------------+
```

## Riverpod Provider 관계
| Provider | 타입 | 역할 |
| --- | --- | --- |
| `performanceLogProvider` | `Provider<PerformanceLog>` | 데코레이터 체인의 비용 로그를 수집하고 수명 종료 시 정리한다. |
| `widgetFeatureProvider` | `Provider<WidgetFeature>` | 기반 기능을 순차적으로 감싼 최종 파이프라인을 노출한다. |
| `RebuildCounterObserver` | `ProviderObserver` | 테스트와 데모에서 Provider 리빌드 횟수를 계량화한다. |

## 안티패턴 비교 (5줄)
- 상속만 사용하는 경우: 모든 변형이 하나의 거대 클래스에 쌓여 OCP를 깨고 테스트가 어려워진다.
- 조건문 분기: `if/else`로 기능 토글을 관리하면 실행 흐름이 복잡해지고 누락된 조합이 생긴다.
- 믹스인 남용: `with` 체이닝은 순서를 보장하지 않아 레이어 누락/중복이 발생할 수 있다.
- 전역 싱글턴 데코레이터: 상태 공유로 인해 여러 위젯의 설정이 충돌하고 테스트 분리가 힘들다.
- 동적 캐스팅 의존: 구체 타입 캐스팅은 체인 가독성과 유지보수를 동시에 망가뜨린다.

## 연습 문제 (Hints 포함)
1. **다크 모드 전환 데코레이터 작성** – `SurfaceDecorator` 앞에 배치해 색상 팔레트를 교체하라. *Hint: `StyledWidget.appendLayer`로 테마 라벨을 추가하고 비용을 조건부로 조정한다.*
2. **서비스 훅 중복 제거 로직 개선** – 동일 훅을 여러 번 추가하면 비용이 누적되지 않도록 수정하라. *Hint: `appendHook`에서 Set 변환 없이 문자열 비교만으로도 필터링할 수 있다.*
3. **부분 성능 측정 추가** – `ServiceHookDecorator` 내부에서 API 호출 시간을 측정하도록 확장하라. *Hint: `PerformanceLog`에 파생 클래스를 도입하거나 새 엔트리를 추가하라.*
