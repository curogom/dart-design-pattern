# Strategy 패턴 (전략 패턴)

## 한 줄 정의
런타임에 교체 가능한 알고리즘 패밀리를 캡슐화해 클라이언트에서 독립적으로 사용할 수 있게 한다.

## UML 텍스트 다이어그램
```
Context --> Strategy
Strategy <|-- LightThemeStrategy
Strategy <|-- DarkThemeStrategy
Strategy <|-- HighContrastThemeStrategy
```

## 핵심 개념 요약
- **전략 인터페이스**: 교체 가능한 알고리즘의 공통 계약을 정의한다.
- **컨텍스트**: 전략 객체에 위임하고, 동적으로 전략을 교체할 수 있는 진입점.
- **구성 vs 상속**: 전략 패턴은 런타임에 구성을 바꿔 상속보다 더 유연한 확장을 제공한다.
- **무상태 객체 권장**: 전략 객체는 동일 입력에 동일 출력을 주어야 테스트와 캐싱이 간단해진다.

## 적용 절차
1. 알고리즘군에서 바뀌는 부분을 추출해 `ThemeStrategy`와 같은 인터페이스로 선언한다.
2. 각 전략을 독립 클래스로 분리하고, 공통 설정은 추상 클래스에 배치한다.
3. 컨텍스트 객체(`ThemeContext`)에서 전략의 구현을 알 필요 없이 인터페이스만 의존한다.
4. 전략 변경을 UI나 설정 변경과 연결할 때는 주입(Provider, DI)을 활용해 리빌드 범위를 최소화한다.
5. 새 전략 추가 시 컨텍스트 코드를 건드리지 않는지 확인한다.

## 콘솔 예제
```dart
void main() {
  final context = ThemeContext(const LightThemeStrategy());
  print(context.apply()); // AppTheme(light, primary: 16777214, ...)
  context.changeStrategy(const DarkThemeStrategy());
  print(context.apply()); // AppTheme(dark, primary: 1184274, ...)
}
```

## Flutter 위젯 예제
```dart
class ThemeSwitcherApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategy = ref.watch(themeStrategyProvider);
    final theme = ref.watch(currentThemeProvider);
    return MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Color(theme.accentColor))),
      home: SegmentedButton(
        segments: const [
          ButtonSegment(value: LightThemeStrategy(), label: Text('Light')),
          ButtonSegment(value: DarkThemeStrategy(), label: Text('Dark')),
        ],
        selected: {strategy},
        onSelectionChanged: (selection) {
          ref.read(themeStrategyProvider.notifier).state = selection.first;
        },
      ),
    );
  }
}
```

## Riverpod 3 적용 포인트
- `StateProvider<ThemeStrategy>`로 현재 전략을 보관하면 Consumer 위젯이 즉시 리빌드된다.
- `Provider<AppTheme>`는 전략 객체의 `buildTheme()`만 호출하므로 테스트가 버튼 없이도 가능하다.
- 고대비 전략처럼 새로운 전략을 추가할 때 Provider 트리를 수정할 필요가 없다.
- ProviderScope override를 이용하면 특정 위젯 트리에서만 전략을 달리 주입할 수 있다.

## 실전 적용 팁
- 다크 모드, 지역화, 접근성 설정처럼 사용자 선호가 달라지는 영역에 전략 패턴을 적용한다.
- 전략을 선택할 때는 `SegmentedButton`, `DropdownButton`, `Settings` 화면 등과 연결해 UX를 명확히 한다.
- 테마 데이터처럼 변경 빈도가 적은 객체는 `const` 생성자를 활용해 불필요한 리빌드를 줄인다.

## 안티패턴·주의점·성능 메모
- `enum`으로 전략을 표현하고 `switch`문으로 분기하면 새 전략 추가 시 분기문이 폭증한다.
- 전략 객체가 상태를 보관하면 재사용 시 부작용이 생기므로 순수 객체로 유지한다.
- Flutter에서는 테마 데이터를 많이 생성할 수 있으니 `const` 생성자를 적극 활용하고, Provider에서 변경된 전략만 감지하게 한다.

## 예상 Q&A
1. 전략 패턴과 상태 패턴의 차이는?
2. 전략 객체 생성을 팩토리로 감싸야 하나?
3. Provider 대신 ChangeNotifier를 써도 되나?
4. 전략 간 공통 설정은 어디서 관리해야 하나?
5. Flutter 테마에서 컬러 충돌을 예방하려면?

> 자세한 답변은 `strategy_qna.md`를 참고하세요.

## 과제와 힌트
1. **문제**: `HighContrastThemeStrategy`에 글꼴 크기 제어 기능을 넣어라. (힌트: `AppTheme`에 `double fontScale` 필드를 추가.)
2. **문제**: 전략 객체를 json으로 직렬화/역직렬화하는 헬퍼를 작성하라. (힌트: `runtimeType` 이름을 키로 사용.)
3. **문제**: 특정 위젯 트리에서만 전략을 바꾸고 싶다. (힌트: `ProviderScope` override를 사용.)

> 모범 답안은 `strategy_assignments.md`에서 확인할 수 있습니다.
