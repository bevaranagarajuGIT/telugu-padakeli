import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/app/navigation/app_shell.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/shared/widgets/bottom_navigation.dart';

void main() {
  test('feature and header text meet 4.5:1 contrast', () {
    final pairs = [
      (AppColors.purple, Colors.white),
      (AppColors.orange, AppColors.ink),
      (AppColors.teal, AppColors.ink),
      (AppColors.pink, AppColors.ink),
      (AppColors.actionBlue, Colors.white),
      (AppColors.deepBlue, Colors.white),
    ];
    for (final pair in pairs) {
      final a = pair.$1.computeLuminance();
      final b = pair.$2.computeLuminance();
      final lighter = a > b ? a : b;
      final darker = a > b ? b : a;
      expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
    }
  });

  test('font presets are normal large and extra large', () {
    expect(TeluguFontSize.values.map((size) => size.scale), [1, 1.2, 1.4]);
    expect(AppSettingsController().fontSize, TeluguFontSize.normal);
  });

  for (final scale in [1.0, 3.2]) {
    testWidgets('navigation fits at width 320 with ${scale}x system text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(1.4),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const AppShell(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('nav-progress')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<BottomNavigation>(find.byType(BottomNavigation))
            .selectedIndex,
        3,
      );
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
