# Template Method 패턴 (템플릿 메서드)

## 한 줄 정의
공통 알고리즘 뼈대를 상위 클래스에 두고 하위 클래스가 특정 단계만 오버라이드하여 행동을 확장한다.

## 핵심 개념 요약
- **템플릿 메서드**: 알고리즘 뼈대를 정의하며 서브클래스가 호출 순서를 바꾸지 못하게 보호한다.
- **훅 메서드**: 선택적으로 오버라이드 가능한 메서드로, 기본 구현을 제공해 확장 부담을 줄인다.
- **순서 보장**: 상위 클래스에서 전체 흐름을 통제하므로, 변경 가능한 부분과 고정된 부분을 명확히 분리한다.
- **불변 데이터 선호**: 리스트나 도메인 객체는 복사본을 활용해 하위 클래스가 원본을 변경하지 않게 한다.

## 적용 절차
1. 알고리즘 단계를 식별하고, 고정 단계와 가변 단계를 구분한다.
2. 고정 단계는 템플릿 메서드에 순서대로 배치하고, 가변 단계는 추상 메서드나 훅으로 선언한다.
3. 공통 후처리가 필요하면 상위 클래스에서 기본 구현을 제공하고, 필요 시 `super.decorate()`처럼 호출하도록 한다.
4. 하위 클래스는 최소한의 단계만 오버라이드하고, 상태를 가지지 않는 순수 함수를 유지한다.
5. `@protected`와 같은 접근 제어를 활용해 템플릿 구조가 무너지는 것을 방지한다.

## UML 텍스트 다이어그램
```
TaskReportTemplate <|-- PriorityTaskReport
TaskReportTemplate <|-- DurationTaskReport
Client --> TaskReportTemplate.buildReport()
```

## 콘솔 예제
```dart
void main() {
  const template = PriorityTaskReport();
  final report = template.buildReport([
    '[LOW] Cleanup (10m)',
    '[HIGH] Strategy sample (50m)',
    '[MID] Refactor (30m)',
  ]);
  report.forEach(print);
}
```

## Flutter 위젯 예제
```dart
class TaskReportApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(sortedTaskReportProvider);
    return MaterialApp(
      home: ListView.builder(
        itemCount: lines.length,
        itemBuilder: (_, index) => ListTile(title: Text(lines[index])),
      ),
    );
  }
}
```

## Riverpod 3 적용 포인트
- 템플릿 선택은 `StateProvider<TaskReportTemplate>`로 관리해 Dropdown과 쉽게 바인딩한다.
- `Provider<List<String>>`는 훅 메서드가 만든 데이터를 읽을 뿐이므로 위젯 테스트가 간단하다.
- 동일한 템플릿을 다양한 데이터셋에 적용하려면 `Provider.family`를 활용하면 된다.
- 비동기 계산이 필요하다면 `FutureProvider`나 `StreamProvider`를 조합해 템플릿 결과를 감싼다.

## 실전 적용 팁
- 보고서, 정렬, 필터링처럼 공통 파이프라인이 존재하고 일부 단계만 다를 때 사용한다.
- 훅 메서드를 너무 많이 만들면 구조가 복잡해지므로, 단계가 늘어난다면 전략 패턴과 혼합하는 것을 고려한다.
- Flutter UI에서는 템플릿 결과를 `ListView`나 `DataTable`에 바로 바인딩해 재사용성을 높인다.

## 안티패턴·주의점·성능 메모
- 하위 클래스가 알고리즘의 여러 단계를 변경하면 템플릿 구조가 흐트러지므로 단계 분리를 과감히 하라.
- 템플릿이 데이터를 많이 복사하면 성능 문제가 생긴다. 불변 리스트를 재사용하거나 lazy iterator를 고려하라.
- 훅 메서드에서 I/O나 비동기 작업을 수행하면 예측이 어려워진다. 오프라인 작업만 허용하거나 별도 async 템플릿을 만든다.

## 예상 Q&A
1. 템플릿 메서드와 전략 패턴의 차이는?
2. Riverpod에서 템플릿을 family로 만들면 어떤 장점이 있는가?
3. 훅 메서드를 필수 구현으로 강제하려면 어떻게 해야 하는가?
4. 비동기 작업을 포함하려면 구조를 어떻게 바꿔야 하는가?
5. 템플릿이 너무 복잡해지면 대안은 무엇인가?

> 상세 답변은 `template_method_qna.md`를 참고하세요.

## 과제와 힌트
1. **문제**: `TaskReportTemplate`에 필터링 훅을 추가해 특정 태그만 포함시키라. (힌트: `shouldInclude(String task)`를 추가하고 `buildReport`에서 필터링.)
2. **문제**: 정렬 기준을 외부 주입 전략으로 교체하고 템플릿은 순서만 관리하라. (힌트: `Comparator<String>`을 생성자 매개변수로 받는다.)
3. **문제**: Flutter 리스트 항목에 예상 소요 시간을 그래프 형태로 표시하라. (힌트: `LinearProgressIndicator`와 `Consumer`를 사용한다.)

> 모범 답안은 `template_method_assignments.md`에서 확인할 수 있습니다.
