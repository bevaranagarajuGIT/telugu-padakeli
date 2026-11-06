import 'dart:async';

import 'package:flutter/material.dart';

import '../../screens/padakeli_onboarding_screen.dart';
import '../../screens/padakeli_splash_screen.dart';
import '../../services/onboarding_store.dart';
import '../../shared/widgets/opening_artwork.dart';
import 'app_shell.dart';

Future<void> waitForLaunchFrame() =>
    WidgetsBinding.instance.waitUntilFirstFrameRasterized;

class AppLaunchGate extends StatefulWidget {
  const AppLaunchGate({
    required this.store,
    this.waitForFirstFrame = waitForLaunchFrame,
    super.key,
  });

  final OnboardingStore store;
  final Future<void> Function() waitForFirstFrame;

  @override
  State<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<AppLaunchGate> {
  final _splashEntered = Completer<void>();
  bool? _completed;
  bool _started = false;
  bool _saving = false;
  bool _entranceReady = false;
  String? _readError;
  String? _saveError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initialize();
      });
    }
  }

  Future<void> _precache(String asset) async {
    Object? failure;
    await precacheImage(
      ResizeImage.resizeIfNeeded(960, null, AssetImage(asset)),
      context,
      onError: (error, stack) => failure = error,
    );
    if (failure != null) throw failure!;
  }

  Future<void> _initialize() async {
    setState(() => _readError = null);
    try {
      await widget.waitForFirstFrame();
      if (!mounted) return;
      setState(() => _entranceReady = true);
      final completed = await widget.store.hasCompleted();
      if (!mounted) return;
      if (!completed) {
        await Future.wait([
          _precache(openingTempleAsset),
          _precache(openingFamilyAsset),
        ]);
        if (!mounted) return;
        // Paint the decoded splash artwork before transitioning, without a timer.
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted) return;
      if (!MediaQuery.disableAnimationsOf(context)) {
        await _splashEntered.future;
      }
      if (mounted) setState(() => _completed = completed);
    } catch (error, stack) {
      debugPrint('Opening initialization failed: $error\n$stack');
      if (mounted) {
        setState(() {
          _readError = 'యాప్ తెరవలేకపోయాము. మళ్లీ ప్రయత్నించండి.';
        });
      }
    }
  }

  Future<void> _complete() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.store.complete();
      if (mounted) setState(() => _completed = true);
    } catch (error, stack) {
      debugPrint('Onboarding completion could not be saved: $error\n$stack');
      if (mounted) {
        setState(() {
          _saveError = 'మీ ఎంపికను దాచలేకపోయాము. మళ్లీ ప్రయత్నించండి.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget screen;
    if (_completed == null) {
      screen = PadakeliSplashScreen(
        error: _readError,
        onRetry: _initialize,
        animateEntrance: _entranceReady,
        onEntered: () {
          if (!_splashEntered.isCompleted) _splashEntered.complete();
        },
      );
    } else if (_completed!) {
      screen = const AppShell();
    } else {
      screen = PadakeliOnboardingScreen(
        onComplete: _complete,
        busy: _saving,
        error: _saveError,
      );
    }
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      child: screen,
    );
  }
}
