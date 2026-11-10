import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pronunciation_pack.dart';

abstract interface class PronunciationBackend {
  Stream<Object> get playbackErrors;
  Future<void> play(String asset);
  Future<void> stop();
  Future<void> dispose();
}

class BundledPronunciationBackend implements PronunciationBackend {
  AudioPlayer? _player;
  Future<void> _tail = Future.value();
  int _generation = 0;
  bool _disposed = false;
  bool _preparing = false;
  final _errors = StreamController<Object>.broadcast();
  StreamSubscription<Object?>? _events;

  @override
  Stream<Object> get playbackErrors => _errors.stream;

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _tail.then((_) => action());
    // The returned operation reports failures to the manager, not the queue.
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  @override
  Future<void> play(String asset) {
    if (_disposed) {
      return Future.error(StateError('Pronunciation player is disposed.'));
    }
    if (!RegExp(
      r'^assets/audio/pronunciation/[a-z][a-z0-9-]*\.wav$',
    ).hasMatch(asset)) {
      return Future.error(
        const FormatException('Only bundled pronunciation audio is allowed.'),
      );
    }
    final generation = ++_generation;
    return _enqueue(() async {
      if (_disposed || generation != _generation) return;
      final player = _player ??= AudioPlayer();
      _events ??= player.eventStream.listen(
        (_) {},
        onError: (Object error, StackTrace stack) {
          if (!_preparing && !_disposed) _errors.add(error);
        },
      );
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      _preparing = true;
      try {
        await player.setSource(AssetSource(asset.substring('assets/'.length)));
      } finally {
        _preparing = false;
      }
      if (_disposed || generation != _generation) return;
      await player.resume();
    });
  }

  @override
  Future<void> stop() {
    _generation++;
    return _enqueue(() async => _player?.stop());
  }

  @override
  Future<void> dispose() {
    if (_disposed) return _tail;
    _disposed = true;
    _generation++;
    return _enqueue(() async {
      try {
        await _player?.dispose();
      } finally {
        await _events?.cancel();
        _player = null;
        await _errors.close();
      }
    });
  }
}

class PronunciationAudioManager extends ChangeNotifier
    with WidgetsBindingObserver {
  PronunciationAudioManager({
    PronunciationBackend? backend,
    AssetBundle? bundle,
  }) : _backend = backend ?? BundledPronunciationBackend(),
       _bundle = bundle ?? rootBundle {
    WidgetsBinding.instance.addObserver(this);
    _playbackErrors = _backend.playbackErrors.listen((exception) {
      if (_disposed) return;
      _report(
        exception,
        StackTrace.current,
        'Audio could not play. Tap Listen to retry.',
      );
      notifyListeners();
      stop();
    });
  }

  final PronunciationBackend _backend;
  final AssetBundle _bundle;
  late final StreamSubscription<Object> _playbackErrors;
  PronunciationPack _pack = const PronunciationPack.empty();
  PronunciationPack get pack => _pack;
  bool loading = true;
  String? error;
  bool _disposed = false;
  bool _loadingStarted = false;
  bool _loadFailed = false;
  bool get loadFailed => _loadFailed;
  late bool _foreground =
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  late final NavigatorObserver navigationObserver =
      _PronunciationNavigationObserver(this);

  bool hasRecording(String text) => !loading && pack.clips.containsKey(text);

  Future<void> load() async {
    if (_disposed || (_loadingStarted && !_loadFailed)) return;
    final retry = _loadFailed;
    _loadingStarted = true;
    _loadFailed = false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (retry) _bundle.evict('assets/data/pronunciation_pack.json');
      final loaded = await PronunciationPack.load(_bundle);
      if (_disposed) return;
      _pack = loaded;
    } on FlutterError catch (exception, stack) {
      if (_disposed) return;
      _loadFailed = true;
      _report(
        exception,
        stack,
        'Pronunciation recordings could not be loaded.',
      );
    } on Exception catch (exception, stack) {
      if (_disposed) return;
      _loadFailed = true;
      _report(
        exception,
        stack,
        'Pronunciation recordings could not be loaded.',
      );
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> play(String text, {required bool isForeground}) async {
    if (_disposed || !_foreground || !isForeground) return;
    final clip = pack.clips[text];
    if (loading || clip == null) {
      error = 'A reviewed offline recording is not available for this item.';
      notifyListeners();
      return;
    }
    try {
      error = null;
      notifyListeners();
      await _backend.play(clip.asset);
    } on FlutterError catch (exception, stack) {
      if (_disposed) return;
      _report(exception, stack, 'Audio could not play. Tap Listen to retry.');
      notifyListeners();
    } on Exception catch (exception, stack) {
      if (_disposed) return;
      _report(exception, stack, 'Audio could not play. Tap Listen to retry.');
      notifyListeners();
    }
  }

  void stop() {
    if (_disposed) return;
    unawaited(_stop());
  }

  Future<void> _stop() async {
    try {
      await _backend.stop();
    } on Exception catch (exception, stack) {
      if (_disposed) return;
      _report(exception, stack, 'Audio could not be stopped.');
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) stop();
  }

  void _report(Object exception, StackTrace stack, String message) {
    error = message;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'Telugu pronunciation',
      ),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeBackend());
    super.dispose();
  }

  Future<void> _disposeBackend() async {
    try {
      try {
        await _playbackErrors.cancel();
      } finally {
        await _backend.dispose();
      }
    } on Exception catch (exception, stack) {
      _report(exception, stack, 'Audio could not be released.');
    }
  }
}

class _PronunciationNavigationObserver extends NavigatorObserver {
  _PronunciationNavigationObserver(this.audio);
  final PronunciationAudioManager audio;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      audio.stop();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      audio.stop();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      audio.stop();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      audio.stop();
}
