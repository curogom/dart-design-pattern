import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week01_patterns/strategy/theme_strategy.dart';

// 전략 패턴 데모 페이지:
// - SegmentedButton으로 선택한 전략을 Riverpod Notifier에 전달해 런타임 테마 교체를 시각화합니다.
// - Flutter에서 테마를 전략으로 분리하면 플랫폼 전용 스타일(예: 다크 모드, 접근성 강조)을 쉽게 추가·테스트할 수 있습니다.
// - 대표 사례: 브랜드별 커스터마이징, A/B 테스트용 테마 전환, 사용자 선호에 따른 런타임 스타일 적용.

class ThemeSwitcherPage extends ConsumerWidget {
  const ThemeSwitcherPage({super.key});

  ThemeData _buildTheme(AppTheme theme) {
    return ThemeData(
      useMaterial3: true,
      primaryColor: Color(theme.primaryColor),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(theme.accentColor),
        brightness:
            theme.name == 'dark' ? Brightness.dark : Brightness.light,
      ),
      textTheme: ThemeData(useMaterial3: true).textTheme.apply(
            fontFamily: theme.textStyle,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final strategy = ref.watch(themeStrategyProvider);

    // SegmentedButton과 전략 Provider를 직결해 전략 변경 → 테마 빌드 → 프리뷰까지의 흐름을 학습합니다.
    return Theme(
      data: _buildTheme(theme),
      child: Scaffold(
        appBar: AppBar(
          title: Text('전략 패턴 · ${theme.name}'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strategy.describe(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              SegmentedButton<ThemeStrategy>(
                segments: const [
                  ButtonSegment(
                    value: LightThemeStrategy(),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: DarkThemeStrategy(),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: HighContrastThemeStrategy(),
                    label: Text('High Contrast'),
                  ),
                ],
                selected: {strategy},
                onSelectionChanged: (selection) {
                  ref
                      .read(themeStrategyProvider.notifier)
                      .change(selection.first);
                },
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '프리뷰',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Primary: 0x${theme.primaryColor.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                      ),
                      Text(
                        'Accent: 0x${theme.accentColor.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                      ),
                      Text('Font: ${theme.textStyle}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
