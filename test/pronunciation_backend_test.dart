import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/services/pronunciation_audio_manager.dart';

class _TestAudioCache extends AudioCache {
  @override
  Future<String> loadPath(String fileName) async => '/test-only/$fileName';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel('xyz.luan/audioplayers');
  const globalMethods = MethodChannel('xyz.luan/audioplayers.global');
  const globalEvents = MethodChannel('xyz.luan/audioplayers.global/events');
  final calls = <MethodCall>[];
  final eventChannels = <MethodChannel>[];
  Completer<void>? prepareBarrier;
  Completer<void>? resumeBarrier;
  bool failNextStop = false;
  late Completer<void> preparing;
  late Completer<void> resuming;
  late AudioCache originalCache;

  Future<void> prepared(String id) async {
    final delivered = Completer<void>();
    messenger.handlePlatformMessage(
      'xyz.luan/audioplayers/events/$id',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'event': 'audio.onPrepared',
        'value': true,
      }),
      (_) => delivered.complete(),
    );
    await delivered.future;
  }

  setUp(() {
    calls.clear();
    eventChannels.clear();
    prepareBarrier = null;
    resumeBarrier = null;
    failNextStop = false;
    preparing = Completer<void>();
    resuming = Completer<void>();
    originalCache = AudioCache.instance;
    AudioCache.instance = _TestAudioCache();
    messenger.setMockMethodCallHandler(globalMethods, (_) async => null);
    messenger.setMockMethodCallHandler(globalEvents, (_) async => null);
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      final args = call.arguments as Map;
      final id = args['playerId'] as String;
      if (call.method == 'stop' && failNextStop) {
        failNextStop = false;
        throw PlatformException(code: 'test-stop-failure');
      }
      if (call.method == 'create') {
        final events = MethodChannel('xyz.luan/audioplayers/events/$id');
        eventChannels.add(events);
        messenger.setMockMethodCallHandler(events, (_) async => null);
      }
      if (call.method == 'setSourceUrl') {
        expect(args['isLocal'], isTrue);
        expect(args['url'], startsWith('/test-only/audio/pronunciation/'));
        if (!preparing.isCompleted) preparing.complete();
        await prepareBarrier?.future;
        await prepared(id);
      }
      if (call.method == 'resume') {
        if (!resuming.isCompleted) resuming.complete();
        await resumeBarrier?.future;
      }
      if (call.method == 'getCurrentPosition' || call.method == 'getDuration') {
        return 0;
      }
      return null;
    });
  });

  tearDown(() {
    AudioCache.instance = originalCache;
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(globalMethods, null);
    messenger.setMockMethodCallHandler(globalEvents, null);
    for (final channel in eventChannels) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  for (final action in ['stop', 'replace', 'dispose']) {
    test('real backend cancels a preparing source on $action', () async {
      final backend = BundledPronunciationBackend();
      prepareBarrier = Completer<void>();
      final first = backend.play('assets/audio/pronunciation/letter-a.wav');
      await preparing.future;
      final next = switch (action) {
        'stop' => backend.stop(),
        'replace' => backend.play('assets/audio/pronunciation/letter-aa.wav'),
        _ => backend.dispose(),
      };
      prepareBarrier!.complete();
      await Future.wait([first, next]);
      final resumes = calls.where((call) => call.method == 'resume');
      expect(resumes, hasLength(action == 'replace' ? 1 : 0));
      final sources = calls
          .where((call) => call.method == 'setSourceUrl')
          .map((call) => (call.arguments as Map)['url']);
      if (action == 'replace') {
        expect(sources.last, endsWith('/letter-aa.wav'));
      }

      await backend.dispose();
      expect(calls.where((call) => call.method == 'dispose'), hasLength(1));
    });
  }

  test(
    'a failed native operation is reported and does not poison retries',
    () async {
      final backend = BundledPronunciationBackend();
      failNextStop = true;
      await expectLater(
        backend.play('assets/audio/pronunciation/letter-a.wav'),
        throwsA(isA<PlatformException>()),
      );
      await backend.play('assets/audio/pronunciation/letter-a.wav');
      expect(calls.where((call) => call.method == 'resume'), hasLength(1));
      await backend.dispose();
    },
  );

  test(
    'stop after an in-flight native resume executes after that resume',
    () async {
      final backend = BundledPronunciationBackend();
      resumeBarrier = Completer<void>();
      final play = backend.play('assets/audio/pronunciation/letter-a.wav');
      await resuming.future;
      final stop = backend.stop();
      resumeBarrier!.complete();
      await Future.wait([play, stop]);
      final stateCalls = calls
          .where((call) => {'resume', 'stop'}.contains(call.method))
          .map((call) => call.method);
      expect(stateCalls, ['stop', 'resume', 'stop']);
      await backend.dispose();
    },
  );

  test(
    'native decoder errors after starting reach the manager error stream',
    () async {
      final backend = BundledPronunciationBackend();
      await backend.play('assets/audio/pronunciation/letter-a.wav');
      final error = backend.playbackErrors.first;
      final id =
          (calls.firstWhere((call) => call.method == 'create').arguments
              as Map)['playerId'];
      final delivered = Completer<void>();
      messenger.handlePlatformMessage(
        'xyz.luan/audioplayers/events/$id',
        const StandardMethodCodec().encodeErrorEnvelope(
          code: 'late-decoder-failure',
          message: 'Test fixture failure after native resume',
        ),
        (_) => delivered.complete(),
      );
      await delivered.future;
      expect(await error, isA<PlatformException>());
      await backend.dispose();
    },
  );
}
