import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final style = NavigationBarTheme.of(context).labelTextStyle?.resolve({});
    final showLabels =
        MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 12) <= 18;
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      height: showLabels ? 80 : 72,
      labelBehavior: showLabels
          ? NavigationDestinationLabelBehavior.alwaysShow
          : NavigationDestinationLabelBehavior.alwaysHide,
      destinations: const [
        NavigationDestination(
          key: ValueKey('nav-home'),
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          key: ValueKey('nav-classic'),
          icon: Icon(Icons.grid_on_outlined),
          selectedIcon: Icon(Icons.grid_on_rounded),
          label: 'Classic',
        ),
        NavigationDestination(
          key: ValueKey('nav-learn'),
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school_rounded),
          label: 'Learn',
        ),
        NavigationDestination(
          key: ValueKey('nav-progress'),
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Progress',
        ),
      ],
    );
  }
}
