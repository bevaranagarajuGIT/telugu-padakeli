import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/screens/kids_activity_screen.dart';
import 'package:telugu_padakeli/screens/kids_learning_screen.dart';
import 'package:telugu_padakeli/widgets/bal_hanuman_character.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';
import 'package:telugu_padakeli/widgets/special_achievement_celebration.dart';

Widget _host(
  Widget child, {
  bool reduced = false,
  AppSettingsController? settings,
  double scale = 1,
  bool dark = false,
  GlobalKey<NavigatorState>? nav,
}) => ChangeNotifierProvider(
  create: (_) => settings ?? AppSettingsController(),
  child: MaterialApp(
    navigatorKey: nav,
    theme: dark ? AppTheme.dark(1) : AppTheme.light(1),
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

Widget _scene({bool completed = true, Widget? character}) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: SpecialAchievementCelebration(
      completed: completed,
      earnedStar: true,
      totalStars: 1,
      character: character,
      characterDescription: character == null ? null : 'Test illustration',
    ),
  ),
);

double _starOpacity(WidgetTester tester, int index) => tester
    .widget<Opacity>(find.byKey(ValueKey('special-victory-star-$index')))
    .opacity;

void _finish(KidsActivitySession session) {
  for (final question in session.activity.questions) {
    session.selectChoice(question.answer);
    expect(session.check(), isTrue);
    session.next();
  }
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

  testWidgets('exact 3.5s phases and sequential decorative stars', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_scene()));
    expect(
      find.byKey(const ValueKey('special-phase-entrance')),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(BalHanumanCharacter), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 599));
    expect(
      find.byKey(const ValueKey('special-phase-entrance')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 2));
    expect(
      find.byKey(const ValueKey('special-phase-celebration')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const ValueKey('special-phase-victory')), findsOneWidget);
    expect(_starOpacity(tester, 0), greaterThan(0));
    expect(_starOpacity(tester, 1), 0);
    expect(_starOpacity(tester, 2), 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_starOpacity(tester, 0), 1);
    expect(_starOpacity(tester, 1), greaterThan(0));
    expect(_starOpacity(tester, 2), 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_starOpacity(tester, 2), greaterThan(0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('special-phase-completion')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.binding.transientCallbackCount, 0);
    expect(
      find.byKey(const ValueKey('special-celebration-skip')),
      findsNothing,
    );
  });

  testWidgets('celebration settles without a redundant skip control', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_scene()));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const ValueKey('special-celebration-skip')),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('special-phase-completion')),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget);
    expect(_starOpacity(tester, 2), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('native articulated character shares the completion clock', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_scene()));
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('bal-hanuman-character')),
                )
                .painter!
            as BalHanumanPainter;
    expect(painter.pose.armRaise, 0);
    await tester.pump(const Duration(milliseconds: 850));
    expect(painter.pose.armRaise, greaterThan(0));
    expect(painter.pose.headTilt.abs(), greaterThan(0.01));
    await tester.pumpAndSettle();
    expect(painter.progress.value, 1);
    expect(painter.pose.armRaise, 1.9);
    expect(painter.pose.tailSwing, closeTo(0, 1e-10));
    expect(find.text('1'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('an incomplete level has no celebration or controls', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_scene(completed: false)));
    expect(find.text('శభాష్!'), findsNothing);
    expect(
      find.byKey(const ValueKey('special-celebration-skip')),
      findsNothing,
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduced motion is static and does not restart on re-enable', (
    tester,
  ) async {
    final reduced = ValueNotifier(true);
    addTearDown(reduced.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: reduced,
        builder: (_, value, _) => _host(_scene(), reduced: value),
      ),
    );
    expect(
      find.byKey(const ValueKey('special-phase-completion')),
      findsOneWidget,
    );
    reduced.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('special-phase-completion')),
      findsOneWidget,
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('background and resume discard stale effects', (tester) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await tester.pumpWidget(_host(_scene()));
    await tester.pump(const Duration(milliseconds: 1800));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('special-phase-completion')),
      findsOneWidget,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('special-phase-completion')),
      findsOneWidget,
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('hidden effects settle and do not restart when shown', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    await tester.pumpWidget(
      _host(
        ValueListenableBuilder(
          valueListenable: active,
          builder: (_, value, _) => TickerMode(enabled: value, child: _scene()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    active.value = false;
    await tester.pump();
    active.value = true;
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('special-phase-completion')),
      findsOneWidget,
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('covered route cannot resume or overlap an old celebration', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_host(_scene(), nav: nav));
    await tester.pump(const Duration(milliseconds: 200));
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other screen')),
      ),
    );
    await tester.pumpAndSettle();
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('special-phase-completion')),
      findsOneWidget,
    );
  });

  testWidgets('an injected illustration moves as one accessible whole widget', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          _scene(
            character: const SizedBox(
              width: 100,
              height: 160,
              child: ColoredBox(color: Colors.orange),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Test illustration'), findsOneWidget);
      expect(find.text('సంపాదించిన నక్షత్రాలు: 1'), findsOneWidget);
      final first = tester
          .widget<Transform>(
            find.byKey(const ValueKey('special-character-motion')),
          )
          .transform
          .storage[13];
      await tester.pump(const Duration(milliseconds: 600));
      final entered = tester
          .widget<Transform>(
            find.byKey(const ValueKey('special-character-motion')),
          )
          .transform
          .storage[13];
      expect(entered, lessThan(first));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Next opens the next real activity once and preserves stars', (
    tester,
  ) async {
    await tester.pumpWidget(_host(KidsLearningScreen(onBack: () {})));
    final entry = find.byKey(const ValueKey('kids-activity-pictures'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    final current = tester.widget<KidsActivityScreen>(
      find.byType(KidsActivityScreen),
    );
    expect(find.byKey(const ValueKey('learning-next-activity')), findsNothing);
    _finish(current.session);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('special-phase-entrance')),
      findsOneWidget,
    );
    expect(current.learning!.stars, 1);
    final next = find.byKey(const ValueKey('learning-next-activity'));
    await tester.ensureVisible(next);
    await tester.pump();
    final action = tester.widget<FilledButton>(next).onPressed!;
    action();
    action();
    await tester.pumpAndSettle();
    final following = tester.widget<KidsActivityScreen>(
      find.byType(KidsActivityScreen),
    );
    expect(following.session.activity.id, 'letters');
    expect(following.session.complete, isFalse);
    expect(following.learning!.stars, 1);
    expect(find.byType(SpecialAchievementCelebration), findsNothing);
    _finish(following.session);
    await tester.pumpAndSettle();
    for (final (index, id) in ['letters-2', 'letters-3'].indexed) {
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      final additional = tester.widget<KidsActivityScreen>(
        find.byType(KidsActivityScreen),
      );
      expect(additional.session.activity.id, id);
      expect(additional.session.complete, isFalse);
      _finish(additional.session);
      await tester.pumpAndSettle();
      expect(additional.learning!.stars, index + 3);
    }
    expect(find.byKey(const ValueKey('learning-next-activity')), findsNothing);
    expect(find.byKey(const ValueKey('learning-return')), findsOneWidget);
    expect(following.learning!.stars, 4);
  });

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    for (final dark in [false, true]) {
      testWidgets('special scene fits $size at 2x text, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _host(_scene(), reduced: true, scale: 2, dark: dark),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('special-celebration-skip')),
          findsNothing,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('bal-hanuman-character')))
              .height,
          greaterThan(0),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
