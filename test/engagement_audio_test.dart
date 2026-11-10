import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/app/navigation/app_shell.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/models/kids_learning.dart';
import 'package:telugu_padakeli/screens/kids_activity_screen.dart';
import 'package:telugu_padakeli/screens/settings_screen.dart';
import 'package:telugu_padakeli/services/engagement_audio_manager.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'helpers/returning_user_app.dart';

class _RecordingBackend implements EngagementAudioBackend {
  _RecordingBackend({this.hasApprovedAssets = true});
  @override
  final bool hasApprovedAssets;
  final cues = <EngagementCue>[];
  int stops = 0;
  int disposals = 0;
  Completer<void>? stopBarrier;
  bool failPlayback = false;

  @override
  Future<void> play(EngagementCue cue) async {
    if (failPlayback) throw Exception('Test playback failure');
    cues.add(cue);
  }

  @override
  Future<void> stop() async {
    stops++;
    await stopBarrier?.future;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

Future<void> _flush() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sound is OFF initially and repeated preferences do not notify', () {
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    var notifications = 0;
    settings.addListener(() => notifications++);
    expect(settings.soundEnabled, isFalse);
    settings.setSoundEnabled(true);
    settings.setSoundEnabled(true);
    settings.setSoundEnabled(false);
    expect(notifications, 2);
  });

  test('OFF, unavailable sources and hidden-screen cues cannot play', () async {
    final settings = AppSettingsController();
    final backend = _RecordingBackend();
    final audio = EngagementAudioManager(settings, backend: backend);
    audio.play(EngagementCue.correct, isForeground: true);
    settings.setSoundEnabled(true);
    audio.play(EngagementCue.correct, isForeground: false);
    await _flush();
    expect(backend.cues, isEmpty);
    final unavailable = _RecordingBackend(hasApprovedAssets: false);
    final unreadyAudio = EngagementAudioManager(settings, backend: unavailable);
    unreadyAudio.play(EngagementCue.reward, isForeground: true);
    await _flush();
    expect(unavailable.cues, isEmpty);
    const silent = SilentEngagementAudioBackend();
    expect(silent.hasApprovedAssets, isFalse);
    await silent.play(EngagementCue.correct);
    unreadyAudio.dispose();
    audio.dispose();
    await _flush();
    settings.dispose();
  });

  test(
    'disabling sound cancels a pending start and does not queue it',
    () async {
      final settings = AppSettingsController()..setSoundEnabled(true);
      final backend = _RecordingBackend()..stopBarrier = Completer<void>();
      final audio = EngagementAudioManager(settings, backend: backend);
      audio.play(EngagementCue.correct, isForeground: true);
      settings.setSoundEnabled(false);
      backend.stopBarrier!.complete();
      await _flush();
      settings.setSoundEnabled(true);
      await _flush();
      expect(backend.cues, isEmpty);
      audio.play(EngagementCue.retry, isForeground: true);
      await _flush();
      expect(backend.cues, [EngagementCue.retry]);
      audio.dispose();
      await _flush();
      settings.dispose();
    },
  );

  test('background stops active audio; resume does not replay', () async {
    final settings = AppSettingsController()..setSoundEnabled(true);
    final backend = _RecordingBackend();
    final audio = EngagementAudioManager(settings, backend: backend);
    audio.play(EngagementCue.correct, isForeground: true);
    await _flush();
    expect(backend.cues, [EngagementCue.correct]);
    final stops = backend.stops;
    audio.didChangeAppLifecycleState(AppLifecycleState.inactive);
    audio.play(EngagementCue.reward, isForeground: true);
    audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _flush();
    expect(backend.stops, greaterThan(stops));
    expect(backend.cues, [EngagementCue.correct]);
    audio.dispose();
    await _flush();
    settings.dispose();
  });

  test(
    'dispose invalidates pending cues and releases its backend once',
    () async {
      final settings = AppSettingsController()..setSoundEnabled(true);
      final backend = _RecordingBackend()..stopBarrier = Completer<void>();
      final audio = EngagementAudioManager(settings, backend: backend);
      audio.play(EngagementCue.correct, isForeground: true);
      audio.dispose();
      audio.dispose();
      backend.stopBarrier!.complete();
      await _flush();
      audio.play(EngagementCue.reward, isForeground: true);
      expect(backend.cues, isEmpty);
      expect(backend.disposals, 1);
      settings.dispose();
    },
  );

  test('backend failure is explicitly reported', () async {
    final settings = AppSettingsController()..setSoundEnabled(true);
    final backend = _RecordingBackend()..failPlayback = true;
    final audio = EngagementAudioManager(settings, backend: backend);
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      audio.play(EngagementCue.correct, isForeground: true);
      await _flush();
      expect(errors.single.library, 'Engagement audio');
      expect(
        errors.single.exception.toString(),
        contains('Test playback failure'),
      );
    } finally {
      FlutterError.onError = original;
      audio.dispose();
      await _flush();
      settings.dispose();
    }
  });

  testWidgets('push and pop stop active or pending audio', (tester) async {
    final settings = AppSettingsController()..setSoundEnabled(true);
    final backend = _RecordingBackend();
    final audio = EngagementAudioManager(settings, backend: backend);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [audio.navigationObserver],
        home: const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();
    final initial = backend.stops;
    backend.stopBarrier = Completer<void>();
    audio.play(EngagementCue.correct, isForeground: true);
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    backend.stopBarrier!.complete();
    await tester.pumpAndSettle();
    expect(backend.cues, isEmpty);
    expect(backend.stops, greaterThan(initial));
    final pushed = backend.stops;
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(backend.stops, greaterThan(pushed));
    await tester.pumpWidget(const SizedBox.shrink());
    audio.dispose();
    await tester.pump();
    settings.dispose();
  });

  testWidgets('settings update the real app and licenses are reachable', (
    tester,
  ) async {
    await pumpReturningUserApp(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    final settings = tester
        .element(find.byType(SettingsScreen))
        .read<AppSettingsController>();
    final toggle = find.byKey(const ValueKey('sound-setting'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.soundEnabled, isTrue);
    expect(
      tester.widget<SwitchListTile>(toggle).subtitle,
      isA<Text>().having(
        (text) => text.data,
        'notice',
        contains('ప్రస్తుతం శబ్దాలు లేవు'),
      ),
    );
    final licenses = find.byKey(const ValueKey('licenses-setting'));
    await tester.ensureVisible(licenses);
    await tester.tap(licenses);
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(settings.soundEnabled, isTrue);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.soundEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'retained-tab and legacy navigation stop audio without route pushes',
    (tester) async {
      final settings = AppSettingsController()..setSoundEnabled(true);
      final backend = _RecordingBackend();
      final audio = EngagementAudioManager(settings, backend: backend);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            Provider.value(value: audio),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Play & Learn'));
      await tester.tap(find.text('Play & Learn'));
      await tester.pumpAndSettle();
      audio.play(EngagementCue.correct, isForeground: true);
      await tester.pump();
      final beforeLegacy = backend.stops;
      final legacy = find.byKey(const ValueKey('kids-legacy'));
      await tester.ensureVisible(legacy);
      await tester.tap(legacy);
      await tester.pumpAndSettle();
      expect(backend.stops, greaterThan(beforeLegacy));
      audio.play(EngagementCue.correct, isForeground: true);
      await tester.pump();
      final beforeHome = backend.stops;
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(backend.stops, greaterThan(beforeHome));
      await tester.pumpWidget(const SizedBox.shrink());
      audio.dispose();
      await tester.pump();
      settings.dispose();
    },
  );

  testWidgets(
    'success and new reward emit once; rebuilds and replays cannot award again',
    (tester) async {
      final settings = AppSettingsController()..setSoundEnabled(true);
      final backend = _RecordingBackend();
      final audio = EngagementAudioManager(settings, backend: backend);
      final learning = KidsLearningController();
      final source = const KidsLearningService().getActivities().firstWhere(
        (a) => a.type == KidsActivityType.letter,
      );
      final activity = KidsLearningActivity(
        id: 'one-letter',
        title: source.title,
        englishTitle: source.englishTitle,
        type: source.type,
        categories: source.categories,
        questions: [source.questions.first],
      );
      final session = learning.sessionFor(activity);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            Provider.value(value: audio),
          ],
          child: MaterialApp(home: KidsActivityScreen(session: session)),
        ),
      );
      await tester.pumpAndSettle();
      session.selectChoice(session.question.answer);
      session.check();
      session.check();
      await tester.pumpAndSettle();
      expect(session.score, 1);
      expect(backend.cues, [EngagementCue.correct]);
      settings.setEnglishHelper(true);
      await tester.pumpAndSettle();
      expect(backend.cues, [EngagementCue.correct]);
      session.next();
      session.next();
      await tester.pumpAndSettle();
      expect(learning.stars, 1);
      expect(session.earnedStarOnCompletion, isTrue);
      expect(
        backend.cues.where((c) => c == EngagementCue.reward),
        hasLength(1),
      );
      expect(find.text('You earned one star!'), findsOneWidget);
      session.restart();
      session.selectChoice(session.question.answer);
      session.check();
      session.next();
      await tester.pumpAndSettle();
      expect(learning.stars, 1);
      expect(session.earnedStarOnCompletion, isFalse);
      expect(
        backend.cues.where((c) => c == EngagementCue.reward),
        hasLength(1),
      );
      expect(find.text('You earned one star!'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      audio.dispose();
      learning.dispose();
      await tester.pump();
      settings.dispose();
    },
  );
}
