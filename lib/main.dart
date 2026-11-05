import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/navigation/app_shell.dart';
import 'core/app_settings_controller.dart';
import 'core/app_theme.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Noto Sans Telugu'], license);
    final robotoLicense = await rootBundle.loadString(
      'assets/fonts/Roboto-LICENSE.txt',
    );
    yield LicenseEntryWithLineBreaks(['Roboto'], robotoLicense);
  });
  runApp(const TeluguPadakeliApp());
}

class TeluguPadakeliApp extends StatelessWidget {
  const TeluguPadakeliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSettingsController(),
      child: Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Telugu Padakeli',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(settings.fontScale),
            darkTheme: AppTheme.dark(settings.fontScale),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
