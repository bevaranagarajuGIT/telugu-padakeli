import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/models/kids_learning.dart';
import 'package:telugu_padakeli/screens/kids_activity_screen.dart';
import 'package:telugu_padakeli/screens/settings_screen.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/services/pronunciation_audio_manager.dart';
import 'package:telugu_padakeli/services/pronunciation_pack.dart';
import 'package:telugu_padakeli/widgets/pronunciation_button.dart';

Map<String, dynamic> _clip(String id, String text) => {
  'id': id,
  'text': text,
  'asset': 'assets/audio/pronunciation/$id.wav',
  'status': 'reviewed',
  'nativeSpeakerReviewed': true,
  'distributionPermission': true,
  'license':
      'Test fixture only; not a human recording or distribution license.',
};

String _manifest(List<Map<String, dynamic>> clips) =>
    jsonEncode({'version': 1, 'language': 'te-IN', 'clips': clips});

ByteData _testWav() {
  // Synthetic PCM bytes only for parsing tests, never a shipped voice asset.
  final bytes = ByteData(48);
  void tag(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, 40, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, 44100, Endian.little);
  bytes.setUint32(28, 88200, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  bytes.setUint32(40, 4, Endian.little);
  bytes.setInt16(44, 100, Endian.little);
  bytes.setInt16(46, -100, Endian.little);
  return bytes;
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.manifest, {this.recording});
  final String manifest;
  final ByteData? recording;
  final requested = <String>[];
  bool failLoads = false;

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    if (failLoads) throw FlutterError('Temporary test asset failure');
    if (key == 'assets/data/pronunciation_pack.json') {
      return ByteData.sublistView(Uint8List.fromList(utf8.encode(manifest)));
    }
    if (recording != null) return recording!;
    throw FlutterError('Missing test audio: $key');
  }
}

class _Backend implements PronunciationBackend {
  final errors = StreamController<Object>.broadcast();
  @override
  Stream<Object> get playbackErrors => errors.stream;
  final played = <String>[];
  int stops = 0;
  int disposals = 0;
  int generation = 0;
  bool fail = false;
  Completer<void>? barrier;

  @override
  Future<void> play(String asset) async {
    final request = ++generation;
    await barrier?.future;
    if (request != generation) return;
    if (fail) throw PlatformException(code: 'playback-test-failure');
    played.add(asset);
  }

  @override
  Future<void> stop() async {
    generation++;
    stops++;
  }

  @override
  Future<void> dispose() async {
    generation++;
    disposals++;
    await errors.close();
  }
}

