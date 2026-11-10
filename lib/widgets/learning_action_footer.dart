import 'package:flutter/material.dart';

class LearningActionFooter extends StatelessWidget {
  const LearningActionFooter({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('learning-action-footer'),
    color: Theme.of(context).colorScheme.surface,
    elevation: 8,
    child: SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.36,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    ),
  );
}
