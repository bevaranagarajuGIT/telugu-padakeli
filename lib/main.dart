import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/navigation/app_launch_gate.dart';
import 'core/app_settings_controller.dart';
import 'core/app_theme.dart';
import 'services/onboarding_store.dart';
import 'services/engagement_audio_manager.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Noto Sans Telugu'], license);
    final robotoLicense = await rootBundle.loadString(
      'assets/fonts/Roboto-LICENSE.txt',
    );
    yield LicenseEntryWithLineBreaks(['Roboto'], robotoLicense);
    final artworkLicense = await rootBundle.loadString(
      'assets/artwork/opening/ATTRIBUTION.txt',
    );
    yield LicenseEntryWithLineBreaks([
      'Opening illustrations',
      'App icon',
    ], artworkLicense);
  });
  runApp(const TeluguPadakeliApp());
}

class TeluguPadakeliApp extends StatelessWidget {
  const TeluguPadakeliApp({
    this.onboardingStore = const PreferencesOnboardingStore(),
    this.waitForFirstFrame = waitForLaunchFrame,
    super.key,
  });

  final OnboardingStore onboardingStore;
  final Future<void> Function() waitForFirstFrame;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsController()),
        Provider(
          create: (context) =>
              EngagementAudioManager(context.read<AppSettingsController>()),
          dispose: (_, audio) => audio.dispose(),
        ),
      ],
      child: Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Telugu Padakeli',
            debugShowCheckedModeBanner: false,
            navigatorObservers: [
              context.read<EngagementAudioManager>().navigationObserver,
            ],
            theme: AppTheme.light(settings.fontScale),
            darkTheme: AppTheme.dark(settings.fontScale),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: AppLaunchGate(
              store: onboardingStore,
              waitForFirstFrame: waitForFirstFrame,
            ),
          );
        },
      ),
    );
  }
}
