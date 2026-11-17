import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_settings_controller.dart';
import '../core/learning_progress.dart';
import '../services/pronunciation_audio_manager.dart';
import '../widgets/app_page.dart';
import '../widgets/section_title.dart';
import '../services/diagnostics.dart';
import 'report_problem_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Diagnostics? _diagnostics;
  DiagnosticScreen? _previousScreen;
  int? _previousLevel;
  bool _diagnosticBusy = false;

  @override
  void initState() {
    super.initState();
    _diagnostics = context.read<Diagnostics?>();
    _previousScreen = _diagnostics?.screen;
    _previousLevel = _diagnostics?.level;
    _diagnostics?.location(DiagnosticScreen.settings);
  }

  @override
  void dispose() {
    if (_previousScreen != null) {
      _diagnostics?.location(_previousScreen!, level: _previousLevel);
    }
    super.dispose();
  }

  Future<void> _diagnosticAction(Future<void> Function() action) async {
    setState(() => _diagnosticBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _diagnosticBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final progress = context.watch<LearningProgress?>();
    final pronunciation = context.watch<PronunciationAudioManager?>();
    final diagnostics = context.watch<Diagnostics?>();
    return AppPage(
      title: 'సెట్టింగ్స్',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'మీకు అనువైన అభ్యాసం',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your preferences and progress stay on this device. '
            'No account or network is needed.',
          ),
          const SizedBox(height: 20),
          if (diagnostics != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('సహాయం / Help'),
                    const SizedBox(height: 8),
                    const Text(
                      'సమస్యను వివరించి, పంపే ముందు నివేదిక చూడండి.\n'
                      'Describe a problem and review your report before sharing. '
                      'No automatic uploads or analytics.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('report-problem-setting'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ReportProblemScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text(
                        'సమస్యను తెలియజేయండి / Report a problem',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      key: const ValueKey('diagnostics-setting'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('స్థానిక చరిత్ర / Local diagnostics'),
                      subtitle: const Text(
                        'Up to 100 screen/level and error-category events for '
                        '7 days on this device. No answers or personal details. '
                        'Turning off clears history; sharing is always optional.',
                      ),
                      value: diagnostics.enabled,
                      onChanged: _diagnosticBusy || !diagnostics.available
                          ? null
                          : (value) => _diagnosticAction(
                              () => diagnostics.setEnabled(value),
                            ),
                    ),
                    OutlinedButton(
                      key: const ValueKey('diagnostics-clear'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _diagnosticBusy
                          ? null
                          : () => _diagnosticAction(diagnostics.clear),
                      child: const Text(
                        'చరిత్ర తొలగించు / Clear diagnostic history',
                      ),
                    ),
                    if (diagnostics.storageError != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          diagnostics.storageError!,
                          key: const ValueKey('diagnostics-error'),
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('diagnostics-retry'),
                        onPressed: _diagnosticBusy
                            ? null
                            : () => _diagnosticAction(diagnostics.retry),
                        child: const Text(
                          'మళ్లీ ప్రయత్నించండి / Retry diagnostics',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
              title: const Text('శబ్దం / Reward sound preference'),
              subtitle: const Text(
                'ప్రస్తుతం శబ్దాలు లేవు. అనుమతి ఉన్న శబ్దాలు '
                'జోడించిన తర్వాత ఈ సెట్టింగ్ పని చేస్తుంది.',
              ),
              value: settings.soundEnabled,
              onChanged: settings.setSoundEnabled,
            ),
          ),
          const SizedBox(height: 22),
          if (progress != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int>(
                  key: const ValueKey('daily-goal-setting'),
                  initialValue: progress.dailyGoal,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'రోజువారీ లక్ష్యం / Daily goal',
                    helperText: 'Distinct correct questions per local day.',
                    helperMaxLines: 3,
                  ),
                  items: [
                    for (var goal = 1; goal <= 10; goal++)
                      DropdownMenuItem(
                        value: goal,
                        child: Text('$goal ప్రశ్నలు / questions'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) progress.setSetting('dailyGoal', value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (progress.storageError != null ||
                progress.recoveryNotice != null) ...[
              Text(
                progress.storageError ?? progress.recoveryNotice!,
                key: const ValueKey('storage-status'),
              ),
              if (progress.canRetrySave)
                TextButton.icon(
                  onPressed: progress.flush,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Retry saving / మళ్లీ సేవ్ చేయి'),
                ),
            ],
            OutlinedButton.icon(
              key: const ValueKey('reset-progress-setting'),
              onPressed: () => _reset(context, progress),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('అభ్యాస పురోగతి తొలగించు / Reset progress'),
            ),
            const SizedBox(height: 16),
          ],
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
            pronunciation?.error ??
                (pronunciation?.loading == true
                    ? 'ఉచ్చారణ / Pronunciation: checking offline recordings.'
                    : pronunciation != null &&
                          pronunciation.pack.clips.isNotEmpty
                    ? 'ఉచ్చారణ / Pronunciation: '
                          '${pronunciation.pack.clips.length} reviewed offline '
                          'recordings. Tap Listen or Replay in Kids activities. '
                          'Listening is manual and separate from reward sounds.'
                    : 'మానవ సమీక్ష చేసిన ఉచ్చారణ రికార్డింగులు ఇంకా లేవు.\n'
                          'Pronunciation is unavailable. Native-speaker '
                          'recordings are pending; no approved audio files '
                          'are bundled yet.'),
            key: const ValueKey('pronunciation-status'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (pronunciation?.loadFailed == true)
            TextButton.icon(
              key: const ValueKey('pronunciation-retry'),
              onPressed: pronunciation!.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('మళ్లీ ప్రయత్నించండి / Retry recordings'),
            ),
          const SizedBox(height: 8),
          Text(
            'Reward sound is a saved preference, not working playback. '
            'Pronunciation never plays automatically and needs no microphone '
            'or network.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _reset(BuildContext context, LearningProgress progress) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('పురోగతి తొలగించాలా? / Reset progress?'),
        content: const Text(
          'Saved answers, completions, stars, daily boards and '
          'learning records will be cleared on this device. '
          'Settings and the completed Welcome are kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('reset-progress-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('వద్దు / Cancel'),
          ),
          FilledButton(
            key: const ValueKey('reset-progress-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('తొలగించు / Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    progress.resetProgress();
    await progress.flush();
    if (context.mounted && progress.storageError == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
