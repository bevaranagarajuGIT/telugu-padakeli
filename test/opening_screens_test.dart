import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/main.dart';
import 'package:telugu_padakeli/screens/padakeli_onboarding_screen.dart';
import 'package:telugu_padakeli/screens/padakeli_splash_screen.dart';
import 'package:telugu_padakeli/services/onboarding_store.dart';
import 'package:telugu_padakeli/shared/widgets/opening_artwork.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

class _Store implements OnboardingStore {
  bool completed = false;
  bool readError = false;
  bool saveError = false;
  int writes = 0;
  int reads = 0;
  Completer<bool>? reading;
  Completer<void>? writing;

  @override
  Future<bool> hasCompleted() async {
    reads++;
    if (readError) throw StateError('Test read failure');
    return reading == null ? completed : await reading!.future;
  }

  @override
  Future<void> complete() async {
    writes++;
    if (saveError) throw StateError('Test save failure');
    if (writing != null) await writing!.future;
    completed = true;
  }
}

Future<void> _frameReady() async {}

TeluguPadakeliApp _testApp(OnboardingStore store) =>
    TeluguPadakeliApp(onboardingStore: store, waitForFirstFrame: _frameReady);

Future<void> _launch(WidgetTester tester, OnboardingStore store) async {
  await tester.pumpWidget(_testApp(store));
  await tester.runAsync(() async {
    final context = tester.element(find.byType(TeluguPadakeliApp));
    await Future.wait([
      precacheImage(
        ResizeImage.resizeIfNeeded(
          960,
          null,
          const AssetImage(openingTempleAsset),
        ),
        context,
      ),
      precacheImage(
        ResizeImage.resizeIfNeeded(
          960,
          null,
          const AssetImage(openingFamilyAsset),
        ),
        context,
      ),
    ]);
  });
  await tester.pumpAndSettle();
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

  test('Completion persists across new store instances', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await const PreferencesOnboardingStore().hasCompleted(), isFalse);
    await const PreferencesOnboardingStore().complete();
    expect(await const PreferencesOnboardingStore().hasCompleted(), isTrue);
  });

  testWidgets(
    'Production store skips Welcome after an actual saved completion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _launch(tester, const PreferencesOnboardingStore());
      await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
      await tester.pumpAndSettle();
      expect(await const PreferencesOnboardingStore().hasCompleted(), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await _launch(tester, const PreferencesOnboardingStore());
      expect(find.byType(PadakeliOnboardingScreen), findsNothing);
      expect(find.text('Classic Padakeli'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Reduced motion disables the fade and saving spinner', (
    tester,
  ) async {
    Widget surface(Widget screen) => MaterialApp(
      theme: AppTheme.light(1),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: screen,
    );
    await tester.pumpWidget(surface(const PadakeliSplashScreen()));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.byType(TweenAnimationBuilder<double>),
          )
          .duration,
      Duration.zero,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(
      surface(PadakeliOnboardingScreen(onComplete: () {}, busy: true)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('onboarding-start')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'Splash waits for actual initialization, not an artificial timer',
    (tester) async {
      final store = _Store()..reading = Completer<bool>();
      await tester.pumpWidget(_testApp(store));
      expect(find.byType(PadakeliSplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(PadakeliSplashScreen), findsOneWidget);
      store.reading!.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Classic Padakeli'), findsOneWidget);
      expect(find.byType(PadakeliOnboardingScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Ready launch waits for a rendered frame and short Splash entrance',
    (tester) async {
      final store = _Store()..completed = true;
      final firstFrame = Completer<void>();
      await tester.pumpWidget(
        TeluguPadakeliApp(
          onboardingStore: store,
          waitForFirstFrame: () => firstFrame.future,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(store.reads, 0);
      firstFrame.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PadakeliSplashScreen), findsOneWidget);
      expect(find.text('Classic Padakeli'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Classic Padakeli'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Reduced-motion launch does not wait for the entrance duration', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final before = tester.binding.clock.now();
    await tester.pumpWidget(_testApp(_Store()..completed = true));
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
    expect(
      tester.binding.clock.now().difference(before),
      lessThan(const Duration(milliseconds: 350)),
    );
    expect(find.text('Classic Padakeli'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final action in ['onboarding-skip', 'onboarding-start']) {
    testWidgets('$action persists before Home and stays skipped on relaunch', (
      tester,
    ) async {
      final store = _Store();
      await _launch(tester, store);
      expect(find.byType(PadakeliOnboardingScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(ValueKey(action)));
      await tester.tap(find.byKey(ValueKey(action)));
      await tester.pumpAndSettle();
      expect(store.writes, 1);
      expect(store.completed, isTrue);
      expect(find.text('Classic Padakeli'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await _launch(tester, store);
      expect(find.byType(PadakeliOnboardingScreen), findsNothing);
      expect(find.text('Classic Padakeli'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Read failure is visible and Retry recovers', (tester) async {
    final store = _Store()..readError = true;
    await _launch(tester, store);
    expect(
      find.text('యాప్ తెరవలేకపోయాము. మళ్లీ ప్రయత్నించండి.'),
      findsOneWidget,
    );
    expect(find.text('Classic Padakeli'), findsNothing);
    store.readError = false;
    await tester.ensureVisible(find.text('మళ్లీ ప్రయత్నించండి'));
    await tester.tap(find.text('మళ్లీ ప్రయత్నించండి'));
    await tester.pumpAndSettle();
    expect(find.byType(PadakeliOnboardingScreen), findsOneWidget);
  });

  testWidgets('Failed save does not claim completion; Start retries', (
    tester,
  ) async {
    final store = _Store()..saveError = true;
    await _launch(tester, store);
    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-start')));
    await tester.tap(find.byKey(const ValueKey('onboarding-start')));
    await tester.pumpAndSettle();
    expect(
      find.text('మీ ఎంపికను దాచలేకపోయాము. మళ్లీ ప్రయత్నించండి.'),
      findsOneWidget,
    );
    expect(store.completed, isFalse);
    expect(find.text('Classic Padakeli'), findsNothing);
    store.saveError = false;
    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-start')));
    await tester.tap(find.byKey(const ValueKey('onboarding-start')));
    await tester.pumpAndSettle();
    expect(store.completed, isTrue);
    expect(find.text('Classic Padakeli'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Both actions disable during a single pending save', (
    tester,
  ) async {
    final store = _Store()..writing = Completer<void>();
    await _launch(tester, store);
    await tester.ensureVisible(find.byKey(const ValueKey('onboarding-start')));
    await tester.tap(find.byKey(const ValueKey('onboarding-start')));
    await tester.pump();
    for (final key in ['onboarding-start', 'onboarding-skip']) {
      expect(
        tester.widget<FilledButton>(find.byKey(ValueKey(key))).onPressed,
        isNull,
      );
    }
    expect(store.writes, 1);
    expect(find.text('Classic Padakeli'), findsNothing);
    store.writing!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Classic Padakeli'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final pending in ['read', 'write']) {
    testWidgets('Disposal during $pending does not update disposed state', (
      tester,
    ) async {
      final store = _Store();
      if (pending == 'read') {
        store.reading = Completer<bool>();
        await tester.pumpWidget(_testApp(store));
      } else {
        store.writing = Completer<void>();
        await _launch(tester, store);
        await tester.ensureVisible(
          find.byKey(const ValueKey('onboarding-start')),
        );
        await tester.tap(find.byKey(const ValueKey('onboarding-start')));
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      if (pending == 'read') {
        store.reading!.complete(false);
      } else {
        store.writing!.complete();
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  for (final (width, height, appScale, systemScale) in [
    (320.0, 568.0, 1.0, 1.0),
    (390.0, 844.0, 1.0, 1.0),
    (430.0, 932.0, 1.0, 1.0),
    (768.0, 1024.0, 1.0, 1.0),
    (844.0, 390.0, 1.0, 1.0),
    (320.0, 568.0, 1.4, 3.2),
  ]) {
    for (final splash in [true, false]) {
      testWidgets(
        'Opening layout ${width}x$height app=$appScale system=$systemScale splash=$splash',
        (tester) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(appScale),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(top: 44, bottom: 34),
                  textScaler: TextScaler.linear(systemScale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: splash
                  ? const PadakeliSplashScreen()
                  : PadakeliOnboardingScreen(onComplete: () {}),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('తెలుగు పదకేళి'), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(OpeningScenery)).width, width);
          expect(tester.getSize(find.byType(OpeningPaperPanel)).width, width);
          if (!splash) {
            final skip = tester.getRect(
              find.byKey(const ValueKey('onboarding-skip')),
            );
            final credits = tester.getRect(find.byTooltip('Artwork credits'));
            expect(skip.overlaps(credits), isFalse);
            expect(skip.left, greaterThanOrEqualTo(0));
            expect(skip.right, lessThanOrEqualTo(width));
            final start = find.byKey(const ValueKey('onboarding-start'));
            if (width == 390) {
              final scene = tester.getRect(find.byType(OpeningScenery));
              expect(scene.height, greaterThanOrEqualTo(height * 0.42));
              expect(scene.height, lessThanOrEqualTo(height * 0.55));
              final description = tester.getRect(
                find.text(
                  'పదకేళి ఆడుతూ తెలుగు పద సంపదను పెంపొందించుకోండి, పిల్లలతో సరదాగా కుటుంబం మొత్తం ఆనందించండి.',
                ),
              );
              expect(
                tester.getRect(start).top - description.bottom,
                lessThan(90),
              );
              expect(
                tester.getRect(start).bottom,
                lessThanOrEqualTo(height - 34),
              );
            }
            await tester.ensureVisible(start);
            await tester.pumpAndSettle();
            expect(
              tester.getRect(start).bottom,
              lessThanOrEqualTo(height - 34),
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  test(
    'Bundled opening artwork decodes without distorted dimensions',
    () async {
      for (final asset in [openingTempleAsset, openingFamilyAsset]) {
        final bytes = await rootBundle.load(asset);
        expect(bytes.lengthInBytes, lessThan(600000));
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width / frame.image.height, closeTo(4 / 3, 0.001));
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
}
