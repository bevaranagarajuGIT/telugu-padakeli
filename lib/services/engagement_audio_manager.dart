import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_settings_controller.dart';

enum EngagementCue { correct, retry, completion, reward }

/// A future backend must use only approved bundled audio and cancel pending
/// starts as well as active playback when stop or dispose is called.
abstract interface class EngagementAudioBackend {
  bool get hasApprovedAssets;
  Future<void> play(EngagementCue cue);
  Future<void> stop();
  Future<void> dispose();
}

class SilentEngagementAudioBackend implements EngagementAudioBackend {
  const SilentEngagementAudioBackend();

  @override
  bool get hasApprovedAssets => false;

  @override
  Future<void> play(EngagementCue cue) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class EngagementAudioManager with WidgetsBindingObserver {
  EngagementAudioManager(
    this.settings, {
    this.backend = const SilentEngagementAudioBackend(),
  }) {
    _soundEnabled = settings.soundEnabled;
    _foreground = _appIsForeground;
    settings.addListener(_settingsChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  final AppSettingsController settings;
  final EngagementAudioBackend backend;
  late final NavigatorObserver navigationObserver = _AudioNavigationObserver(
    this,
  );
  late bool _soundEnabled;
  late bool _foreground;
  bool _disposed = false;
  int _generation = 0;

  bool get _appIsForeground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  bool get _canPlay =>
      !_disposed && _foreground && _soundEnabled && backend.hasApprovedAssets;

  void play(EngagementCue cue, {required bool isForeground}) {
    if (!isForeground || !_canPlay) return;
    final generation = ++_generation;
    unawaited(_play(cue, generation));
  }

  Future<void> _play(EngagementCue cue, int generation) async {
    try {
      await backend.stop();
      if (!_canPlay || generation != _generation) return;
      await backend.play(cue);
    } on Exception catch (error, stack) {
      _report(error, stack);
    }
  }

  void stop() {
    if (_disposed) return;
    _generation++;
    unawaited(_stop());
  }

  Future<void> _stop() async {
    try {
      await backend.stop();
    } on Exception catch (error, stack) {
      _report(error, stack);
    }
  }

  void _settingsChanged() {
    if (_soundEnabled == settings.soundEnabled) return;
    _soundEnabled = settings.soundEnabled;
    if (!_soundEnabled) stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) stop();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    settings.removeListener(_settingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeBackend());
  }

  Future<void> _disposeBackend() async {
    try {
      try {
        await backend.stop();
      } finally {
        await backend.dispose();
      }
    } on Exception catch (error, stack) {
      _report(error, stack);
    }
  }

  void _report(Exception error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Engagement audio',
      ),
    );
  }
}

class _AudioNavigationObserver extends NavigatorObserver {
  _AudioNavigationObserver(this.audio);
  final EngagementAudioManager audio;

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
