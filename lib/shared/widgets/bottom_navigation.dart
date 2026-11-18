import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final selectedColor = scheme.brightness == Brightness.dark
        ? scheme.primary
        : AppColors.actionBlue;
    final unselectedColor = scheme.brightness == Brightness.dark
        ? scheme.onSurfaceVariant
        : AppColors.navy.withValues(alpha: 0.78);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? selectedColor
                  : unselectedColor,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => style?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? selectedColor
                  : unselectedColor,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelected,
                height: showLabels ? 80 : 72,
                elevation: 0,
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
                    icon: Icon(Icons.trending_up_rounded),
                    selectedIcon: Icon(Icons.trending_up_rounded),
                    label: 'Progress',
                  ),
                ],
              ),
              Positioned(
                left: constraints.maxWidth / 4 * (selectedIndex + 0.5) - 24,
                bottom: MediaQuery.paddingOf(context).bottom + 4,
                child: IgnorePointer(
                  child: Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
