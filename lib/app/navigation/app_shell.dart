import 'package:flutter/material.dart';

import '../../screens/home_screen.dart';
import '../../screens/kids_game_screen.dart';
import '../../screens/padakeli_screen.dart';
import '../../screens/progress_screen.dart';
import '../../screens/settings_screen.dart';
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
    if (_selectedIndex != index) FocusScope.of(context).unfocus();
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) _select(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            TickerMode(
              enabled: _selectedIndex == 0 && !_settingsOpen,
              child: HomeScreen(
                hasActivePuzzle: _visited.contains(1),
                onClassic: () => _select(1),
                onLearn: () => _select(2),
                onProgress: () => _select(3),
                onSettings: _openSettings,
              ),
            ),
            _visited.contains(1)
                ? const PadakeliScreen()
                : const SizedBox.shrink(),
            _visited.contains(2)
                ? const KidsGameScreen()
                : const SizedBox.shrink(),
            _visited.contains(3)
                ? const ProgressScreen()
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
