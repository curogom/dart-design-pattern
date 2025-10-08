# Strategy 패턴 과제 모범답안

1. **HighContrast 전략에 글꼴 크기 제어 추가**  
   - `AppTheme`에 `double fontScale` 필드를 추가하고 기본값을 1.0으로 둔다.  
   - `HighContrastThemeStrategy`에서 `fontScale: 1.2`와 같이 더 큰 값을 반환한다.  
   - Flutter 위젯에서는 `MediaQuery.textScaleFactor * theme.fontScale`을 곱해 적용한다.

2. **전략 직렬화/역직렬화 헬퍼**  
   - `Map<String, dynamic>`을 반환하는 `toJson()`을 각 전략이 구현하게 하거나, 전략명(`runtimeType.toString()`)과 속성 값을 매핑한다.  
   - 역직렬화는 전략 이름을 스위치로 매칭하거나 `registry[name]` 패턴을 사용해 클래스를 생성한다.

3. **특정 위젯 트리에서만 전략 교체**  
   - Flutter 위젯 트리에서 `ProviderScope(overrides: [...])`를 사용해 하위 트리에만 다른 전략을 주입한다.  
   - 예: `ProviderScope(overrides: [themeStrategyProvider.overrideWith((_) => const DarkThemeStrategy())], child: WidgetTree())`.
