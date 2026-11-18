import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/widgets/engagement_motion.dart';

Widget _host(
  Widget child, {
  bool reduced = false,
  double textScale = 1,
  bool dark = false,
  GlobalKey<NavigatorState>? nav,
}) => MaterialApp(
  navigatorKey: nav,
  theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduced,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: Scaffold(body: Center(child: child)),
);

double _scale(WidgetTester tester, Finder parent) => tester
    .widgetList<Transform>(
      find.descendant(
        of: parent,
        matching: find.byType(Transform, skipOffstage: false),
        skipOffstage: false,
      ),
    )
    .last
    .transform
    .storage[0];

int _characterFrame(WidgetTester tester) {
  final sprite = tester.widget<Positioned>(
    find.byKey(const ValueKey('answer-hanuman-sprite'), skipOffstage: false),
  );
  final side = sprite.width! / 6;
  return (-sprite.top! / side).round() * 6 + (-sprite.left! / side).round();
}

Future<int> _paintedPixels(WidgetTester tester) async {
  final painter = tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(EngagementReaction),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter!;
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(120, 120));
    final picture = recorder.endRecording();
    final image = await picture.toImage(120, 120);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = data!.buffer.asUint8List();
    var pixels = 0;
    for (var i = 3; i < bytes.length; i += 4) {
      if (bytes[i] > 0) pixels++;
    }
    image.dispose();
    picture.dispose();
    return pixels;
  }))!;
}

