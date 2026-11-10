import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/home_screen.dart';
import '../../screens/kids_learning_screen.dart';
import '../../screens/padakeli_screen.dart';
import '../../screens/progress_screen.dart';
import '../../screens/settings_screen.dart';
import '../../core/learning_progress.dart';
import '../../services/engagement_audio_manager.dart';
import '../../shared/widgets/bottom_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final _visited = <int>{0};
  bool _settingsOpen = false;
  bool _dailyOpen = false;
  int _resumeRequest = 0;
  int _resetRevision = 0;

  Future<void> _openDaily({String? date}) async {
    final saved = context.read<LearningProgress?>();
    setState(() => _dailyOpen = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PadakeliScreen(
            dailyDate: date ?? saved?.today ?? calendarDay(DateTime.now()),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _dailyOpen = false);
    }
  }

  void _resume() {
    final saved = context.read<LearningProgress?>();
    switch (saved?.lastDestination) {
      case 'kids' || 'practice':
        setState(() => _resumeRequest++);
        _select(2);
      case 'daily':
        _openDaily(date: saved?.lastDailyDate);
      default:
        _select(1);
    }
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    } finally {
      if (mounted) setState(() => _settingsOpen = false);
    }
  }

  void _select(int index) {
    if (_selectedIndex != index) {
      context.read<EngagementAudioManager?>()?.stop();
      FocusScope.of(context).unfocus();
    }
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<LearningProgress?>();
    if (saved != null && saved.resetRevision != _resetRevision) {
      _resetRevision = saved.resetRevision;
      _selectedIndex = 0;
      _visited
        ..clear()
        ..add(0);
    }
    return PopScope<Object?>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) _select(0);
      },
      child: Scaffold(
        body: IndexedStack(
          key: ValueKey(_resetRevision),
          index: _selectedIndex,
          children: [
            TickerMode(
              enabled: _selectedIndex == 0 && !_settingsOpen && !_dailyOpen,
              child: HomeScreen(
                hasActivePuzzle: saved?.hasClassic ?? false,
                hasSavedLearning: saved?.lastDestination != null,
                storageNotice: saved?.storageError ?? saved?.recoveryNotice,
                onClassic: () => _select(1),
                onLearn: () => _select(2),
                onProgress: () => _select(3),
                onSettings: _openSettings,
                onDaily: _openDaily,
                onResume: _resume,
              ),
            ),
            _visited.contains(1)
                ? TickerMode(
                    enabled:
                        _selectedIndex == 1 && !_settingsOpen && !_dailyOpen,
                    child: PadakeliScreen(onBack: () => _select(0)),
                  )
                : const SizedBox.shrink(),
            _visited.contains(2)
                ? TickerMode(
                    enabled:
                        _selectedIndex == 2 && !_settingsOpen && !_dailyOpen,
                    child: KidsLearningScreen(
                      onBack: () => _select(0),
                      resumeRequest: _resumeRequest,
                    ),
                  )
                : const SizedBox.shrink(),
            _visited.contains(3)
                ? TickerMode(
                    enabled:
                        _selectedIndex == 3 && !_settingsOpen && !_dailyOpen,
                    child: ProgressScreen(
                      onResume: _resume,
                      onLearn: () => _select(2),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: BottomNavigation(
          selectedIndex: _selectedIndex,
          onSelected: _select,
        ),
      ),
    );
  }
}
