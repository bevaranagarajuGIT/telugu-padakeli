import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/models/kids_learning.dart';
import 'package:telugu_padakeli/screens/kids_activity_screen.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/widgets/kids_completion_scene.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

Widget _host(
  Widget child,
  AppSettingsController settings, {
  bool reduced = false,
  bool dark = false,
  double scale = 1,
  double appScale = 1,
  GlobalKey<NavigatorState>? navigator,
}) => ChangeNotifierProvider.value(
  value: settings,
  child: MaterialApp(
    navigatorKey: navigator,
    theme: dark ? AppTheme.dark(appScale) : AppTheme.light(appScale),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(scale),
      ),
      child: child!,
    ),
    home: child,
  ),
);

Widget _scene({bool earned = true, bool animate = true}) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: KidsCompletionScene(
      totalStars: 1,
      earnedStar: earned,
      animate: animate,
    ),
  ),
);

KidsLearningActivity _activity() {
  final source = const KidsLearningService().getActivities().firstWhere(
    (activity) => activity.type == KidsActivityType.letter,
  );
  return KidsLearningActivity(
    id: 'completion-scene-letter',
    title: source.title,
    englishTitle: source.englishTitle,
    type: source.type,
    categories: source.categories,
    questions: [source.questions.last],
  );
}

void _finish(KidsActivitySession session) {
  session.selectChoice(session.question.answer);
  expect(session.check(), isTrue);
  session.next();
}

