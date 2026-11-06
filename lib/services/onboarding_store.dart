import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingStore {
  Future<bool> hasCompleted();
  Future<void> complete();
}

class PreferencesOnboardingStore implements OnboardingStore {
  const PreferencesOnboardingStore();

  static const completionKey = 'onboarding_completed_v1';

  @override
  Future<bool> hasCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completionKey) ?? false;
  }

  @override
  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(completionKey, true)) {
      throw StateError('Could not save onboarding completion.');
    }
  }
}
