import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/premium_telugu_text.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _DimensionalButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      primary: true,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _DimensionalButton(
      label: label,
      onPressed: onPressed,
      primary: false,
    );
  }
}

class _DimensionalButton extends StatefulWidget {
  const _DimensionalButton({
    required this.label,
    required this.onPressed,
    required this.primary,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final IconData? icon;

  @override
  State<_DimensionalButton> createState() => _DimensionalButtonState();
}

class _DimensionalButtonState extends State<_DimensionalButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(18);
    final foreground = widget.primary ? Colors.white : scheme.primary;
    final background = widget.primary ? AppColors.actionBlue : scheme.surface;
    return FocusableActionDetector(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      child: Semantics(
        button: true,
        label: widget.label,
        onTap: widget.onPressed,
        child: ExcludeSemantics(
          child: AnimatedScale(
            scale: _pressed && !reducedMotion ? 0.985 : 1,
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                color: background,
                borderRadius: radius,
                border: Border.all(
                  color: _focused
                      ? scheme.tertiary
                      : widget.primary
                      ? Colors.transparent
                      : scheme.outline,
                  width: _focused ? 3 : 1,
                ),
                boxShadow: widget.primary
                    ? [
                        BoxShadow(
                          color: AppColors.deepBlue.withValues(alpha: 0.3),
                          offset: Offset(0, _pressed ? 1 : 4),
                          blurRadius: _pressed ? 2 : 0,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  canRequestFocus: false,
                  excludeFromSemantics: true,
                  onTap: () {
                    Feedback.forTap(context);
                    widget.onPressed();
                  },
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: foreground),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: PremiumTeluguText(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
