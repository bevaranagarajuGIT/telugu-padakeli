import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'helpers/returning_user_app.dart';
import 'package:telugu_padakeli/screens/home_screen.dart';
import 'package:telugu_padakeli/shared/widgets/app_header.dart';
import 'package:telugu_padakeli/shared/widgets/bottom_navigation.dart';
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
        expect(bytes.buffer.asUint8List(bytes.offsetInBytes, 8), [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ], reason: asset);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;
        expect(image.width, inInclusiveRange(128, 1536), reason: asset);
        expect(image.height, inInclusiveRange(128, 1536), reason: asset);
        if (asset != HomeArtwork.background) {
          expect(
            image.width / image.height,
            inInclusiveRange(0.65, 1.8),
            reason: asset,
          );
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
        find.byKey(const ValueKey('home-mascot-motion'), skipOffstage: !hidden),
      )
      .transform
      .storage[13];

  testWidgets('saved Home fits above native navigation on a standard phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 24);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(1),
        home: Scaffold(
          body: HomeScreen(
            onClassic: () {},
            onLearn: () {},
            onProgress: () {},
            onSettings: () {},
            onRiddles: () {},
            hasSavedLearning: true,
          ),
          bottomNavigationBar: BottomNavigation(
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final navigation = tester.getRect(find.byType(NavigationBar));
    for (final action in [
      'resume',
      'classic',
      'learn',
      'riddles',
      'daily',
      'progress',
    ]) {
      final rect = tester.getRect(find.byKey(ValueKey('home-$action')));
      expect(rect.top, greaterThanOrEqualTo(0), reason: action);
      expect(rect.bottom, lessThanOrEqualTo(navigation.top), reason: action);
    }
    for (final title in ['పదకేళి ఆడండి', 'చిన్నారుల ఆటలు']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
      final lines = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: title.length),
          )
          .map((box) => box.top)
          .toSet();
      expect(
        lines,
        hasLength(1),
        reason: '$title should not wrap at normal phone size',
      );
    }
    for (final (action, label, minimum) in [
      ('learn', 'చిన్నారుల ఆటలు', 4.5),
      ('learn', 'Play & Learn', 4.5),
      ('riddles', 'పొడుపు కథలు', 3.0),
      ('riddles', 'Telugu Riddles', 4.5),
    ]) {
      final surface = find.descendant(
        of: find.byKey(ValueKey('home-$action')),
        matching: find.byType(Ink),
      );
      final gradient =
          (tester.widget<Ink>(surface).decoration! as BoxDecoration).gradient!
              as LinearGradient;
      final surfaceRect = tester.getRect(surface);
      final textTop = tester.getRect(find.text(label)).top;
      final position = (textTop - surfaceRect.top) / surfaceRect.height;
      final stops = gradient.stops!;
      var segment = 0;
      while (segment < stops.length - 2 && position > stops[segment + 1]) {
        segment++;
      }
      final color = Color.lerp(
        gradient.colors[segment],
        gradient.colors[segment + 1],
        ((position - stops[segment]) / (stops[segment + 1] - stops[segment]))
            .clamp(0, 1),
      )!;
      expect(
        1.05 / (color.computeLuminance() + 0.05),
        greaterThanOrEqualTo(minimum),
        reason: label,
      );
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final (width, scale) in [
    (320.0, 1.0),
    (390.0, 1.2),
    (411.0, 1.0),
    (768.0, 2.0),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'refined Home actions remain reachable at $width, scale=$scale, dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final opened = <String>[];
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark(1) : AppTheme.light(1),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: HomeScreen(
                onClassic: () => opened.add('classic'),
                onLearn: () => opened.add('learn'),
                onProgress: () => opened.add('progress'),
                onDaily: () => opened.add('daily'),
                onRiddles: () => opened.add('riddles'),
                onResume: () => opened.add('resume'),
                onSettings: () => opened.add('settings'),
                hasSavedLearning: true,
                storageNotice: 'Storage needs attention. Open Settings.',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('home-riddles-artwork')),
            findsOneWidget,
          );
          final classic = tester.getRect(
            find.byKey(const ValueKey('home-classic')),
          );
          final learn = tester.getRect(
            find.byKey(const ValueKey('home-learn')),
          );
          final daily = tester.getRect(
            find.byKey(const ValueKey('home-daily')),
          );
          final progress = tester.getRect(
            find.byKey(const ValueKey('home-progress')),
          );
          if (width < 372 || scale > 1.125) {
            expect(learn.top, greaterThan(classic.bottom));
            expect(progress.top, greaterThan(daily.bottom));
          } else {
            expect(classic.top, learn.top);
            expect(classic.height, learn.height);
            expect(daily.top, progress.top);
          }
          expect(tester.takeException(), isNull);
          for (final action in [
            'resume',
            'classic',
            'learn',
            'riddles',
            'daily',
            'progress',
          ]) {
            final finder = find.byKey(ValueKey('home-$action'));
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
            await tester.tap(finder);
            expect(opened.last, action);
            expect(tester.takeException(), isNull);
          }
          await tester.ensureVisible(find.byTooltip('Settings'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Settings'));
          expect(opened.last, 'settings');
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

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

  for (final width in [320.0, 390.0, 412.0]) {
    for (final fontScale in [1.0, 1.2]) {
      testWidgets(
        'compact header fits width $width and font scale $fontScale',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          var openedSettings = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(fontScale),
              home: HomeScreen(
                onClassic: () {},
                onLearn: () {},
                onProgress: () {},
                onSettings: () => openedSettings = true,
                hasActivePuzzle: true,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final scene = tester.getRect(find.byType(HomeScenery));
          final title = tester.getRect(find.text('తెలుగు పదకేళి'));
          final tagline = tester.getRect(find.text('పదాలతో ఆట, భాషతో ఆనందం'));
          final mascot = tester.getRect(
            find.byKey(const ValueKey('home-mascot-motion')),
          );
          expect(scene.contains(title.topLeft), isTrue);
          expect(scene.contains(title.bottomRight), isTrue);
          expect(scene.contains(tagline.topLeft), isTrue);
          expect(scene.contains(tagline.bottomRight), isTrue);
          expect(title.right, lessThanOrEqualTo(mascot.center.dx));
          expect(tagline.right, lessThanOrEqualTo(mascot.center.dx));
          if (fontScale > 1) {
            expect(title.right + 12, lessThanOrEqualTo(mascot.left + 0.001));
            expect(tagline.right + 12, lessThanOrEqualTo(mascot.left + 0.001));
          }
          final gradient = tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(HomeScenery),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .map((box) => box.decoration)
              .whereType<BoxDecoration>()
              .map((decoration) => decoration.gradient)
              .whereType<LinearGradient>()
              .where((gradient) => gradient.stops != null)
              .single;
          final textEdge = (tagline.right - scene.left) / scene.width;
          final stops = gradient.stops!;
          final segment = textEdge <= stops[1] ? 0 : 1;
          final shade = Color.lerp(
            gradient.colors[segment],
            gradient.colors[segment + 1],
            (textEdge - stops[segment]) / (stops[segment + 1] - stops[segment]),
          )!;
          final background = tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(HomeScenery),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .map((box) => box.decoration)
              .whereType<BoxDecoration>()
              .map((decoration) => decoration.gradient)
              .whereType<LinearGradient>()
              .singleWhere((gradient) => gradient.stops == null);
          final lightestBackground = background.colors
              .map((color) => Color.alphaBlend(shade, color))
              .reduce(
                (a, b) => a.computeLuminance() > b.computeLuminance() ? a : b,
              );
          expect(
            1.05 / (lightestBackground.computeLuminance() + 0.05),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            tester.getSize(find.byType(AppHeader)).height,
            lessThanOrEqualTo(fontScale > 1 ? 400 : 300),
          );
          expect(find.bySemanticsLabel('తెలుగు పదకేళి'), findsOneWidget);
          expect(
            find.bySemanticsLabel('పదాలతో ఆట, భాషతో ఆనందం'),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Settings'));
          expect(openedSettings, isTrue);
          expect(tester.takeException(), isNull);
          semantics.dispose();
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
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
      await pumpReturningUserApp(tester);
      await tester.pumpAndSettle();
      await startBob(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await tester.pumpAndSettle();
      });
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
          isFalse,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('settings route suspends Home motion until popped', (
    tester,
  ) async {
    await pumpReturningUserApp(tester);
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
    await pumpReturningUserApp(tester);
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
