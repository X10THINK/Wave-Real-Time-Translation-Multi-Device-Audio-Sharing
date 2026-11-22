import 'package:flutter/material.dart';
import '../theme/wave_theme.dart';

// WAVE components 05/22 are SKIPPED. These exact V6.3.1 widget renderers are
// retained solely by onboarding to avoid accidental theme migration.
// Their original onPressed/onTap behavior remains untouched.

class WaveLegacyGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final List<Color>? colors;
  final double radius;
  final VoidCallback? onTap;
  final double? height;
  const WaveLegacyGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.colors,
    this.radius = 27,
    this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              colors ??
              [
                Colors.white.withValues(alpha: .87),
                const Color(0xFFE5FEFF).withValues(alpha: .75),
              ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: .92),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: WaveColors.deepTeal.withValues(alpha: .09),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class WaveLegacyPrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool destructive;
  const WaveLegacyPrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFA82232) : WaveColors.deepTeal;
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 54)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 8)],
        Flexible(child: Text(title, textAlign: TextAlign.center)),
      ],
    );
    return SizedBox(
      width: double.infinity,
      child:
          outlined
              ? OutlinedButton(
                onPressed: onPressed,
                style: style,
                child: content,
              )
              : FilledButton(
                onPressed: onPressed,
                style: style.copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) =>
                        states.contains(WidgetState.disabled)
                            ? const Color(0xFFD7DEE2)
                            : color,
                  ),
                ),
                child: content,
              ),
    );
  }
}
