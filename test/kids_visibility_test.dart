import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/models/kids_learning.dart';
import 'package:telugu_padakeli/screens/kids_activity_screen.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

const _activity = KidsLearningActivity(
  id: 'visibility-activity',
  type: KidsActivityType.completion,
  categories: {LearningCategory.early},
  title: 'పదాన్ని పూర్తి చేయి',
  englishTitle: 'Complete the word',
  questions: [
    KidsLearningQuestion(
      id: 'visibility-one',
      prompt: 'తప్పిన అక్షరాన్ని ఎంచుకోండి',
      englishPrompt: 'Choose the missing letter.',
      answer: 'లం',
      display: 'కమ_',
      completedWord: 'కమలం',
      choices: [KidsChoice('లం'), KidsChoice('రం'), KidsChoice('పం')],
      explanation: 'నీటిలో పూసే పువ్వు',
      englishExplanation: 'A flower that blooms in water.',
    ),
    KidsLearningQuestion(
      id: 'visibility-two',
      prompt: 'తప్పిన అక్షరాన్ని ఎంచుకోండి',
      englishPrompt: 'Choose the missing letter.',
      answer: 'మ్మ',
      display: 'అ_',
      completedWord: 'అమ్మ',
      choices: [KidsChoice('మ్మ'), KidsChoice('న్న'), KidsChoice('క్క')],
      explanation: 'తల్లి అనే అర్థం వచ్చే పదం',
      englishExplanation: 'Another word for mother.',
    ),
  ],
);

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

  for (final width in [320.0, 390.0]) {
    for (final height in [480.0, 568.0]) {
      for (final scale in [1.0, 1.4]) {
        for (final dark in [false, true]) {
          for (final reduced in [false, true]) {
            testWidgets('visible footer and completion $width x $height '
                'app=$scale dark=$dark reduced=$reduced English on', (
              tester,
            ) async {
              tester.view.physicalSize = Size(width, height);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final settings = AppSettingsController()..setEnglishHelper(true);
              final learning = KidsLearningController();
              final session = learning.sessionFor(_activity);
              addTearDown(settings.dispose);
              addTearDown(learning.dispose);
              var advanced = 0;
              await tester.pumpWidget(
                ChangeNotifierProvider.value(
                  value: settings,
                  child: MaterialApp(
                    theme: dark ? AppTheme.dark(scale) : AppTheme.light(scale),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        disableAnimations: reduced,
                        padding: const EdgeInsets.only(top: 28, bottom: 24),
                      ),
                      child: child!,
                    ),
                    home: KidsActivityScreen(
                      session: session,
                      learning: learning,
                      onNext: () => advanced++,
                    ),
                  ),
                ),
              );
              for (var index = 0; index < _activity.questions.length; index++) {
                final answer = find.byKey(
                  ValueKey('learning-choice-${session.question.answer}'),
                );
                await Scrollable.ensureVisible(
                  tester.element(answer),
                  alignment: 0.5,
                );
                await tester.pumpAndSettle();
                await tester.tap(answer);
                await tester.pumpAndSettle();
                final check = find.byKey(const ValueKey('learning-check'));
                await Scrollable.ensureVisible(
                  tester.element(check),
                  alignment: 0.5,
                );
                await tester.pumpAndSettle();
                await tester.tap(check);
                await tester.pumpAndSettle();
                expect(session.answerState, KidsAnswerState.correct);
                final next = find.byKey(const ValueKey('learning-next'));
                final footer = tester.getRect(
                  find.byKey(const ValueKey('learning-action-footer')),
                );
                final nextRect = tester.getRect(next);
                expect(next.hitTestable(), findsOneWidget);
                expect(nextRect.top, greaterThanOrEqualTo(footer.top));
                expect(nextRect.bottom, lessThanOrEqualTo(height - 24));
                expect(nextRect.height, greaterThanOrEqualTo(48));
                final content = tester.getRect(
                  find.byKey(const ValueKey('kids-activity-scroll')),
                );
                expect(content.bottom, lessThanOrEqualTo(footer.top + 0.01));
                final feedback = find.byKey(const ValueKey('learning-correct'));
                await Scrollable.ensureVisible(
                  tester.element(feedback),
                  alignment: 1,
                );
                await tester.pumpAndSettle();
                expect(
                  tester.getRect(feedback).bottom,
                  lessThanOrEqualTo(footer.top + 0.01),
                );
                await Scrollable.ensureVisible(
                  tester.element(answer),
                  alignment: 1,
                );
                await tester.pumpAndSettle();
                expect(
                  tester.getRect(answer).bottom,
                  lessThanOrEqualTo(footer.top + 0.01),
                );
                await tester.drag(
                  find.byKey(const ValueKey('kids-activity-scroll')),
                  const Offset(0, -180),
                );
                await tester.pumpAndSettle();
                await tester.tap(
                  next,
                ); // No scrolling to find the continuation.
                await tester.pumpAndSettle();
              }
              final heading = find.byKey(
                const ValueKey('learning-completion-heading'),
              );
              final character = find.byKey(
                const ValueKey('bal-hanuman-character'),
              );
              final viewport = tester.getRect(
                find.byKey(const ValueKey('kids-activity-completion-scroll')),
              );
              expect(
                tester.getRect(heading).top,
                greaterThanOrEqualTo(viewport.top),
              );
              expect(
                tester.getRect(heading).bottom,
                lessThanOrEqualTo(viewport.bottom),
              );
              expect(
                tester.getRect(character).top,
                greaterThanOrEqualTo(viewport.top),
              );
              expect(
                tester.getRect(character).bottom,
                lessThanOrEqualTo(viewport.bottom),
              );
              expect(Focus.of(tester.element(heading)).hasFocus, isTrue);
              expect(
                find
                    .byKey(const ValueKey('learning-next-activity'))
                    .hitTestable(),
                findsOneWidget,
              );
              final replay = find.byKey(const ValueKey('learning-restart'));
              await Scrollable.ensureVisible(
                tester.element(replay),
                alignment: 0.5,
              );
              await tester.pumpAndSettle();
              expect(replay.hitTestable(), findsOneWidget);
              final back = find.byKey(const ValueKey('learning-return'));
              await Scrollable.ensureVisible(
                tester.element(back),
                alignment: 0.5,
              );
              await tester.pumpAndSettle();
              expect(back.hitTestable(), findsOneWidget);
              await tester.tap(
                find.byKey(const ValueKey('learning-next-activity')),
              );
              expect(advanced, 1);
              expect(learning.stars, 1);
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            });
          }
        }
      }
    }
  }
}