double _bankScale(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('completion-bank-pulse')))
    .transform
    .storage[0];

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

  testWidgets('earned star travels to the total and settles within 800ms', (
    tester,
  ) async {
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(_scene(), settings));
      expect(find.text('1'), findsOneWidget);
      expect(find.bySemanticsLabel('సంపాదించిన నక్షత్రాలు: 1'), findsOneWidget);
      expect(find.byKey(const ValueKey('completion-word')), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(
        find.byKey(const ValueKey('completion-star-flight')),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 350));
      final first = tester.getCenter(
        find.byKey(const ValueKey('completion-star-flight')),
      );
      await tester.pump(const Duration(milliseconds: 270));
      final later = tester.getCenter(
        find.byKey(const ValueKey('completion-star-flight')),
      );
      expect(later.dx, greaterThan(first.dx));
      expect(later.dy, lessThan(first.dy));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_bankScale(tester), greaterThan(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey('completion-star-flight')),
        findsNothing,
      );
      expect(_bankScale(tester), closeTo(1, 0.0001));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('replay celebrates without a reward flight or counter pulse', (
    tester,
  ) async {
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    await tester.pumpWidget(_host(_scene(earned: false), settings));
    for (final duration in [350, 370, 100]) {
      await tester.pump(Duration(milliseconds: duration));
      expect(
        find.byKey(const ValueKey('completion-star-flight')),
        findsNothing,
      );
      expect(_bankScale(tester), 1);
      expect(find.text('1'), findsOneWidget);
    }
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduced motion remains static after being re-enabled', (
    tester,
  ) async {
    final settings = AppSettingsController();
    final reduced = ValueNotifier(true);
    addTearDown(settings.dispose);
    addTearDown(reduced.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: reduced,
        builder: (_, value, _) => _host(_scene(), settings, reduced: value),
      ),
    );
    expect(_bankScale(tester), 1);
    reduced.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('completion-star-flight')), findsNothing);
    expect(_bankScale(tester), 1);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('background and resume never replay a stale flying reward', (
    tester,
  ) async {
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await tester.pumpWidget(_host(_scene(), settings));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byKey(const ValueKey('completion-star-flight')),
      findsOneWidget,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byKey(const ValueKey('completion-star-flight')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('completion-star-flight')), findsNothing);
    expect(_bankScale(tester), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('hidden scene cancels instead of resuming a reward flight', (
    tester,
  ) async {
    final settings = AppSettingsController();
    final active = ValueNotifier(true);
    addTearDown(settings.dispose);
    addTearDown(active.dispose);
    await tester.pumpWidget(
      _host(
        ValueListenableBuilder(
          valueListenable: active,
          builder: (_, enabled, _) =>
              TickerMode(enabled: enabled, child: _scene()),
        ),
        settings,
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    active.value = false;
    await tester.pump();
    active.value = true;
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('completion-star-flight')), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('first completion and replay display the real controller total', (
    tester,
  ) async {
    final settings = AppSettingsController();
    final learning = KidsLearningController();
    addTearDown(settings.dispose);
    addTearDown(learning.dispose);
    final session = learning.sessionFor(_activity());
    await tester.pumpWidget(
      _host(KidsActivityScreen(session: session, learning: learning), settings),
    );
    expect(find.text(session.question.answer), findsOneWidget);
    _finish(session);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('ఒక నక్షత్రం సంపాదించావు!'), findsOneWidget);
    expect(find.byKey(const ValueKey('completion-word')), findsNothing);
    expect(find.text(session.question.answer), findsNothing);
    expect(
      find.byKey(const ValueKey('special-phase-entrance')),
      findsOneWidget,
    );
    expect(learning.stars, 1);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('completion-star-count')))
          .data,
      '1',
    );
    settings.setEnglishHelper(true);
    await tester.pumpAndSettle();
    expect(learning.stars, 1);
    session.restart();
    await tester.pump();
    expect(find.text(session.question.answer), findsOneWidget);
    _finish(session);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('completion-star-flight')), findsNothing);
    expect(find.text('You earned one star!'), findsNothing);
    expect(find.byKey(const ValueKey('completion-word')), findsNothing);
    expect(find.text(session.question.answer), findsNothing);
    expect(learning.stars, 1);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('completion-star-count')))
          .data,
      '1',
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an already completed activity opens statically', (tester) async {
    final settings = AppSettingsController();
    final learning = KidsLearningController();
    addTearDown(settings.dispose);
    addTearDown(learning.dispose);
    final session = learning.sessionFor(_activity());
    _finish(session);
    await tester.pumpWidget(
      _host(KidsActivityScreen(session: session, learning: learning), settings),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('completion-star-flight')), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final dark in [false, true]) {
    testWidgets('scrolled finish and replay open at Hanuman, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()..setEnglishHelper(true);
      final learning = KidsLearningController();
      addTearDown(settings.dispose);
      addTearDown(learning.dispose);
      final session = learning.sessionFor(_activity());
      await tester.pumpWidget(
        _host(
          KidsActivityScreen(session: session, learning: learning),
          settings,
          dark: dark,
        ),
      );
      for (var attempt = 0; attempt < 2; attempt++) {
        session.selectChoice(session.question.answer);
        expect(session.check(), isTrue);
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const ValueKey('kids-activity-scroll')),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        final finish = find.byKey(const ValueKey('learning-next'));
        await Scrollable.ensureVisible(tester.element(finish), alignment: 0.5);
        await tester.pumpAndSettle();
        final quizScroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('kids-activity-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.drag(
          find.byKey(const ValueKey('kids-activity-scroll')),
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
        expect(quizScroll.position.pixels, greaterThan(0));
        await tester.tap(finish);
        await tester.pump();
        final completionScroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('kids-activity-completion-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(completionScroll, isNot(same(quizScroll)));
        expect(completionScroll.position.pixels, 0);
        final viewport = tester.getRect(
          find.byKey(const ValueKey('kids-activity-completion-scroll')),
        );
        final hanuman = tester.getRect(
          find.byKey(const ValueKey('bal-hanuman-character')),
        );
        expect(hanuman.top, greaterThanOrEqualTo(viewport.top));
        expect(hanuman.bottom, lessThanOrEqualTo(viewport.bottom));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('bal-hanuman-character')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('completion-word')), findsNothing);
        expect(find.text(session.question.answer), findsNothing);
        expect(learning.stars, 1);
        final stage = tester.widget<Container>(
          find.byKey(const ValueKey('special-celebration-stage')),
        );
        final stageColor = (stage.decoration! as BoxDecoration).color!;
        final praise = tester.widget<Text>(find.text('శభాష్!'));
        final praiseLuminance = praise.style!.color!.computeLuminance();
        final stageLuminance = stageColor.computeLuminance();
        expect(
          (praiseLuminance > stageLuminance
              ? (praiseLuminance + 0.05) / (stageLuminance + 0.05)
              : (stageLuminance + 0.05) / (praiseLuminance + 0.05)),
          greaterThanOrEqualTo(3),
        );
        final result = tester.widget<Container>(
          find.byKey(const ValueKey('learning-completion-result')),
        );
        expect(
          (result.decoration! as BoxDecoration).color,
          dark ? AppColors.darkSuccessBackground : AppColors.successBackground,
        );
        final replay = find.byKey(const ValueKey('learning-restart'));
        await Scrollable.ensureVisible(tester.element(replay), alignment: 0.5);
        await tester.pumpAndSettle();
        expect(completionScroll.position.pixels, greaterThan(0));
        await tester.tap(replay);
        await tester.pumpAndSettle();
        expect(session.complete, isFalse);
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
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('return remains usable while the celebration is playing', (
    tester,
  ) async {
    final settings = AppSettingsController();
    final learning = KidsLearningController();
    final nav = GlobalKey<NavigatorState>();
    addTearDown(settings.dispose);
    addTearDown(learning.dispose);
    final session = learning.sessionFor(_activity());
    await tester.pumpWidget(
      _host(
        const Scaffold(body: Text('Activity list')),
        settings,
        navigator: nav,
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            KidsActivityScreen(session: session, learning: learning),
      ),
    );
    await tester.pumpAndSettle();
    _finish(session);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byKey(const ValueKey('special-phase-entrance')),
      findsOneWidget,
    );
    final back = find.byKey(const ValueKey('learning-return'));
    await tester.ensureVisible(back);
    await tester.pump();
    expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('Activity list'), findsOneWidget);
    expect(learning.stars, 1);
  });

  for (final size in [
    const Size(320, 640),
    const Size(360, 740),
    const Size(390, 844),
  ]) {
    testWidgets('phone completion needs no scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()..setEnglishHelper(true);
      final learning = KidsLearningController();
      addTearDown(settings.dispose);
      addTearDown(learning.dispose);
      final session = learning.sessionFor(_activity());
      _finish(session);
      await tester.pumpWidget(
        _host(
          KidsActivityScreen(
            session: session,
            learning: learning,
            onNext: () {},
          ),
          settings,
          reduced: true,
        ),
      );
      await tester.pumpAndSettle();
      final viewport = find.byKey(
        const ValueKey('kids-activity-completion-scroll'),
      );
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: viewport, matching: find.byType(Scrollable)),
      );
      expect(scroll.position.maxScrollExtent, 0);
      expect(
        find.byKey(const ValueKey('special-celebration-skip')),
        findsNothing,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('bal-hanuman-character')))
            .height,
        lessThanOrEqualTo(112),
      );
      for (final key in [
        'learning-restart',
        'learning-return',
        'learning-next-activity',
      ]) {
        expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
      }
      expect(learning.stars, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(800, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('completion fits $size, text $scale, dark $dark', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final settings = AppSettingsController()..setEnglishHelper(true);
          final learning = KidsLearningController();
          addTearDown(settings.dispose);
          addTearDown(learning.dispose);
          final session = learning.sessionFor(_activity());
          _finish(session);
          await tester.pumpWidget(
            _host(
              KidsActivityScreen(session: session, learning: learning),
              settings,
              reduced: true,
              dark: dark,
              scale: scale,
              appScale: 1.4,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final key in ['learning-return', 'learning-restart']) {
            final button = find.byKey(ValueKey(key));
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
          }
          await tester.tap(find.byKey(const ValueKey('learning-restart')));
          await tester.pumpAndSettle();
          expect(session.complete, isFalse);
          expect(learning.stars, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
