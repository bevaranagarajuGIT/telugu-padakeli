import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/widgets/bal_hanuman_character.dart';
import 'package:telugu_padakeli/widgets/engagement_motion.dart';

void main() {
  test('separate arm, head, tail and gada poses move and settle', () {
    final entrance = BalHanumanPose.at(0);
    final moving = BalHanumanPose.at(0.85 / 3.5);
    final end = BalHanumanPose.at(1);
    expect(entrance.scale, 0.88);
    expect(entrance.rise, 24);
    expect(entrance.armRaise, 0);
    expect(moving.armRaise, greaterThan(0));
    expect(moving.headTilt.abs(), greaterThan(0.01));
    expect(moving.tailSwing.abs(), greaterThan(0.05));
    expect(moving.gadaTilt.abs(), greaterThan(0.05));
    expect(end.scale, 1);
    expect(end.rise, 0);
    expect(end.armRaise, 1.9);
    expect(end.headTilt, closeTo(0, 1e-10));
    expect(end.tailSwing, closeTo(0, 1e-10));
    expect(end.gadaTilt, closeTo(0, 1e-10));
    expect(end.handWave, closeTo(0, 1e-10));
    final settled = BalHanumanPose.at(2.6 / 3.5);
    expect(settled.armRaise, end.armRaise);
    expect(settled.headTilt, end.headTilt);
    expect(settled.tailSwing, end.tailSwing);
  });

  test('wrist wave and gentle blink have independent finite timing', () {
    final waving = BalHanumanPose.at(1.2 / 3.5);
    final blinking = BalHanumanPose.at(1.07 / 3.5);
    expect(waving.armRaise, 1.9);
    expect(waving.handWave.abs(), greaterThan(0.05));
    expect(blinking.eyeOpen, closeTo(0.1, 1e-10));
    expect(BalHanumanPose.at(0).eyeOpen, 1);
    expect(BalHanumanPose.at(1).eyeOpen, closeTo(1, 1e-10));
  });

  test('original vector painting handles zero, small and large canvases', () {
    for (final size in [
      Size.zero,
      const Size(180, 200),
      const Size(280, 320),
      const Size(840, 960),
    ]) {
      final recorder = ui.PictureRecorder();
      final painter = BalHanumanPainter(const AlwaysStoppedAnimation(0.35));
      painter.paint(Canvas(recorder), size);
      recorder.endRecording().dispose();
      expect(
        painter.shouldRepaint(BalHanumanPainter(painter.progress)),
        isFalse,
      );
    }
  });

  testWidgets('reduced motion draws an accessible static vector character', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SizedBox(
                width: 180,
                height: 200,
                child: EngagementTimeline(
                  duration: const Duration(milliseconds: 3500),
                  builder: (_, progress) =>
                      BalHanumanCharacter(progress: progress),
                ),
              ),
            ),
          ),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('bal-hanuman-character')),
                  )
                  .painter!
              as BalHanumanPainter;
      expect(painter.progress.value, 1);
      expect(painter.pose.armRaise, 1.9);
      expect(
        find.bySemanticsLabel(
          'చిన్న హనుమంతుడు చిరునవ్వుతో చేయి ఊపుతూ అభినందిస్తున్నాడు',
        ),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
