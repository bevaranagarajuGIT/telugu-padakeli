import 'package:flutter/foundation.dart';
import 'package:telugu_padakeli/main.dart' as app;
import 'package:telugu_padakeli/services/onboarding_store.dart';

// Home/game fixtures represent returning users; opening flow has separate tests.
class TeluguPadakeliApp extends app.TeluguPadakeliApp {
  const TeluguPadakeliApp({super.key})
    : super(
        onboardingStore: const _CompletedStore(),
        waitForFirstFrame: _frameReady,
      );
}

Future<void> _frameReady() => SynchronousFuture<void>(null);

class _CompletedStore implements OnboardingStore {
  const _CompletedStore();

  @override
  Future<bool> hasCompleted() => SynchronousFuture(true);

  @override
  Future<void> complete() async {}
}
