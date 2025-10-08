# Template Method 패턴 과제 모범답안

1. **필터링 훅 추가**  
   - `TaskReportTemplate`에 `bool shouldInclude(String task) => true;` 훅을 추가하고, `buildReport`에서 `tasks.where(shouldInclude).toList()`를 호출한다.  
   - 특정 태그만 포함하려면 하위 클래스에서 `shouldInclude`를 오버라이드해 조건을 지정한다.

2. **정렬 기준을 외부 주입 전략으로 교체**  
   - 템플릿 생성자에서 `Comparator<String>`를 받도록 하고, 기본값으로 기존 정렬 로직을 제공한다.  
   - 하위 클래스는 `super(comparator: customComparator);`를 호출해 전략을 전달하며, 템플릿은 전달받은 비교 함수를 사용한다.

3. **Flutter 리스트에 예상 소요 시간 그래프 표시**  
   - 각 항목을 `ListTile` 대신 `Card`로 감싸고, `LinearProgressIndicator(value: minutes / totalMinutes)`를 추가한다.  
   - Riverpod Provider에서 총 시간을 계산해 UI에 전달하면 재사용성과 테스트 용이성이 높아진다.
