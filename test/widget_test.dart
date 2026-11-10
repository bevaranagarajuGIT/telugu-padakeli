import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/app/navigation/app_shell.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'helpers/returning_user_app.dart';
import 'package:telugu_padakeli/screens/home_screen.dart';
import 'package:telugu_padakeli/shared/widgets/app_buttons.dart';
import 'package:telugu_padakeli/shared/widgets/bottom_navigation.dart';
import 'package:telugu_padakeli/shared/widgets/feature_card.dart';
import 'package:telugu_padakeli/services/kids_question_service.dart';

Finder _score(int value) => find.descendant(
  of: find.byKey(const ValueKey('kids-score')),
  matching: find.text('$value'),
);

void main() {
  test('Kids Game provides seven progressively sized levels', () {
    final levels = const KidsQuestionService().getLevels();

    expect(levels.map((level) => level.name), [
      'Beginner',
      'Easy',
      'Medium',
      'Hard',
      'Expert',
      'Master',
      'Champion',
    ]);
    expect(levels.map((level) => level.questions.length), [
      5,
      5,
      7,
      7,
      10,
      10,
      10,
    ]);
  });

  testWidgets('home screen shows primary actions', (tester) async {
    await pumpReturningUserApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Telugu Padakeli'), findsOneWidget);
    expect(find.text('తెలుగు పదకేళి'), findsOneWidget);
    expect(find.text('Classic Padakeli'), findsOneWidget);
    expect(find.text('Play & Learn'), findsOneWidget);
    expect(find.text('Daily Puzzle'), findsOneWidget);
    expect(find.text('My Progress'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('correct answer shows feedback, advances, and unlocks easy', (
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

    expect(find.byKey(const ValueKey('kids-level-status-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('kids-question-panel')), findsOneWidget);
    expect(find.text('ప్రశ్న 1 / 5'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('kids-answer-లం')));
    await tester.tap(find.text('సరిచూడు'));
    await tester.pump();
    expect(_score(1), findsOneWidget);
    expect(find.text('శభాష్! సరైన సమాధానం.'), findsOneWidget);
    expect(find.byKey(const ValueKey('kids-feedback-success')), findsOneWidget);
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey('kids-feedback-success')),
                  )
                  .decoration!
              as BoxDecoration)
          .color,
      AppColors.teal,
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('అ_'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-న్న')));
    await tester.tap(find.text('సరిచూడు'));
    await tester.pumpAndSettle();
    expect(find.text('మళ్లీ ప్రయత్నించు! నువ్వు చేయగలవు.'), findsOneWidget);
    expect(find.byKey(const ValueKey('kids-feedback-error')), findsOneWidget);
    expect(_score(1), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-మ్మ')));
    await tester.tap(find.text('సరిచూడు'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('పా_శాల'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-ఠ')));
    await tester.tap(find.text('సరిచూడు'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    for (final question
        in const KidsQuestionService().getLevels().first.questions.skip(3)) {
      await tester.tap(find.byKey(ValueKey('kids-answer-${question.answer}')));
      await tester.tap(find.text('సరిచూడు'));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
    }
    expect(find.text('స్థాయి 2 · సులభ స్థాయి'), findsOneWidget);
    expect(find.text('సులభ స్థాయి'), findsOneWidget);
    expect(find.text('ఆ_'), findsOneWidget);
  });

  testWidgets('wrong answers allow retries and next question earns a point', (
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

    await tester.tap(find.text('సరిచూడు'));
    await tester.pumpAndSettle();
    expect(_score(0), findsOneWidget);
    expect(find.text('ఒక అక్షరం ఎంచుకోండి.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-పం')));
    await tester.tap(find.text('సరిచూడు'));
    await tester.pumpAndSettle();
    expect(_score(0), findsOneWidget);
    expect(find.byKey(const ValueKey('kids-feedback-error')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-లం')));
    await tester.tap(find.text('సరిచూడు'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(_score(1), findsOneWidget);
    expect(find.text('అ_'), findsOneWidget);
    expect(find.text('సరైంది! మీ స్కోరు పెరిగింది.'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('kids-answer-మ్మ')));
    await tester.tap(find.text('సరిచూడు'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('పా_శాల'), findsOneWidget);
    expect(_score(2), findsOneWidget);
  });

  testWidgets('progress card opens an honest coming-soon screen', (
    tester,
  ) async {
    await pumpReturningUserApp(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My Progress'));
    await tester.tap(find.text('My Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Progress tracking is coming soon.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('Classic Padakeli'), findsOneWidget);
  });

  testWidgets('dashboard respects reduced-motion accessibility setting', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
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

    final entrance = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('dashboard-entrance')),
    );
    expect(entrance.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active puzzle resume appears before the playable cards', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onClassic: () => opened = true,
          onLearn: () {},
          onProgress: () {},
          onSettings: () {},
          hasActivePuzzle: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Resume Classic')).bottom,
      lessThan(tester.getRect(find.byType(FeatureCard).first).top),
    );
    await tester.tap(find.text('Resume Classic'));
    expect(opened, isTrue);
  });

  testWidgets('playable feature cards have matching heights', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onClassic: () {},
          onLearn: () {},
          onProgress: () {},
          onSettings: () {},
        ),
      ),
    );

    final heights = [
      for (var index = 0; index < 2; index++)
        tester.getSize(find.byType(FeatureCard).at(index)).height,
    ];
    expect(heights[0], heights[1]);
    expect(find.byType(FeatureCard), findsNWidgets(2));
  });

  testWidgets('coming-soon status is included in feature-card semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
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
    final semantics = tester.ensureSemantics();
    await tester.pump();

    expect(
      find.bySemanticsLabel('నేటి పదకేళి, Daily Puzzle, Coming Soon'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('నా పురోగతి, My Progress, Coming Soon'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('dimensional button exposes button semantics and keyboard keys', (
    tester,
  ) async {
    var activations = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PrimaryButton(
              label: 'Start Classic',
              onPressed: () => activations++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = tester.getSemantics(find.bySemanticsLabel('Start Classic'));
    final buttonData = button.getSemanticsData();
    expect(buttonData.flagsCollection.isButton, isTrue);
    expect(buttonData.hasAction(SemanticsAction.tap), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(activations, 2);
    semantics.dispose();
  });

  testWidgets('feature cards grow and remain scrollable at large text sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
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

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings action opens font and dark-mode controls', (
    tester,
  ) async {
    await pumpReturningUserApp(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('అక్షర పరిమాణం'), findsOneWidget);
    expect(find.text('డార్క్ మోడ్'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Classic Padakeli'), findsOneWidget);
  });

  testWidgets('classic puzzle input survives tab navigation and resume', (
    tester,
  ) async {
    await pumpReturningUserApp(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Classic Padakeli'));
    await tester.tap(find.text('Classic Padakeli'));
    await tester.pumpAndSettle();
    expect(find.text('స్థాయిని ఎంచుకోండి'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('difficulty-Beginner')));
    await tester.pumpAndSettle();
    for (final number in ['1', '2']) {
      expect(find.text(number, skipOffstage: false), findsOneWidget);
    }
    expect(find.text('అడ్డం (Across)'), findsOneWidget);
    expect(find.text('నిలువు (Down)'), findsOneWidget);
    expect(find.byKey(const ValueKey('clue-across-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('clue-across-2')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('crossword-cell-0')));
    await tester.ensureVisible(find.byKey(const ValueKey('akshara-ఆ')));
    await tester.tap(find.byKey(const ValueKey('akshara-ఆ')));

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resume Classic'));
    await tester.tap(find.text('Resume Classic'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
          .data,
      'ఆ',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BottomNavigation>(find.byType(BottomNavigation))
          .selectedIndex,
      0,
    );
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('font selector exposes normal large and extra-large sizes', (
    tester,
  ) async {
    await pumpReturningUserApp(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    for (final size in TeluguFontSize.values) {
      await tester.ensureVisible(find.text(size.label));
      await tester.tap(find.text(size.label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(RadioListTile<TeluguFontSize>), findsNWidgets(3));
  });

  testWidgets('home daily action is explicitly coming soon', (tester) async {
    await pumpReturningUserApp(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Daily Puzzle'));
    await tester.tap(find.text('Daily Puzzle'));
    await tester.pump();
    expect(find.text('Daily Puzzle త్వరలో వస్తుంది'), findsOneWidget);
  });
}
