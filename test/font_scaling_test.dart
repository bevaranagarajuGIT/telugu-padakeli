import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/main.dart';
import 'package:telugu_padakeli/screens/home_screen.dart';
import 'package:telugu_padakeli/shared/widgets/feature_card.dart';
import 'package:telugu_padakeli/shared/widgets/home_artwork.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

Map<String, TextStyle?> _roles(TextTheme theme) => {
  'displayLarge': theme.displayLarge,
  'displayMedium': theme.displayMedium,
  'displaySmall': theme.displaySmall,
  'headlineLarge': theme.headlineLarge,
  'headlineMedium': theme.headlineMedium,
  'headlineSmall': theme.headlineSmall,
  'titleLarge': theme.titleLarge,
  'titleMedium': theme.titleMedium,
  'titleSmall': theme.titleSmall,
  'bodyLarge': theme.bodyLarge,
  'bodyMedium': theme.bodyMedium,
  'bodySmall': theme.bodySmall,
  'labelLarge': theme.labelLarge,
  'labelMedium': theme.labelMedium,
  'labelSmall': theme.labelSmall,
};

class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize * (fontSize <= 20 ? 1.5 : 1.3);

  @override
  double get textScaleFactor => 1.5;
}

void main() {
  setUpAll(() async {
    for (final (family, file) in [
      (PremiumTeluguText.fontFamily, 'NotoSansTelugu'),
      ('Roboto', 'Roboto'),
    ]) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$file-$weight.ttf'));
      }
      await loader.load();
    }
  });

  for (final dark in [false, true]) {
    ThemeData theme(double scale) =>
        dark ? AppTheme.dark(scale) : AppTheme.light(scale);

    for (final preset in TeluguFontSize.values) {
      test('all resolved font roles scale for ${preset.name}, dark=$dark', () {
        final normal = theme(1);
        final scaled = theme(preset.scale);
        expect(normal.textTheme.headlineLarge!.fontSize, 32);
        expect(normal.textTheme.bodyLarge!.fontSize, 16);
        for (final (before, after) in [
          (_roles(normal.textTheme), _roles(scaled.textTheme)),
          (_roles(normal.primaryTextTheme), _roles(scaled.primaryTextTheme)),
        ]) {
          for (final role in before.keys) {
            final original = before[role]!;
            final enlarged = after[role]!;
            expect(original.fontSize, isNotNull, reason: role);
            expect(
              enlarged.fontSize,
              closeTo(original.fontSize! * preset.scale, 0.001),
              reason: role,
            );
            expect(enlarged.fontFamily, PremiumTeluguText.fontFamily);
            expect(enlarged.fontFamilyFallback, ['Roboto']);
            expect(enlarged.color, original.color, reason: role);
          }
        }
        final navigation = scaled.navigationBarTheme.labelTextStyle!.resolve(
          {},
        );
        expect(
          navigation!.fontSize,
          closeTo(
            normal.textTheme.labelMedium!.fontSize! * preset.scale,
            0.001,
          ),
        );
        expect(navigation.fontFamily, 'Roboto');
      });
    }

    testWidgets(
      'Settings presets change rendered Home and layout, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const TeluguPadakeliApp());
        await tester.pumpAndSettle();
        if (dark) {
          await tester.tap(find.byTooltip('Settings'));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(SwitchListTile));
          await tester.pumpAndSettle();
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        final title = find.text('తెలుగు పదకేళి');
        final normalHeight = tester.getSize(title).height;

        for (final preset in [
          TeluguFontSize.normal,
          TeluguFontSize.large,
          TeluguFontSize.extraLarge,
          TeluguFontSize.normal,
        ]) {
          await tester.ensureVisible(find.byTooltip('Settings'));
          await tester.tap(find.byTooltip('Settings'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(preset.label));
          await tester.tap(find.text(preset.label));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<RadioGroup<TeluguFontSize>>(
                  find.byType(RadioGroup<TeluguFontSize>),
                )
                .groupValue,
            preset,
          );
          await tester.pageBack();
          await tester.pumpAndSettle();

          final text = tester.widget<Text>(title);
          expect(text.style!.fontSize, closeTo(32 * preset.scale, 0.001));
          expect(
            tester.widget<Text>(find.text('పదకేళి ఆడండి')).style!.fontSize,
            closeTo(22 * preset.scale, 0.001),
          );
          expect(
            Theme.of(tester.element(find.byType(HomeScreen))).brightness,
            dark ? Brightness.dark : Brightness.light,
          );
          final classic = tester.getRect(find.byType(FeatureCard).at(0));
          final learn = tester.getRect(find.byType(FeatureCard).at(1));
          if (preset == TeluguFontSize.normal) {
            expect(tester.getSize(title).height, closeTo(normalHeight, 0.001));
            expect(classic.top, closeTo(learn.top, 0.001));
            expect(classic.height, learn.height);
          } else {
            expect(tester.getSize(title).height, greaterThan(normalHeight));
            expect(learn.top, greaterThanOrEqualTo(classic.bottom));
            expect(classic.width, 350);
          }
          expect(
            find.byType(HomeScenery),
            preset == TeluguFontSize.extraLarge ? findsNothing : findsOneWidget,
          );
          await tester.ensureVisible(find.text('Continue Playing'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('app presets preserve the independent nonlinear system scaler', (
    tester,
  ) async {
    const scaler = _NonlinearTextScaler();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(1.4),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child!,
        ),
        home: HomeScreen(
          onClassic: () {},
          onLearn: () {},
          onProgress: () {},
          onSettings: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(find.text('తెలుగు పదకేళి'));
    expect(title.style!.fontSize, closeTo(44.8, 0.001));
    expect(title.textScaler, same(scaler));
    expect(
      title.textScaler!.scale(title.style!.fontSize!),
      closeTo(58.24, 0.001),
    );
    final subtitle = tester.widget<Text>(find.text('Classic Padakeli'));
    expect(subtitle.style!.fontSize, closeTo(19.6, 0.001));
    expect(subtitle.textScaler, same(scaler));
    expect(
      subtitle.textScaler!.scale(subtitle.style!.fontSize!),
      closeTo(29.4, 0.001),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
