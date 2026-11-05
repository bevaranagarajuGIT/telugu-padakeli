import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/app/navigation/app_shell.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/main.dart';
import 'package:telugu_padakeli/screens/home_screen.dart';
import 'package:telugu_padakeli/shared/widgets/bottom_navigation.dart';
import 'package:telugu_padakeli/services/kids_question_service.dart';

void main() {
  test('Kids Game provides five levels with three questions each', () {
    final levels = const KidsQuestionService().getLevels();

    expect(levels.map((level) => level.name), [
      'Beginner',
      'Easy',
      'Medium',
      'Hard',
      'Expert',
    ]);
    expect(levels.every((level) => level.questions.length == 3), isTrue);
  });

  testWidgets('home screen shows primary actions', (tester) async {
    await tester.pumpWidget(const TeluguPadakeliApp());

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
    await tester.pumpWidget(const TeluguPadakeliApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Play & Learn'));
    await tester.tap(find.text('Play & Learn'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('kids-answer-ల')));
    await tester.tap(find.text('Check'));
    await tester.pump();
    expect(find.text('స్కోరు: 1'), findsOneWidget);
    expect(find.text('సరైంది! మీ స్కోరు పెరిగింది.'), findsOneWidget);
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
    expect(find.text('అ_ము'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-న')));
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('తప్పు సమాధానం. మళ్ళీ ప్రయత్నించండి.'), findsOneWidget);
    expect(find.byKey(const ValueKey('kids-feedback-error')), findsOneWidget);
    expect(find.text('స్కోరు: 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-మ')));
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('పా_శాల'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-ఠ')));
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('స్థాయి 2 · Easy'), findsOneWidget);
    expect(find.text('సులభ స్థాయి'), findsOneWidget);
    expect(find.text('ఆ_ు'), findsOneWidget);
  });

  testWidgets('wrong answers allow retries and next question earns a point', (
    tester,
  ) async {
    await tester.pumpWidget(const TeluguPadakeliApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Play & Learn'));
    await tester.tap(find.text('Play & Learn'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('స్కోరు: 0'), findsOneWidget);
    expect(find.text('ఒక అక్షరం ఎంచుకోండి.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-ప')));
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('స్కోరు: 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('kids-feedback-error')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-answer-ల')));
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('స్కోరు: 1'), findsOneWidget);
    expect(find.text('అ_ము'), findsOneWidget);
    expect(find.text('సరైంది! మీ స్కోరు పెరిగింది.'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('kids-answer-మ')));
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('పా_శాల'), findsOneWidget);
    expect(find.text('స్కోరు: 2'), findsOneWidget);
  });

  testWidgets('progress card opens an honest coming-soon screen', (
    tester,
  ) async {
    await tester.pumpWidget(const TeluguPadakeliApp());
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

  testWidgets('settings action opens font and dark-mode controls', (
    tester,
  ) async {
    await tester.pumpWidget(const TeluguPadakeliApp());
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
    await tester.pumpWidget(const TeluguPadakeliApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Classic Padakeli'));
    await tester.tap(find.text('Classic Padakeli'));
    await tester.pumpAndSettle();
    expect(find.text('స్థాయిని ఎంచుకోండి'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('difficulty-Beginner')));
    await tester.pumpAndSettle();
    for (final number in ['1', '2', '3', '4', '5']) {
      expect(find.text(number, skipOffstage: false), findsOneWidget);
    }
    expect(find.text('అడ్డం (Across →)'), findsOneWidget);
    expect(find.text('నిలువు (Down ↓)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('crossword-cell-0')));
    await tester.ensureVisible(find.byKey(const ValueKey('akshara-క')));
    await tester.tap(find.byKey(const ValueKey('akshara-క')));

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resume Classic'));
    await tester.tap(find.text('Resume Classic'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
          .data,
      'క',
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
    await tester.pumpWidget(const TeluguPadakeliApp());
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
    await tester.pumpWidget(const TeluguPadakeliApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Daily Puzzle'));
    await tester.tap(find.text('Daily Puzzle'));
    await tester.pump();
    expect(find.text('Daily Puzzle త్వరలో వస్తుంది'), findsOneWidget);
  });
}