void main() {
  const reaction = EngagementReaction(
    moment: EngagementMoment.correct,
    child: Icon(Icons.star_rounded),
  );

  testWidgets('screen popup plays once without blocking or shifting feedback', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        AnswerCharacterCelebration(
          child: SizedBox(
            width: 300,
            height: 100,
            child: FilledButton(
              onPressed: () => taps++,
              child: const Text('Next question'),
            ),
          ),
        ),
      ),
    );
    final burst = find.byType(AnswerCharacterCelebration);
    final initialSize = tester.getSize(burst);
    final initialButton = tester.getRect(find.byType(FilledButton));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/artwork/kids/hanuman-answer-wave.png'),
        tester.element(burst),
      ),
    );
    expect(_characterFrame(tester), 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_characterFrame(tester), 5);
    expect(
      tester.getRect(find.byKey(const ValueKey('answer-celebration-popup'))),
      const Rect.fromLTWH(0, 0, 800, 600),
    );
    expect(initialSize, const Size(300, 100));
    await tester.tap(find.text('Next question'));
    expect(taps, 1);
    expect(tester.getSize(burst), initialSize);
    expect(tester.getRect(find.byType(FilledButton)), initialButton);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('answer-hanuman-artwork')), findsNothing);
    await tester.pumpWidget(
      _host(
        AnswerCharacterCelebration(
          child: SizedBox(
            width: 300,
            height: 100,
            child: FilledButton(
              onPressed: () => taps++,
              child: const Text('Next question'),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('answer-celebration-popup')),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion skips the popup and never replays when enabled again',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const AnswerCharacterCelebration(
            answerIndex: 1,
            child: SizedBox(width: 300, height: 100),
          ),
          reduced: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const ValueKey('answer-celebration-popup')),
        findsNothing,
      );
      await tester.pumpWidget(
        _host(
          const AnswerCharacterCelebration(
            answerIndex: 1,
            child: SizedBox(width: 300, height: 100),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const ValueKey('answer-celebration-popup')),
        findsNothing,
      );
      await tester.pumpWidget(
        _host(
          const AnswerCharacterCelebration(
            animate: false,
            answerIndex: 1,
            child: SizedBox(width: 300, height: 100),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('answer-hanuman-artwork')),
        findsNothing,
      );
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('background dismisses the popup without replay on resume', (
    tester,
  ) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await tester.pumpWidget(
      _host(
        const AnswerCharacterCelebration(
          child: SizedBox(width: 300, height: 100),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(_characterFrame(tester), 5);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('answer-celebration-popup')),
      findsNothing,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('answer-celebration-popup')),
      findsNothing,
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('new answers alternate artwork without replaying on rebuild', (
    tester,
  ) async {
    Widget answer(int index) => _host(
      AnswerCharacterCelebration(
        key: ValueKey(index),
        answerIndex: index,
        child: const Text('Correct'),
      ),
    );
    for (var index = 0; index < 3; index++) {
      await tester.pumpWidget(answer(index));
      final expected = AssetImage(
        'assets/artwork/kids/hanuman-answer-${index.isEven ? 'wave' : 'clap'}.png',
      );
      expect(
        tester
            .widget<Image>(find.byKey(const ValueKey('answer-hanuman-artwork')))
            .image,
        expected,
      );
      expect(_characterFrame(tester), 0);
      await tester.pump(const Duration(milliseconds: 250));
      expect(_characterFrame(tester), 5);
      await tester.pumpWidget(answer(index));
      expect(_characterFrame(tester), 5);
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        find.byKey(const ValueKey('answer-celebration-popup')),
        findsNothing,
      );
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('covering or removing the source removes its popup', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _host(const AnswerCharacterCelebration(child: Text('Correct')), nav: nav),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('answer-celebration-popup')),
      findsOneWidget,
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another screen')),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('answer-celebration-popup')),
      findsNothing,
    );
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('answer-celebration-popup')),
      findsNothing,
    );
    await tester.pumpWidget(
      _host(
        const AnswerCharacterCelebration(
          key: ValueKey('new-answer'),
          child: Text('Correct'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('answer-celebration-popup')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(
      find.byKey(const ValueKey('answer-celebration-popup')),
      findsNothing,
    );
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('popup fits $size with large text in dark mode', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _host(
          const AnswerCharacterCelebration(child: Text('Correct')),
          textScale: 3.2,
          dark: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      final viewport = Offset.zero & size;
      final artwork = tester.getRect(
        find
            .ancestor(
              of: find.byKey(const ValueKey('answer-hanuman-sprite')),
              matching: find.byType(ClipRect),
            )
            .first,
      );
      expect(viewport.contains(artwork.topLeft), isTrue);
      expect(viewport.contains(artwork.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('answer-celebration-popup')),
        findsNothing,
      );
    });
  }

  testWidgets('correct star pulses and stops within its 420ms budget', (
    tester,
  ) async {
    await tester.pumpWidget(_host(reaction));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_scale(tester, find.byType(EngagementReaction)), greaterThan(1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_scale(tester, find.byType(EngagementReaction)), closeTo(1, 0.0001));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'completion paints native particles then leaves no particle pixels',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const EngagementReaction(
            moment: EngagementMoment.completion,
            child: Icon(Icons.star_rounded),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(await _paintedPixels(tester), greaterThan(40));
      await tester.pump(const Duration(milliseconds: 650));
      expect(await _paintedPixels(tester), 0);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('reduced motion is instant and toggling back does not replay', (
    tester,
  ) async {
    final reduced = ValueNotifier(true);
    addTearDown(reduced.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: reduced,
        builder: (_, value, _) => _host(
          const EngagementReaction(
            moment: EngagementMoment.completion,
            child: Icon(Icons.star_rounded),
          ),
          reduced: value,
        ),
      ),
    );
    expect(_scale(tester, find.byType(EngagementReaction)), 1);
    expect(await _paintedPixels(tester), 0);
    reduced.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(_scale(tester, find.byType(EngagementReaction)), 1);
    expect(await _paintedPixels(tester), 0);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('background snaps to static and resume does not replay', (
    tester,
  ) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await tester.pumpWidget(_host(reaction));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_scale(tester, find.byType(EngagementReaction)), greaterThan(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(_scale(tester, find.byType(EngagementReaction)), 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 120));
    expect(_scale(tester, find.byType(EngagementReaction)), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'inactive TickerMode cancels instead of freezing an old reaction',
    (tester) async {
      final active = ValueNotifier(true);
      addTearDown(active.dispose);
      await tester.pumpWidget(
        _host(
          ValueListenableBuilder(
            valueListenable: active,
            builder: (_, value, _) =>
                TickerMode(enabled: value, child: reaction),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      active.value = false;
      await tester.pump();
      expect(_scale(tester, find.byType(EngagementReaction)), 1);
      active.value = true;
      await tester.pump(const Duration(milliseconds: 120));
      expect(_scale(tester, find.byType(EngagementReaction)), 1);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('covered route cancels motion and popping cannot restart it', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_host(reaction, nav: nav));
    await tester.pump(const Duration(milliseconds: 100));
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Covered')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _scale(tester, find.byType(EngagementReaction, skipOffstage: false)),
      1,
    );
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_scale(tester, find.byType(EngagementReaction)), 1);
  });

  testWidgets('tap feedback preserves hit area, semantics and one activation', (
    tester,
  ) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          TapFeedback(
            child: FilledButton(
              onPressed: () => taps++,
              style: FilledButton.styleFrom(minimumSize: const Size(100, 56)),
              child: const Text('Check'),
            ),
          ),
        ),
      );
      final button = find.byType(FilledButton);
      final initialSize = tester.getSize(button);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      expect(_scale(tester, find.byType(TapFeedback)), closeTo(0.975, 0.0001));
      expect(tester.getSize(button), initialSize);
      expect(find.bySemanticsLabel('Check'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(_scale(tester, find.byType(TapFeedback)), 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reduced-motion taps still activate without scaling', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        TapFeedback(
          child: FilledButton(
            onPressed: () => taps++,
            child: const Text('Check'),
          ),
        ),
        reduced: true,
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump(const Duration(milliseconds: 110));
    expect(_scale(tester, find.byType(TapFeedback)), 1);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('disabled and cancelled presses never activate', (tester) async {
    await tester.pumpWidget(
      _host(
        const TapFeedback(
          enabled: false,
          child: FilledButton(onPressed: null, child: Text('Disabled')),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(_scale(tester, find.byType(TapFeedback)), 1);
    var taps = 0;
    await tester.pumpWidget(
      _host(
        TapFeedback(
          child: FilledButton(
            onPressed: () => taps++,
            child: const Text('Check'),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(_scale(tester, find.byType(TapFeedback)), 1);
    expect(tester.takeException(), isNull);
  });
}