Future<PronunciationAudioManager> _audio(_Backend backend) async {
  final audio = PronunciationAudioManager(
    backend: backend,
    bundle: _Bundle(
      _manifest([
        _clip('letter-a', 'అ'),
        _clip('word-arati', 'అరటి'),
        _clip('word-maamidi', 'మామిడి'),
      ]),
      recording: _testWav(),
    ),
  );
  await audio.load();
  return audio;
}

Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shipped pack has 11 pending items and no approved audio', () async {
    final pack = await PronunciationPack.load(rootBundle);
    expect(pack.pendingCount, 11);
    expect(pack.clips, isEmpty);
  });

  test('pending entries never attempt to load nonexistent files', () async {
    final bundle = _Bundle(
      _manifest([
        {
          ..._clip('letter-a', 'అ'),
          'status': 'pending-recording',
          'nativeSpeakerReviewed': false,
        },
      ]),
    );
    final pack = await PronunciationPack.load(bundle);
    expect(pack.clips, isEmpty);
    expect(bundle.requested, ['assets/data/pronunciation_pack.json']);
  });

  for (final field in [
    'nativeSpeakerReviewed',
    'distributionPermission',
    'license',
  ]) {
    test('reviewed entry without $field is rejected', () {
      final clip = _clip('letter-a', 'అ')..remove(field);
      expect(
        () => PronunciationPack.parse(_manifest([clip])),
        throwsFormatException,
      );
    });
  }

  test('duplicates, traversal, remote sources and wrong language fail', () {
    final clip = _clip('letter-a', 'అ');
    for (final source in [
      _manifest([clip, clip]),
      _manifest([clip, _clip('other', 'అ')]),
      _manifest([
        {...clip, 'asset': 'https://example.invalid/speech.wav'},
      ]),
      _manifest([
        {...clip, 'id': '../unsafe'},
      ]),
      jsonEncode({'version': 1, 'language': 'en-US', 'clips': []}),
    ]) {
      expect(() => PronunciationPack.parse(source), throwsFormatException);
    }
  });

  test('missing approved WAV cannot become available', () async {
    final backend = _Backend();
    final audio = PronunciationAudioManager(
      backend: backend,
      bundle: _Bundle(_manifest([_clip('letter-a', 'అ')])),
    );
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await audio.load();
      expect(audio.loading, isFalse);
      expect(audio.error, contains('could not be loaded'));
      expect(audio.hasRecording('అ'), isFalse);
      expect(errors.single.library, 'Telugu pronunciation');
      expect(backend.played, isEmpty);
    } finally {
      FlutterError.onError = original;
      audio.dispose();
      await _flush();
    }
  });

  test('truncated, non-PCM and empty WAV containers fail closed', () async {
    final nonPcm = _testWav()..setUint16(20, 3, Endian.little);
    final empty = _testWav()..setUint32(40, 0, Endian.little);
    for (final recording in [ByteData(8), nonPcm, empty]) {
      await expectLater(
        PronunciationPack.load(
          _Bundle(_manifest([_clip('letter-a', 'అ')]), recording: recording),
        ),
        throwsFormatException,
      );
    }
  });

  test('stereo data must contain whole sample frames', () async {
    final stereo = _testWav()
      ..setUint16(22, 2, Endian.little)
      ..setUint32(28, 176400, Endian.little)
      ..setUint16(32, 4, Endian.little)
      ..setUint32(4, 38, Endian.little)
      ..setUint32(40, 2, Endian.little);
    await expectLater(
      PronunciationPack.load(
        _Bundle(
          _manifest([_clip('letter-a', 'అ')]),
          recording: ByteData.sublistView(stereo.buffer.asUint8List(0, 46)),
        ),
      ),
      throwsFormatException,
    );
  });

  test('late playback failures are reported, stopped and retryable', () async {
    final backend = _Backend();
    final audio = await _audio(backend);
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await audio.play('అ', isForeground: true);
      backend.errors.add(PlatformException(code: 'late-decoder-failure'));
      await _flush();
      expect(audio.error, contains('Tap Listen to retry'));
      expect(errors.single.library, 'Telugu pronunciation');
      expect(backend.stops, 1);
      await audio.play('అ', isForeground: true);
      expect(audio.error, isNull);
      expect(backend.played, hasLength(2));
    } finally {
      FlutterError.onError = original;
      audio.dispose();
      await _flush();
    }
  });

  testWidgets('Settings retries a failed asset load without restarting', (
    tester,
  ) async {
    final bundle = _Bundle(
      _manifest([_clip('letter-a', 'అ')]),
      recording: _testWav(),
    )..failLoads = true;
    final audio = PronunciationAudioManager(
      backend: _Backend(),
      bundle: bundle,
    );
    final settings = AppSettingsController();
    await audio.load();
    expect(tester.takeException(), isA<FlutterError>());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: audio),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    final retry = find.byKey(const ValueKey('pronunciation-retry'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    bundle.failLoads = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(audio.error, isNull);
    expect(audio.hasRecording('అ'), isTrue);
    expect(retry, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    audio.dispose();
    settings.dispose();
  });

  testWidgets('route push and pop stop pronunciation without autoplay', (
    tester,
  ) async {
    final backend = _Backend();
    final audio = await _audio(backend);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [audio.navigationObserver],
        home: const Scaffold(),
      ),
    );
    await audio.play('అ', isForeground: true);
    final stops = backend.stops;
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold()),
      ),
    );
    await tester.pumpAndSettle();
    expect(backend.stops, greaterThan(stops));
    final pushedStops = backend.stops;
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(backend.stops, greaterThan(pushedStops));
    expect(backend.played, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    audio.dispose();
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.4]) {
      for (final dark in [false, true]) {
        testWidgets(
          'approved audio and Next fit ${width}x480 scale=$scale dark=$dark',
          (tester) async {
            tester.view.physicalSize = Size(width, 480);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final backend = _Backend();
            final audio = await _audio(backend);
            final settings = AppSettingsController()..setEnglishHelper(true);
            final learning = KidsLearningController();
            final activity = const KidsLearningService()
                .getActivities()
                .firstWhere(
                  (activity) => activity.type == KidsActivityType.letter,
                );
            final session = learning.sessionFor(activity);
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: audio),
                  ChangeNotifierProvider.value(value: settings),
                ],
                child: MaterialApp(
                  theme: dark ? AppTheme.dark(scale) : AppTheme.light(scale),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      disableAnimations: true,
                      padding: const EdgeInsets.only(top: 28, bottom: 24),
                    ),
                    child: child!,
                  ),
                  home: KidsActivityScreen(
                    session: session,
                    learning: learning,
                  ),
                ),
              ),
            );
            session.selectChoice(session.question.answer);
            session.check();
            await tester.pumpAndSettle();
            final listen = find.byKey(const ValueKey('pronunciation-అరటి'));
            await Scrollable.ensureVisible(
              tester.element(listen),
              alignment: 0.5,
            );
            await tester.pumpAndSettle();
            final footer = tester.getRect(
              find.byKey(const ValueKey('learning-action-footer')),
            );
            final viewport = tester.getRect(
              find.byKey(const ValueKey('kids-activity-scroll')),
            );
            final button = tester.getRect(listen);
            expect(button.top, greaterThanOrEqualTo(viewport.top));
            expect(button.bottom, lessThanOrEqualTo(footer.top));
            expect(listen.hitTestable(), findsOneWidget);
            await tester.tap(listen);
            await tester.pumpAndSettle();
            expect(backend.played, hasLength(1));
            final next = find.byKey(const ValueKey('learning-next'));
            expect(next.hitTestable(), findsOneWidget);
            await tester.tap(next);
            await tester.pumpAndSettle();
            expect(session.index, 1);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            audio.dispose();
            learning.dispose();
            settings.dispose();
          },
        );
      }
    }
  }

  test('bundled PCM is available but loading does not autoplay', () async {
    final backend = _Backend();
    final audio = await _audio(backend);
    expect(audio.hasRecording('అ'), isTrue);
    expect(audio.hasRecording('ఆ'), isFalse);
    expect(backend.played, isEmpty);
    await audio.play('అ', isForeground: true);
    await audio.play('అ', isForeground: true);
    expect(backend.played, hasLength(2));
    expect(backend.played.first, 'assets/audio/pronunciation/letter-a.wav');
    audio.dispose();
    await _flush();
    expect(backend.disposals, 1);
  });

  test('background/hidden play is blocked; resume never replays', () async {
    final backend = _Backend();
    final audio = await _audio(backend);
    await audio.play('అ', isForeground: false);
    audio.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await audio.play('అ', isForeground: true);
    audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _flush();
    expect(backend.played, isEmpty);
    expect(backend.stops, 1);
    audio.dispose();
  });

  test('stop, background and disposal invalidate pending starts', () async {
    for (final action in ['stop', 'background', 'dispose']) {
      final backend = _Backend()..barrier = Completer<void>();
      final audio = await _audio(backend);
      final play = audio.play('అ', isForeground: true);
      switch (action) {
        case 'stop':
          audio.stop();
        case 'background':
          audio.didChangeAppLifecycleState(AppLifecycleState.paused);
        case 'dispose':
          audio.dispose();
      }
      backend.barrier!.complete();
      await play;
      await _flush();
      expect(backend.played, isEmpty, reason: action);
      audio.dispose();
      await _flush();
      expect(backend.disposals, 1);
    }
  });

  test(
    'backend rejects network sources and disposes without starting a player',
    () async {
      final backend = BundledPronunciationBackend();
      await expectLater(
        backend.play('https://example.invalid/speech.wav'),
        throwsFormatException,
      );
      await backend.stop();
      await backend.dispose();
      await backend.dispose();
    },
  );

  testWidgets('button plays manually, replays, reports failure and retries', (
    tester,
  ) async {
    final backend = _Backend();
    final audio = await _audio(backend);
    final settings = AppSettingsController()..setEnglishHelper(true);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: audio),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PronunciationButton(text: 'అ')),
        ),
      ),
    );
    expect(backend.played, isEmpty);
    final listen = find.byKey(const ValueKey('pronunciation-అ'));
    await tester.tap(listen);
    await tester.pumpAndSettle();
    expect(backend.played, hasLength(1));
    expect(find.text('Replay — అ'), findsOneWidget);
    settings.setDarkMode(true);
    await tester.pumpAndSettle();
    expect(backend.played, hasLength(1));
    backend.fail = true;
    await tester.tap(listen);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<PlatformException>());
    expect(
      find.text('Audio could not play. Tap Listen to retry.'),
      findsOneWidget,
    );
    backend.fail = false;
    await tester.tap(listen);
    await tester.pumpAndSettle();
    expect(audio.error, isNull);
    expect(backend.played, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
    audio.dispose();
    settings.dispose();
  });

  testWidgets('pending pack does not display a nonfunctional button', (
    tester,
  ) async {
    final audio = PronunciationAudioManager(backend: _Backend());
    await tester.runAsync(audio.load);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: audio,
        child: const MaterialApp(
          home: Scaffold(body: PronunciationButton(text: 'అ')),
        ),
      ),
    );
    expect(find.byType(OutlinedButton), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    audio.dispose();
  });

  for (final picture in [false, true]) {
    testWidgets(
      '${picture ? 'picture' : 'letter'} audio does not reveal the answer or change progress',
      (tester) async {
        final backend = _Backend();
        final audio = await _audio(backend);
        final learning = KidsLearningController();
        final source = const KidsLearningService().getActivities().firstWhere(
          (activity) =>
              activity.type ==
              (picture ? KidsActivityType.picture : KidsActivityType.letter),
        );
        final session = learning.sessionFor(source);
        final settings = AppSettingsController()..setEnglishHelper(true);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: audio),
              ChangeNotifierProvider.value(value: settings),
            ],
            child: MaterialApp(
              navigatorObservers: [audio.navigationObserver],
              home: KidsActivityScreen(session: session, learning: learning),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final answer = picture ? 'మామిడి' : 'అరటి';
        final answerButton = find.byKey(ValueKey('pronunciation-$answer'));
        expect(answerButton, findsNothing);
        expect(backend.played, isEmpty);
        if (!picture) {
          final letterButton = find.byKey(const ValueKey('pronunciation-అ'));
          await tester.ensureVisible(letterButton);
          await tester.tap(letterButton);
          await tester.pumpAndSettle();
          expect(session.score, 0);
          expect(session.answerState, KidsAnswerState.ready);
          expect(learning.stars, 0);
        }
        session.selectChoice(session.question.answer);
        session.check();
        await tester.pumpAndSettle();
        await tester.ensureVisible(answerButton);
        await tester.tap(answerButton);
        await tester.pumpAndSettle();
        expect(backend.played.last, contains(picture ? 'maamidi' : 'arati'));
        expect(session.score, 1);
        expect(learning.stars, 0);
        final stops = backend.stops;
        session.next();
        await tester.pumpAndSettle();
        expect(backend.stops, greaterThan(stops));
        expect(answerButton, findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        audio.dispose();
        learning.dispose();
        settings.dispose();
      },
    );
  }
}
