import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'helpers/returning_user_app.dart';
import 'package:telugu_padakeli/screens/kids_game_screen.dart';
import 'package:telugu_padakeli/services/kids_question_service.dart';
import 'package:telugu_padakeli/shared/widgets/home_artwork.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';
import 'package:telugu_padakeli/widgets/engagement_motion.dart';

void expectFeedbackVisible(WidgetTester tester, String key) {
  final viewport = tester.getRect(find.byKey(const ValueKey('kids-scroll')));
  final feedback = tester.getRect(find.byKey(ValueKey(key)));
  expect(feedback.top, greaterThanOrEqualTo(viewport.top - 0.01));
  expect(feedback.bottom, lessThanOrEqualTo(viewport.bottom + 0.01));
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

  for (final (size, appScale, systemScale) in [
    (const Size(320, 568), 1.0, 1.0),
    (const Size(390, 844), 1.0, 1.0),
    (const Size(411, 914), 1.0, 1.0),
    (const Size(390, 844), 1.2, 1.5),
  ]) {
    for (final dark in [false, true]) {
      for (final reducedMotion in [false, true]) {
        testWidgets(
          'Check answer reveals feedback at $size, app=$appScale, system=$systemScale, dark=$dark, reduced=$reducedMotion',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create: (_) => AppSettingsController()..setEnglishHelper(true),
                child: MaterialApp(
                  theme: dark
                      ? AppTheme.dark(appScale)
                      : AppTheme.light(appScale),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      viewPadding: const EdgeInsets.symmetric(vertical: 24),
                      textScaler: TextScaler.linear(systemScale),
                      disableAnimations: reducedMotion,
                    ),
                    child: child!,
                  ),
                  home: const Scaffold(
                    body: KidsGameScreen(),
                    bottomNavigationBar: SizedBox(height: 80),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final check = find.byKey(const ValueKey('kids-check-answer'));

            Future<void> checkAnswer() async {
              await tester.ensureVisible(check);
              await tester.pumpAndSettle();
              await tester.tap(check);
              await tester.pump();
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 250));
            }

            await checkAnswer();
            expectFeedbackVisible(tester, 'kids-feedback-neutral');
            expect(
              tester
                  .widget<AnswerStarBurst>(find.byType(AnswerStarBurst))
                  .animate,
              isFalse,
            );
            final question = const KidsQuestionService()
                .getLevels()
                .first
                .questions
                .first;
            final wrong = find.byKey(
              ValueKey(
                'kids-answer-${question.options.firstWhere((option) => option != question.answer)}',
              ),
            );
            await tester.ensureVisible(wrong);
            await tester.pumpAndSettle();
            await tester.tap(wrong);
            await checkAnswer();
            expectFeedbackVisible(tester, 'kids-feedback-error');
            expect(
              tester
                  .widget<AnswerStarBurst>(find.byType(AnswerStarBurst))
                  .animate,
              isFalse,
            );
            final correct = find.byKey(
              ValueKey('kids-answer-${question.answer}'),
            );
            await tester.ensureVisible(correct);
            await tester.pumpAndSettle();
            await tester.tap(correct);
            await checkAnswer();
            expectFeedbackVisible(tester, 'kids-feedback-success');
            expect(
              tester
                  .widget<AnswerStarBurst>(find.byType(AnswerStarBurst))
                  .animate,
              isTrue,
            );
            expect(find.text(question.prompt), findsOneWidget);
            expect(tester.widget<FilledButton>(check).onPressed, isNull);
            await tester.pump(const Duration(milliseconds: 750));
            expectFeedbackVisible(tester, 'kids-feedback-success');
            await tester.pump(const Duration(milliseconds: 200));
            await tester.pumpAndSettle();
            expect(find.text('ప్రశ్న 2 / 5'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }

  for (final size in [const Size(390, 844), const Size(411, 914)]) {
    for (final dark in [false, true]) {
      testWidgets(
        'all practice questions fit above navigation at $size, dark=$dark',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final settings = AppSettingsController()..setEnglishHelper(true);
          addTearDown(settings.dispose);
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: settings,
              child: MaterialApp(
                theme: dark ? AppTheme.dark(1) : AppTheme.light(1),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    viewPadding: const EdgeInsets.symmetric(vertical: 24),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: const Scaffold(
                  body: KidsGameScreen(),
                  bottomNavigationBar: SizedBox(height: 80),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final levels = const KidsQuestionService().getLevels();
          final scroll = find.byKey(const ValueKey('kids-scroll'));
          final check = find.byKey(const ValueKey('kids-check-answer'));
          for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
            final level = levels[levelIndex];
            for (final question in level.questions) {
              final label = '${level.name}: ${question.prompt}';
              final position = tester
                  .state<ScrollableState>(
                    find.descendant(
                      of: scroll,
                      matching: find.byType(Scrollable),
                    ),
                  )
                  .position;
              expect(position.pixels, 0, reason: label);
              expect(position.maxScrollExtent, 0, reason: label);
              expect(
                find.text('స్థాయి ${levelIndex + 1} / ${levels.length}'),
                findsOneWidget,
                reason: label,
              );
              expect(find.text(level.title), findsOneWidget, reason: label);
              final status = tester.getRect(
                find.byKey(ValueKey('kids-level-status-$levelIndex')),
              );
              final questionPanel = tester.getRect(
                find.byKey(const ValueKey('kids-question-panel')),
              );
              final hint = tester.getRect(
                find.byKey(const ValueKey('kids-question-hint')),
              );
              expect(
                questionPanel.top - status.bottom,
                closeTo(size.height >= 900 ? 20 : 12, 0.01),
                reason: label,
              );
              expect(
                hint.top - questionPanel.bottom,
                closeTo(size.height >= 900 ? 16 : 8, 0.01),
                reason: label,
              );
              final viewport = tester.getRect(scroll);
              for (final control in [
                find.byKey(ValueKey('kids-level-status-$levelIndex')),
                find.byKey(const ValueKey('kids-question-panel')),
                for (final option in question.options)
                  find.byKey(ValueKey('kids-answer-$option')),
                check,
              ]) {
                final rect = tester.getRect(control);
                expect(
                  rect.top,
                  greaterThanOrEqualTo(viewport.top),
                  reason: label,
                );
                expect(
                  rect.bottom,
                  lessThanOrEqualTo(viewport.bottom),
                  reason: label,
                );
              }
              for (final option in question.options) {
                final answer = find.byKey(ValueKey('kids-answer-$option'));
                expect(
                  tester.getSize(answer).shortestSide,
                  greaterThanOrEqualTo(48),
                );
              }
              expect(tester.getSize(check).height, greaterThanOrEqualTo(48));
              expect(find.text(question.englishHint), findsOneWidget);
              await tester.tap(
                find.byKey(ValueKey('kids-answer-${question.answer}')),
              );
              await tester.pump();
              await tester.tap(check);
              await tester.pump();
              expectFeedbackVisible(tester, 'kids-feedback-success');
              await tester.pump(const Duration(milliseconds: 1200));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: label);
            }
            if (levelIndex + 1 < levels.length) {
              await tester.tap(find.byKey(const ValueKey('legacy-next-level')));
              await tester.pumpAndSettle();
            }
          }
          expect(
            find.byKey(const ValueKey('legacy-completion-restart')),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final (width, height, appScale, systemScale) in [
    (320.0, 568.0, 1.0, 1.0),
    (844.0, 390.0, 1.0, 1.0),
    (320.0, 844.0, 1.0, 1.0),
    (390.0, 844.0, 1.0, 1.0),
    (800.0, 844.0, 1.0, 1.0),
    (1280.0, 844.0, 1.0, 1.0),
    (390.0, 844.0, 1.2, 1.0),
    (320.0, 844.0, 1.4, 3.2),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'practice remains usable at $width x $height, app=$appScale, system=$systemScale, dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AppSettingsController()..setEnglishHelper(true),
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
          expect(find.text('ప్రశ్న 1 / 5'), findsOneWidget);
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

  testWidgets(
    'original practice English hints follow Helper without replacing Telugu',
    (tester) async {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: const MaterialApp(home: KidsGameScreen()),
        ),
      );
      const english = 'A flower that blooms in water.';
      expect(find.text('Check answer'), findsOneWidget);
      expect(find.text(english), findsNothing);
      settings.setEnglishHelper(true);
      await tester.pumpAndSettle();
      expect(find.text(english), findsOneWidget);
      expect(find.text('నీటిలో పూసే పువ్వు'), findsOneWidget);
      settings.setEnglishHelper(false);
      await tester.pumpAndSettle();
      expect(find.text(english), findsNothing);
      expect(find.text('Check answer'), findsOneWidget);
      expect(find.text('నీటిలో పూసే పువ్వు'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('learning back action returns Home without discarding progress', (
    tester,
  ) async {
    await pumpReturningUserApp(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Play & Learn'));
    await tester.tap(find.text('Play & Learn'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('kids-legacy')));
    await tester.tap(find.byKey(const ValueKey('kids-legacy')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('kids-answer-లం')));
    await tester.tap(find.byKey(const ValueKey('kids-answer-లం')));
    await tester.ensureVisible(
      find.byTooltip('ఆటలకు వెళ్లు / Return to activities'),
    );
    await tester.tap(find.byTooltip('ఆటలకు వెళ్లు / Return to activities'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('హోమ్‌కు వెళ్లు / Back to Home'));
    await tester.tap(find.byTooltip('హోమ్‌కు వెళ్లు / Back to Home'));
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
