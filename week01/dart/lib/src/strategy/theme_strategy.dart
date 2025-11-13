import 'package:riverpod/riverpod.dart';

// 전략 패턴 소개:
// - 동일한 문제를 해결하는 여러 알고리즘(테마 구성)을 `ThemeStrategy` 인터페이스로 추상화합니다.
// - 클라이언트(`ThemeContext` 및 Riverpod Provider)가 런타임에 전략을 갈아끼우면서 UI를 재사용합니다.
// - 상태(현재 전략)는 Riverpod `Notifier`로 노출해 Flutter 위젯과 쉽게 동기화하고, 순수 객체 모델은
//   패턴 개념 학습에 집중하도록 별도로 유지했습니다.
// Dart/Flutter 적합성:
// - 함수형 스타일과 불변 객체 모델을 살리기 좋고, 의존성 주입보다 가벼운 전략 교체를 제공해 위젯 재빌드 비용을 명확히 제어합니다.
// - 단점은 전략 수가 지나치게 많아지면 선택 UI·DI 구성이 복잡해지고, 상태 추적 지점(Notifier 등)이 늘어난다는 점입니다.
// 대표 사례:
// - UX 커스터마이징(테마, 레이아웃)이나 API 호출 정책(재시도, 캐시 전략)을 화면/플랫폼별로 바꿔야 할 때 유용합니다.

/// 실행 가능한 테마 데이터 모델.
class AppTheme {
  const AppTheme({
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.textStyle,
  });

  final String name;
  final int primaryColor;
  final int accentColor;
  final String textStyle;

  AppTheme copyWith({
    String? name,
    int? primaryColor,
    int? accentColor,
    String? textStyle,
  }) {
    return AppTheme(
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  @override
  String toString() {
    return 'AppTheme($name, primary: $primaryColor, accent: $accentColor, text: $textStyle)';
  }
}

/// 전략 패턴의 전략 인터페이스.
abstract class ThemeStrategy {
  const ThemeStrategy();

  AppTheme buildTheme();

  String describe();

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;
}

class LightThemeStrategy extends ThemeStrategy {
  const LightThemeStrategy();

  @override
  AppTheme buildTheme() {
    return const AppTheme(
      name: 'light',
      primaryColor: 0xFFEEEEEE,
      accentColor: 0xFF1565C0,
      textStyle: 'Roboto-Light',
    );
  }

  @override
  String describe() => '눈부심을 줄이기 위한 밝은 테마';
}

class DarkThemeStrategy extends ThemeStrategy {
  const DarkThemeStrategy();

  @override
  AppTheme buildTheme() {
    return const AppTheme(
      name: 'dark',
      primaryColor: 0xFF121212,
      accentColor: 0xFF90CAF9,
      textStyle: 'Roboto-Bold',
    );
  }

  @override
  String describe() => '콘텐츠 집중을 위한 어두운 테마';
}

class HighContrastThemeStrategy extends ThemeStrategy {
  const HighContrastThemeStrategy();

  @override
  AppTheme buildTheme() {
    return const AppTheme(
      name: 'high_contrast',
      primaryColor: 0xFFFFFFFF,
      accentColor: 0xFF000000,
      textStyle: 'RobotoMono-Bold',
    );
  }

  @override
  String describe() => '접근성을 강조한 고대비 테마';
}

class ThemeContext {
  ThemeContext(this._strategy);

  ThemeStrategy _strategy;

  AppTheme apply() => _strategy.buildTheme();

  void changeStrategy(ThemeStrategy strategy) {
    _strategy = strategy;
  }
}

// 전략 패턴에서 선택된 전략을 Riverpod 상태로 노출해 Flutter UI와 동기화합니다.
class ThemeStrategyNotifier extends Notifier<ThemeStrategy> {
  @override
  ThemeStrategy build() => const LightThemeStrategy();

  void change(ThemeStrategy strategy) {
    if (state == strategy) {
      return;
    }
    state = strategy;
  }
}

final themeStrategyProvider =
    NotifierProvider<ThemeStrategyNotifier, ThemeStrategy>(
  ThemeStrategyNotifier.new,
);

final currentThemeProvider = Provider<AppTheme>(
  (ref) => ref.watch(themeStrategyProvider).buildTheme(),
);

void main() {
  final context = ThemeContext(const LightThemeStrategy());
  final initialTheme = context.apply();
  print('초기 테마: $initialTheme');
  context.changeStrategy(const DarkThemeStrategy());
  final updatedTheme = context.apply();
  print('변경 테마: $updatedTheme');
}
