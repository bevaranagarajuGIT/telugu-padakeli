import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
      expect(find.text('Picture matching'), findsNothing);
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
      expect(find.text('Meaning match'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'English Helper switches in Settings and updates the open activity',
    (tester) async {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        _host(KidsLearningScreen(onBack: () {}), settings),
      );
      await _tap(tester, find.byTooltip('సెట్టింగ్స్'));
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
      expect(find.text('ప్రశ్న 2 / 2'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('learning-choice-చిలుక')));
      await _tap(tester, find.byKey(const ValueKey('learning-next')));
      expect(find.text('అద్భుతం! ఆట పూర్తయింది.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('learning-restart')));
      expect(find.text('ప్రశ్న 1 / 2'), findsOneWidget);
      await _tap(tester, find.byTooltip('ఆటలకు వెళ్లు'));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('kids-stars'))).data,
        '1',
      );
      await _tap(tester, find.byKey(const ValueKey('kids-activity-pictures')));
      expect(find.text('ప్రశ్న 1 / 2'), findsOneWidget);
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
      final session = KidsActivitySession(activities.last, () {});
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
      await tester.pumpWidget(const TeluguPadakeliApp());
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('nav-learn')));
      await _tap(tester, find.byKey(const ValueKey('kids-category-explorers')));
      await _tap(
        tester,
        find.byKey(const ValueKey('kids-activity-completion-0')),
      );
      await _tap(tester, find.byKey(const ValueKey('learning-choice-లం')));
      await _tap(tester, find.byKey(const ValueKey('learning-check')));
      await _tap(tester, find.byTooltip('ఆటలకు వెళ్లు'));
      await _tap(tester, find.byTooltip('హోమ్‌కు వెళ్లు'));
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
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull, reason: '$type controls');
            session.restart();
            for (final question in session.activity.questions) {
              if (type == KidsActivityType.builder) {
                final unused = List.generate(question.tiles.length, (i) => i);
                for (final akshara in TeluguAkshara.split(question.answer)) {
                  final i = unused.firstWhere(
                    (i) => question.tiles[i] == akshara,
                  );
                  unused.remove(i);
                  session.selectTile(i);
                }
              } else {
                session.selectChoice(question.answer);
              }
              session.check();
              session.next();
            }
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
