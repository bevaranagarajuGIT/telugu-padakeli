import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/navigation/app_launch_gate.dart';
import 'core/app_settings_controller.dart';
import 'core/app_theme.dart';
import 'core/learning_progress.dart';
import 'services/learning_store.dart';
import 'services/onboarding_store.dart';
import 'services/engagement_audio_manager.dart';
import 'services/pronunciation_audio_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = LearningProgress(PreferencesLearningStore());
  await progress.load();
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
    final vocabularyNotice = await rootBundle.loadString(
      'assets/artwork/kids/ATTRIBUTION.txt',
    );
    yield LicenseEntryWithLineBreaks([
      'Original vocabulary illustrations',
    ], vocabularyNotice);
  });
  runApp(TeluguPadakeliApp(progress: progress));
}

class TeluguPadakeliApp extends StatelessWidget {
  const TeluguPadakeliApp({
    this.onboardingStore = const PreferencesOnboardingStore(),
    this.waitForFirstFrame = waitForLaunchFrame,
    this.progress,
    super.key,
  });

  final OnboardingStore onboardingStore;
  final Future<void> Function() waitForFirstFrame;
  final LearningProgress? progress;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              progress ??
              LearningProgress(MemoryLearningStore(), autoSave: false),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AppSettingsController(progress: context.read<LearningProgress>()),
        ),
        Provider(
          create: (context) =>
              EngagementAudioManager(context.read<AppSettingsController>()),
          dispose: (_, audio) => audio.dispose(),
        ),
        ChangeNotifierProvider(
          create: (_) => PronunciationAudioManager()..load(),
        ),
      ],
      child: _PersistenceLifecycle(
        child: Consumer<AppSettingsController>(
          builder: (context, settings, _) {
            return MaterialApp(
              title: 'Telugu Padakeli',
              debugShowCheckedModeBanner: false,
              navigatorObservers: [
                context.read<EngagementAudioManager>().navigationObserver,
                context.read<PronunciationAudioManager>().navigationObserver,
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
      ),
    );
  }
}

class _PersistenceLifecycle extends StatefulWidget {
  const _PersistenceLifecycle({required this.child});
  final Widget child;

  @override
  State<_PersistenceLifecycle> createState() => _PersistenceLifecycleState();
}

class _PersistenceLifecycleState extends State<_PersistenceLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(context.read<LearningProgress>().flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
