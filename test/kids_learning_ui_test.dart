import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/models/kids_learning.dart';
import 'package:telugu_padakeli/models/telugu_akshara.dart';
import 'package:telugu_padakeli/screens/kids_activity_screen.dart';
import 'package:telugu_padakeli/screens/kids_learning_screen.dart';
import 'package:telugu_padakeli/screens/settings_screen.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';
import 'helpers/returning_user_app.dart';

Widget _host(
  Widget screen,
  AppSettingsController settings, {
  bool dark = false,
  double systemScale = 1,
  double appScale = 1,
}) => ChangeNotifierProvider.value(
  value: settings,
  child: MaterialApp(
    theme: dark ? AppTheme.dark(appScale) : AppTheme.light(appScale),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(systemScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: screen,
  ),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _completeSession(KidsActivitySession session) {
  for (final question in session.activity.questions) {
    if (session.activity.type == KidsActivityType.builder) {
      final unused = List.generate(question.tiles.length, (i) => i);
      for (final akshara in TeluguAkshara.split(question.answer)) {
        final index = unused.firstWhere((i) => question.tiles[i] == akshara);
        unused.remove(index);
        session.selectTile(index);
      }
    } else {
      session.selectChoice(question.answer);
    }
    session.check();
    session.next();
  }
}

void main() {
  final activities = const KidsLearningService().getActivities();
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

  testWidgets('activity cards expose button actions, not progress-bar roles', (
    tester,
  ) async {
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(KidsLearningScreen(onBack: () {}), settings));
    await tester.pumpAndSettle();
    final activity = find.byKey(const ValueKey('kids-activity-pictures'));
    await Scrollable.ensureVisible(tester.element(activity));
    await tester.pumpAndSettle();
    final data = tester.getSemantics(activity).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.label, contains('0 / 5'));
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final dark in [false, true]) {
    testWidgets('next stays reachable on a small phone, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()..setEnglishHelper(true);
      final learning = KidsLearningController();
      addTearDown(settings.dispose);
      addTearDown(learning.dispose);
      final session = learning.sessionFor(
        activities.firstWhere(
          (activity) => activity.type == KidsActivityType.letter,
        ),
      );
      await tester.pumpWidget(
        _host(
          KidsActivityScreen(session: session, learning: learning),
          settings,
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      session.selectChoice(session.question.answer);
      expect(session.check(), isTrue);
      await tester.pumpAndSettle();
      final next = find.byKey(const ValueKey('learning-next'));
      expect(next.hitTestable(), findsOneWidget);
      final viewport = tester.getRect(
        find.byKey(const ValueKey('kids-activity-scroll')),
      );
      final button = tester.getRect(next);
      expect(button.top, greaterThanOrEqualTo(viewport.bottom));
      expect(button.bottom, lessThanOrEqualTo(640));
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(session.index, 1);
      expect(
        tester
            .state<ScrollableState>(
              find.descendant(
                of: find.byKey(const ValueKey('kids-activity-scroll')),
                matching: find.byType(Scrollable),
              ),
            )
            .position
            .pixels,
        0,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('kids welcome leaves room for the activities', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    await tester.pumpWidget(_host(KidsLearningScreen(onBack: () {}), settings));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('kids-welcome-panel'))).height,
      lessThan(200),
    );
    expect(
      find.byKey(const ValueKey('kids-activity-pictures')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'age selection shows only corresponding activities and preserves Telugu',
    (tester) async {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        _host(KidsLearningScreen(onBack: () {}), settings),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('kids-activity-pictures')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kids-activity-meanings')),
        findsNothing,
      );
      expect(find.text('Picture matching'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('kids-category-explorers')));
      expect(
        find.byKey(const ValueKey('kids-activity-completion-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kids-activity-builder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kids-activity-pictures')),
        findsNothing,
      );
      await _tap(tester, find.byKey(const ValueKey('kids-category-champions')));
      expect(
        find.byKey(const ValueKey('kids-activity-meanings')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kids-activity-completion-2')),
        findsOneWidget,
      );
      settings.setEnglishHelper(true);
      await tester.pumpAndSettle();
      expect(find.text('Meaning match'), findsOneWidget);
      expect(find.text('అర్థాన్ని గుర్తించు'), findsOneWidget);
      settings.setEnglishHelper(false);
      await tester.pumpAndSettle();
      expect(find.text('Meaning match'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'vibrant quiz keeps clear answer states and contrast dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = AppSettingsController()..setEnglishHelper(true);
        final session = KidsActivitySession(
          activities.firstWhere(
            (activity) => activity.type == KidsActivityType.picture,
          ),
          () {},
        );
        addTearDown(settings.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          _host(KidsActivityScreen(session: session), settings, dark: dark),
        );
        await tester.pumpAndSettle();
        final scheme = Theme.of(
          tester.element(find.byType(KidsActivityScreen)),
        ).colorScheme;
        for (final key in [
          'learning-progress-panel',
          'learning-question-panel',
        ]) {
          final decoration =
              tester.widget<Container>(find.byKey(ValueKey(key))).decoration!
                  as BoxDecoration;
          expect(decoration.color, isNot(scheme.surface));
        }
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .minHeight,
          8,
        );

        void expectChoiceContrast(KidsChoice choice) {
          final button = tester.widget<OutlinedButton>(
            find.byKey(ValueKey('learning-choice-${choice.telugu}')),
          );
          for (final states in [
            <WidgetState>{},
            {WidgetState.disabled},
          ]) {
            final colors = [
              button.style!.foregroundColor!.resolve(states)!,
              button.style!.backgroundColor!.resolve(states)!,
            ];
            final luminances =
                colors.map((color) => color.computeLuminance()).toList()
                  ..sort();
            expect(
              (luminances.last + 0.05) / (luminances.first + 0.05),
              greaterThanOrEqualTo(4.5),
            );
          }
        }

        for (final choice in session.question.choices) {
          expectChoiceContrast(choice);
          final button = find.byKey(
            ValueKey('learning-choice-${choice.telugu}'),
          );
          expect(tester.getSize(button).height, greaterThanOrEqualTo(64));
          expect(tester.getRect(button).bottom, lessThanOrEqualTo(844));
          expect(
            tester
                .widget<Icon>(
                  find.byKey(
                    ValueKey('learning-choice-status-${choice.telugu}'),
                  ),
                )
                .icon,
            Icons.circle_outlined,
          );
        }
        final wrong = session.question.choices.firstWhere(
          (choice) => choice.telugu != session.question.answer,
        );
        await _tap(
          tester,
          find.byKey(ValueKey('learning-choice-${wrong.telugu}')),
        );
        expect(find.byKey(const ValueKey('learning-retry')), findsOneWidget);
        expect(
          tester
              .widget<Icon>(
                find.byKey(ValueKey('learning-choice-status-${wrong.telugu}')),
              )
              .icon,
          Icons.refresh_rounded,
        );
        expectChoiceContrast(wrong);
        final answer = session.question.choices.firstWhere(
          (choice) => choice.telugu == session.question.answer,
        );
        await _tap(
          tester,
          find.byKey(ValueKey('learning-choice-${answer.telugu}')),
        );
        expect(find.byKey(const ValueKey('learning-correct')), findsOneWidget);
        expect(
          tester
              .widget<Icon>(
                find.byKey(ValueKey('learning-choice-status-${answer.telugu}')),
              )
              .icon,
          Icons.check_rounded,
        );
        final correctButton = tester.widget<OutlinedButton>(
          find.byKey(ValueKey('learning-choice-${answer.telugu}')),
        );
        expect(correctButton.onPressed, isNull);
        expect(
          correctButton.style!.backgroundColor!.resolve({WidgetState.disabled}),
          dark ? AppColors.darkSuccessBackground : AppColors.successBackground,
        );
        final feedback = tester.widget<Container>(
          find.byKey(const ValueKey('learning-correct')),
        );
        expect(
          (feedback.decoration! as BoxDecoration).color,
          dark ? AppColors.darkSuccessBackground : AppColors.successBackground,
        );
        for (final choice in session.question.choices) {
          expectChoiceContrast(choice);
        }
        expect(session.score, 1);
        await _tap(tester, find.byKey(const ValueKey('learning-next')));
        expect(session.index, 1);
        expect(session.answerState, KidsAnswerState.ready);
        expect(find.byKey(const ValueKey('learning-correct')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'English Helper switches in Settings and updates the open activity',
    (tester) async {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        _host(KidsLearningScreen(onBack: () {}), settings),
      );
      await _tap(tester, find.byTooltip('సెట్టింగ్స్ / Settings'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('english-helper-setting')));
      expect(settings.englishHelper, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('kids-activity-pictures')));
      expect(find.text('What is this?'), findsOneWidget);
      expect(find.text('ఇది ఏమిటి?'), findsOneWidget);
      expect(find.text('Mango'), findsOneWidget);
      expect(find.text('మామిడి'), findsOneWidget);
      settings.setEnglishHelper(false);
      await tester.pumpAndSettle();
      expect(find.text('Mango'), findsNothing);
      expect(find.text('మామిడి'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'picture retry, completion, restart and dashboard star are real',
    (tester) async {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        _host(KidsLearningScreen(onBack: () {}), settings),
      );
      await _tap(tester, find.byKey(const ValueKey('kids-activity-pictures')));
      await _tap(tester, find.byKey(const ValueKey('learning-choice-జామ')));
      expect(find.byKey(const ValueKey('learning-retry')), findsOneWidget);
      expect(find.byKey(const ValueKey('learning-next')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('learning-choice-మామిడి')));
      expect(find.byKey(const ValueKey('learning-correct')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('learning-next')));
      expect(find.text('ప్రశ్న 2 / 5'), findsOneWidget);
      for (final question in activities.first.questions.skip(1)) {
        await _tap(
          tester,
          find.byKey(ValueKey('learning-choice-${question.answer}')),
        );
        await _tap(tester, find.byKey(const ValueKey('learning-next')));
      }
      expect(find.text('ఆట పూర్తయింది!'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('learning-restart')));
      expect(find.text('ప్రశ్న 1 / 5'), findsOneWidget);
      await _tap(tester, find.byTooltip('ఆటలకు వెళ్లు / Return to activities'));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('kids-stars'))).data,
        '1',
      );
      await _tap(tester, find.byKey(const ValueKey('kids-activity-pictures')));
      expect(find.text('ప్రశ్న 1 / 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'builder exposes undo, reset, correct full sequence and no partial success',
    (tester) async {
      final settings = AppSettingsController();
      final session = KidsActivitySession(
        activities.firstWhere((a) => a.id == 'builder'),
        () {},
      );
      addTearDown(settings.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        _host(KidsActivityScreen(session: session), settings),
      );
      await _tap(tester, find.byKey(const ValueKey('learning-tile-2')));
      await _tap(tester, find.byKey(const ValueKey('learning-check')));
      expect(find.byKey(const ValueKey('learning-retry')), findsOneWidget);
      expect(session.score, 0);
      await _tap(tester, find.byKey(const ValueKey('learning-undo')));
      expect(session.selectedTiles, isEmpty);
      await _tap(tester, find.byKey(const ValueKey('learning-tile-0')));
      await _tap(tester, find.byKey(const ValueKey('learning-clear')));
      expect(session.selectedTiles, isEmpty);
      for (final i in [2, 0, 1]) {
        await _tap(tester, find.byKey(ValueKey('learning-tile-$i')));
      }
      await _tap(tester, find.byKey(const ValueKey('learning-check')));
      expect(session.score, 1);
      expect(find.byKey(const ValueKey('learning-correct')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'meaning helper does not reveal target meaning before an answer',
    (tester) async {
      final settings = AppSettingsController()..setEnglishHelper(true);
      final session = KidsActivitySession(
        activities.firstWhere((a) => a.id == 'meanings'),
        () {},
      );
      addTearDown(settings.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        _host(KidsActivityScreen(session: session), settings),
      );
      await tester.pumpAndSettle();
      expect(find.text('Which word has a similar meaning?'), findsOneWidget);
      expect(find.text('ధైర్యం'), findsOneWidget);
      expect(
        find.text('Courage means facing something without fear.'),
        findsNothing,
      );
      await _tap(tester, find.byKey(const ValueKey('learning-choice-సాహసం')));
      await _tap(tester, find.byKey(const ValueKey('learning-check')));
      expect(
        find.text('Courage means facing something without fear.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Home and bottom navigation retain category and activity progress',
    (tester) async {
      await pumpReturningUserApp(tester);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('nav-learn')));
      await _tap(tester, find.byKey(const ValueKey('kids-category-explorers')));
      await _tap(
        tester,
        find.byKey(const ValueKey('kids-activity-completion-0')),
      );
      await _tap(tester, find.byKey(const ValueKey('learning-choice-లం')));
      await _tap(tester, find.byKey(const ValueKey('learning-check')));
      await _tap(tester, find.byTooltip('ఆటలకు వెళ్లు / Return to activities'));
      await _tap(tester, find.byTooltip('హోమ్‌కు వెళ్లు / Back to Home'));
      expect(find.text('Classic Padakeli'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('nav-learn')));
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('kids-category-explorers')),
      );
      expect(chip.selected, isTrue);
      await _tap(
        tester,
        find.byKey(const ValueKey('kids-activity-completion-0')),
      );
      expect(find.byKey(const ValueKey('learning-correct')), findsOneWidget);
      expect(find.text('కమలం'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'all activity controls remain bilingual with English Helper off',
    (tester) async {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      var nextActions = 0;
      for (final type in KidsActivityType.values) {
        final session = KidsActivitySession(
          activities.firstWhere((activity) => activity.type == type),
          () {},
        );
        await tester.pumpWidget(
          _host(
            KidsActivityScreen(session: session, onNext: () => nextActions++),
            settings,
          ),
        );
        await tester.pumpAndSettle();
        expect(settings.englishHelper, isFalse);
        expect(find.text('Return to activities'), findsOneWidget);
        expect(find.text('ఆటలకు వెళ్లు'), findsOneWidget);
        if (type != KidsActivityType.picture &&
            type != KidsActivityType.letter) {
          expect(find.text('Check answer'), findsOneWidget);
        }
        if (type == KidsActivityType.builder) {
          expect(find.text('Undo last tile'), findsOneWidget);
          expect(find.text('Reset attempt'), findsOneWidget);
        }
        if (type == KidsActivityType.picture) {
          expect(find.text('What is this?'), findsNothing);
          expect(find.text('Mango'), findsNothing);
        }
        _completeSession(session);
        await tester.pumpAndSettle();
        expect(find.text('Next level'), findsOneWidget);
        expect(find.text('Play again'), findsOneWidget);
        expect(find.text('Return to activities'), findsOneWidget);
        await _tap(tester, find.text('Next level'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();
      }
      expect(nextActions, KidsActivityType.values.length);
    },
  );

  for (final (width, height, scale, appScale) in [
    (320.0, 568.0, 1.0, 1.0),
    (390.0, 844.0, 1.0, 1.0),
    (800.0, 1024.0, 1.0, 1.0),
    (320.0, 568.0, 3.2, 1.4),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'all Kids surfaces fit $width x $height scale=$scale dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final settings = AppSettingsController()..setEnglishHelper(true);
          addTearDown(settings.dispose);
          await tester.pumpWidget(
            _host(
              KidsLearningScreen(onBack: () {}),
              settings,
              dark: dark,
              systemScale: scale,
              appScale: appScale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byKey(const ValueKey('kids-legacy')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final type in KidsActivityType.values) {
            final session = KidsActivitySession(
              activities.firstWhere((a) => a.type == type),
              () {},
            );
            await tester.pumpWidget(
              _host(
                KidsActivityScreen(session: session),
                settings,
                dark: dark,
                systemScale: scale,
                appScale: appScale,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$type initial layout',
            );
            final target = type == KidsActivityType.builder
                ? find.byKey(const ValueKey('learning-tile-0'))
                : find.byKey(
                    ValueKey(
                      'learning-choice-${session.question.choices.first.telugu}',
                    ),
                  );
            await _tap(tester, target);
            if (type == KidsActivityType.builder) {
              expect(session.selectedTiles, [0]);
            } else {
              expect(session.choice, session.question.choices.first.telugu);
            }
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull, reason: '$type controls');
            session.restart();
            _completeSession(session);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$type completion layout',
            );
            await _tap(tester, find.byKey(const ValueKey('learning-restart')));
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            session.dispose();
          }
        },
      );
    }
  }
}
