import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'helpers/returning_user_app.dart';
import 'package:telugu_padakeli/screens/kids_game_screen.dart';
import 'package:telugu_padakeli/shared/widgets/home_artwork.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

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

  for (final (width, appScale, systemScale) in [
    (320.0, 1.0, 1.0),
    (390.0, 1.0, 1.0),
    (800.0, 1.0, 1.0),
    (1280.0, 1.0, 1.0),
    (390.0, 1.2, 1.0),
    (320.0, 1.4, 3.2),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'Template B fits $width, app=$appScale, system=$systemScale, dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AppSettingsController(),
              child: MaterialApp(
                theme: dark
                    ? AppTheme.dark(appScale)
                    : AppTheme.light(appScale),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(systemScale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: const KidsGameScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.bySemanticsLabel('స్కోరు: 0'), findsOneWidget);
          expect(find.text('ప్రశ్న 1 / 3'), findsOneWidget);
          expect(find.text('కమ_'), findsOneWidget);
          expect(find.text('నీటిలో పూసే పువ్వు'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final answer = find.byKey(const ValueKey('kids-answer-లం'));
          await tester.ensureVisible(answer);
          await tester.pumpAndSettle();
          expect(tester.getSize(answer).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(answer).width, greaterThanOrEqualTo(48));
          await tester.tap(answer);
          await tester.pumpAndSettle();
          final selected = tester.widget<OutlinedButton>(answer);
          expect(
            selected.style!.backgroundColor!.resolve({}),
            AppColors.purple,
          );
          expect(find.bySemanticsLabel('స్కోరు: 0'), findsOneWidget);
          await tester.ensureVisible(find.text('సరిచూడు'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('సరిచూడు'));
          await tester.pump();
          expect(find.bySemanticsLabel('స్కోరు: 1'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('kids-feedback-success')),
            findsOneWidget,
          );
          final check = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'సరిచూడు'),
          );
          expect(check.onPressed, isNull);
          expect(tester.takeException(), isNull);
          semantics.dispose();
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('learning back action returns Home without discarding progress', (
    tester,
  ) async {
    await tester.pumpWidget(const TeluguPadakeliApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Play & Learn'));
    await tester.tap(find.text('Play & Learn'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('kids-legacy')));
    await tester.tap(find.byKey(const ValueKey('kids-legacy')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('kids-answer-లం')));
    await tester.tap(find.byKey(const ValueKey('kids-answer-లం')));
    await tester.ensureVisible(find.byTooltip('ఆటలకు వెళ్లు'));
    await tester.tap(find.byTooltip('ఆటలకు వెళ్లు'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('హోమ్‌కు వెళ్లు'));
    await tester.tap(find.byTooltip('హోమ్‌కు వెళ్లు'));
    await tester.pumpAndSettle();
    expect(find.text('Classic Padakeli'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-learn')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('kids-legacy')));
    await tester.tap(find.byKey(const ValueKey('kids-legacy')));
    await tester.pumpAndSettle();
    final selected = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('kids-answer-లం')),
    );
    expect(selected.style!.backgroundColor!.resolve({}), AppColors.purple);
    expect(
      find.image(
        ResizeImage.resizeIfNeeded(
          312,
          null,
          const AssetImage(HomeArtwork.learn),
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
