import 'package:flutter/material.dart';

class LargeMenuButton extends StatelessWidget {
  const LargeMenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label, textAlign: TextAlign.center),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? scheme.primaryContainer,
        foregroundColor: color == null
            ? scheme.onPrimaryContainer
            : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
    );
  }
}
