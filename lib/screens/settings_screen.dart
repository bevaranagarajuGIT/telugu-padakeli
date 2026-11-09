import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_settings_controller.dart';
import '../widgets/app_page.dart';
import '../widgets/section_title.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    return AppPage(
      title: 'సెట్టింగ్స్',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('అక్షర పరిమాణం'),
                  RadioGroup<TeluguFontSize>(
                    groupValue: settings.fontSize,
                    onChanged: (size) {
                      if (size != null) settings.setFontSize(size);
                    },
                    child: Column(
                      children: [
                        for (final size in TeluguFontSize.values)
                          RadioListTile<TeluguFontSize>(
                            value: size,
                            title: Text(size.label),
                            contentPadding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text('డార్క్ మోడ్'),
              subtitle: const Text('కళ్లకు సౌకర్యమైన రంగులు'),
              value: settings.darkMode,
              onChanged: settings.setDarkMode,
            ),
          ),
          const SizedBox(height: 22),
          Card(
            child: SwitchListTile(
              key: const ValueKey('english-helper-setting'),
              title: const Text('ఇంగ్లీష్ సహాయం — English Helper'),
              subtitle: const Text(
                'పిల్లల ఆటల్లో తెలుగు కింద చిన్న ఇంగ్లీష్ వివరణలు',
              ),
              value: settings.englishHelper,
              onChanged: settings.setEnglishHelper,
            ),
          ),
          const SizedBox(height: 22),
          Card(
            child: SwitchListTile(
              key: const ValueKey('sound-setting'),
              title: const Text('శబ్దం'),
              subtitle: const Text(
                'ప్రస్తుతం శబ్దాలు లేవు. అనుమతి ఉన్న శబ్దాలు '
                'జోడించిన తర్వాత ఈ సెట్టింగ్ పని చేస్తుంది.',
              ),
              value: settings.soundEnabled,
              onChanged: settings.setSoundEnabled,
            ),
          ),
          const SizedBox(height: 22),
          TextButton.icon(
            key: const ValueKey('licenses-setting'),
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Telugu Padakeli',
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('చిత్రాలు, లైసెన్సులు'),
          ),
          const SizedBox(height: 16),
          Text(
            'రోజువారీ పదకేళి, అభ్యాస పురోగతి త్వరలో వస్తాయి. '
            'ఈ దశలో సెట్టింగ్స్ యాప్ తెరిచి ఉన్నంతవరకే ఉంటాయి.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
