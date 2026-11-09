import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/widgets/engagement_motion.dart';

Widget _host(
  Widget child, {
  bool reduced = false,
  GlobalKey<NavigatorState>? nav,
}) => MaterialApp(
  navigatorKey: nav,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
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
