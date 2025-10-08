import 'package:test/test.dart';
import 'package:week01_patterns/strategy/theme_strategy.dart';

void main() {
  group('ThemeStrategy', () {
    test('Light theme applies expected palette', () {
      const strategy = LightThemeStrategy();
      final theme = strategy.buildTheme();
      expect(theme.name, 'light');
      expect(theme.primaryColor, 0xFFEEEEEE);
      expect(theme.accentColor, 0xFF1565C0);
    });

    test('Context can switch strategy at runtime', () {
      final context = ThemeContext(const LightThemeStrategy());
      expect(context.apply().name, 'light');
      context.changeStrategy(const DarkThemeStrategy());
      expect(context.apply().name, 'dark');
    });
  });
}
