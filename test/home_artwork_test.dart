import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/main.dart';
import 'package:telugu_padakeli/screens/home_screen.dart';
import 'package:telugu_padakeli/shared/widgets/feature_card.dart';
import 'package:telugu_padakeli/shared/widgets/home_artwork.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test(
    'Home PNGs bundle, decode, and have bounded sizes and genuine alpha',
    () async {
      var totalBytes = 0;
      for (final asset in HomeArtwork.assets) {
        final bytes = await rootBundle.load(asset);
        totalBytes += bytes.lengthInBytes;
        expect(bytes.lengthInBytes, lessThan(1500000), reason: asset);
        expect(
          bytes.buffer.asUint8List(bytes.offsetInBytes, 8),
          [137, 80, 78, 71, 13, 10, 26, 10],
          reason: asset,
        );
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;
        expect(image.width, inInclusiveRange(128, 1536), reason: asset);
        expect(image.height, inInclusiveRange(128, 1536), reason: asset);
        if (asset != HomeArtwork.background) {
          expect(image.width, image.height, reason: asset);
          final rgba = (await image.toByteData())!;
          var transparent = 0;
          var nearOpaque = 0;
          for (var index = 3; index < rgba.lengthInBytes; index += 4) {
            final alpha = rgba.getUint8(index);
            if (alpha == 0) transparent++;
            if (alpha >= 240) nearOpaque++;
          }
          final pixels = image.width * image.height;
          expect(transparent / pixels, greaterThan(0.10), reason: asset);
          expect(nearOpaque / pixels, greaterThan(0.10), reason: asset);
          expect(rgba.getUint8(3), 0, reason: '$asset top-left corner');
        }
        image.dispose();
        codec.dispose();
      }
      expect(totalBytes, lessThan(4000000));
    },
  );

  double mascotY(WidgetTester tester, {bool hidden = false}) => tester
      .widget<Transform>(
        find.byKey(
          const ValueKey('home-mascot-motion'),
          skipOffstage: !hidden,
        ),
      )
      .transform
      .storage[13];

  for (final width in [320.0, 390.0, 768.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets('illustrated Home fits at width $width, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark(1) : AppTheme.light(1),
            home: HomeScreen(
              onClassic: () {},
              onLearn: () {},
              onProgress: () {},
              onSettings: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(HomeScenery), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('My Progress'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  Future<void> startBob(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 550));
    expect(mascotY(tester), lessThan(-1));
  }

  testWidgets('illustrated card keeps one action and keyboard activation', (
    tester,
  ) async {
    var activations = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeatureCard(
            title: 'Classic',
            subtitle: 'Padakeli',
            icon: Icons.grid_on_rounded,
            artwork: FeatureCardArtwork.crossword,
            background: Colors.purple,
            foreground: Colors.white,
            onTap: () => activations++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Classic, Padakeli'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(activations, 2);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final tab in ['classic', 'learn', 'progress']) {
    testWidgets('hidden Home cancels idle timer and bob on $tab tab', (
      tester,
    ) async {
      await tester.pumpWidget(const TeluguPadakeliApp());
      await tester.pumpAndSettle();
      await startBob(tester);

      await tester.tap(find.byKey(ValueKey('nav-$tab')));
      await tester.pumpAndSettle();
      expect(mascotY(tester, hidden: true), 0);
      await tester.pump(const Duration(seconds: 12));
      expect(tester.binding.transientCallbackCount, 0);
      expect(mascotY(tester, hidden: true), 0);

      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await startBob(tester);
      if (tab == 'classic') {
        expect(
          tester.widget<HomeScenery>(find.byType(HomeScenery)).celebrating,
          isTrue,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('settings route suspends Home motion until popped', (tester) async {
    await tester.pumpWidget(const TeluguPadakeliApp());
    await tester.pumpAndSettle();
    await startBob(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 12));
    expect(mascotY(tester, hidden: true), 0);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await startBob(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('background lifecycle cancels and resumes Home idle motion', (
    tester,
  ) async {
    await tester.pumpWidget(const TeluguPadakeliApp());
    await tester.pumpAndSettle();
    await startBob(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 12));
    expect(mascotY(tester), 0);
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await startBob(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('live reduced-motion changes cancel and resume idle motion', (
    tester,
  ) async {
    var reduced = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: const Center(child: HomeScenery()),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await startBob(tester);
    update(() => reduced = true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 12));
    expect(mascotY(tester), 0);
    expect(tester.binding.transientCallbackCount, 0);
    update(() => reduced = false);
    await tester.pump();
    await startBob(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
