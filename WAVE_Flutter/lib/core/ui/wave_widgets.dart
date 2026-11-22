import 'package:flutter/material.dart';
import '../theme/wave_theme.dart';
import '../theme/wave_design_tokens.dart';
import 'wave_background.dart';

/// Approved Component 03: white, circular Pearl Raised icon treatment.
/// All icons remain decorative unless their parent owns the interaction.
class WavePearlIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool active;
  final Color? color;
  const WavePearlIcon({super.key, required this.icon, this.size = 48,
    this.active = false, this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: WaveDesignTokens.pearlGradient,
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: WaveDesignTokens.pearlShadows,
    ),
    child: Icon(icon,
      color: color ?? WaveColors.deepTeal,
      size: size * .51,
    ),
  );
}

/// Approved 02 Halo Card / softly raised universal content surface.
/// Keeps every existing `onTap` and layout/height contract intact.
class WaveGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final List<Color>? colors;
  final double radius;
  final VoidCallback? onTap;
  final double? height;
  const WaveGlassCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(18), this.colors,
    this.radius = WaveDesignTokens.cardRadius, this.onTap, this.height});

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: colors == null
                ? WaveDesignTokens.cardGradient
                : LinearGradient(begin: Alignment.topLeft,
                  end: Alignment.bottomRight, colors: colors!),
            border: Border.all(color: Colors.white.withValues(alpha: .96), width: 1.5),
            borderRadius: shape,
            boxShadow: WaveDesignTokens.cardShadows,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: shape,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Approved 01 Turquoise + White neumorphic pill. Brighter aqua remains in
/// ornamental surfaces; the white CTA text uses contrast-compliant dark teal.
class WavePrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool destructive;
  const WavePrimaryButton({super.key, required this.title,
    required this.onPressed, this.icon, this.outlined = false,
    this.destructive = false});

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.arrow_forward_rounded),
          label: Text(title, textAlign: TextAlign.center),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: const StadiumBorder(),
          ),
        ),
      );
    }
    final enabled = onPressed != null;
    final fill = destructive
      ? const LinearGradient(colors: [Color(0xFFB82B3D), Color(0xFF912434)])
      : WaveDesignTokens.accessibleActionGradient;
    return SizedBox(
      width: double.infinity,
      child: Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? fill : const LinearGradient(
                colors: [Color(0xFFE0EAE9), Color(0xFFD4E0DF)]),
            borderRadius: BorderRadius.circular(WaveDesignTokens.pillRadius),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: enabled ? WaveDesignTokens.pearlShadows : null,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(WaveDesignTokens.pillRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                child: Row(
                  children: [
                    WavePearlIcon(
                      icon: icon ?? Icons.waves_rounded,
                      size: 39, color: enabled ? WaveColors.deepTeal : WaveColors.muted),
                    const SizedBox(width: 7),
                    Expanded(child: Text(title, textAlign: TextAlign.center,
                      style: TextStyle(color: enabled ? Colors.white : WaveColors.muted,
                        fontSize: 14, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 7),
                    const WavePearlIcon(icon: Icons.arrow_forward_rounded, size: 39),
                  ],
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

/// Approved status feedback: strong foreground and a separate semantic dot.
class WaveStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const WaveStatusBadge(this.text, {super.key, this.color = WaveColors.success});
  @override
  Widget build(BuildContext context) {
    final readableColor = color.computeLuminance() > .18
        ? WaveColors.deepTeal : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: WaveDesignTokens.pearlGradient,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white, width: 1.3),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .48),
          child: Text(text, softWrap: true, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w800, color: readableColor))),
      ]),
    );
  }
}

/// Approved 16 Capsule Command Bar. Original callbacks, back navigation and
/// brand image assets are passed through unmodified.
class WaveTopBar extends StatelessWidget {
  final String? title;
  final bool showProfile;
  final bool back;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  const WaveTopBar({super.key, this.title, this.showProfile = false,
    this.back = false, this.onBack, this.onProfile});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 57),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    decoration: BoxDecoration(
      gradient: WaveDesignTokens.pearlGradient,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: WaveDesignTokens.pearlShadows,
    ),
    child: Row(mainAxisSize: MainAxisSize.max, children: [
      if (back) ...[
        _WaveRoundAction(icon: Icons.arrow_back_ios_new_rounded,
          label: 'Back', onTap: onBack ?? () => Navigator.maybePop(context)),
        const SizedBox(width: 9),
      ],
      if (title == null) ...[
        Image.asset('assets/images/wave_icon.png', width: 39, height: 39),
        const SizedBox(width: 7),
        Flexible(child: Image.asset('assets/images/wave_wordmark.png',
          width: 120, height: 38, fit: BoxFit.contain)),
      ] else
        Expanded(child: Text(title!, maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: WaveColors.ink,
            fontSize: 18, fontWeight: FontWeight.w800))),
      if (title == null) const Spacer(),
      if (showProfile) _WaveRoundAction(icon: Icons.person_rounded,
        label: 'Settings', onTap: onProfile),
    ]),
  );
}

class _WaveRoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _WaveRoundAction({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onTap,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    icon: WavePearlIcon(icon: icon, size: 39),
  );
}

class WavePage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final bool back;
  final Widget? trailing;
  const WavePage({super.key, required this.title, this.subtitle,
    this.children = const [], this.footer, this.back = true, this.trailing});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: WaveBackground(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(children: [
              Expanded(child: WaveTopBar(title: title, back: back)),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ]),
          ),
          if (subtitle != null)
            Padding(padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Align(alignment: Alignment.centerLeft,
                child: Text(subtitle!, style: const TextStyle(
                  color: WaveColors.muted, fontSize: 13)))),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            children: children,
          )),
          if (footer != null)
            Padding(padding: const EdgeInsets.fromLTRB(20, 5, 20, 18),
              child: footer!),
        ]),
      ),
    ),
  );
}

/// Approved 13,18,19,23,24 capsule row: reuse for discovery, devices, settings,
/// permissions, session entries, source options and (when implemented) billing.
class WaveOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;
  const WaveOptionTile({super.key, required this.title,
    required this.subtitle, required this.icon, this.onTap,
    this.selected = false, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: WaveGlassCard(
      radius: WaveDesignTokens.pillRadius,
      onTap: onTap,
      colors: selected
          ? const [Color(0xFFD9FCF7), Color(0xFFB8F2E9)]
          : const [Colors.white, Color(0xFFE8FAF7)],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 49),
        child: Row(children: [
          WaveIconTile(icon: icon, active: selected),
          const SizedBox(width: 13),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: WaveColors.deepTeal,
                fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(
                color: WaveColors.muted, fontSize: 12, height: 1.35)),
            ],
          )),
          const SizedBox(width: 5),
          trailing ?? (onTap == null ? const SizedBox.shrink() :
            Icon(selected ? Icons.check_circle_rounded :
              Icons.chevron_right_rounded,
              color: WaveColors.deepTeal, size: 24)),
        ]),
      ),
    ),
  );
}

class WaveIconTile extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color? color;
  const WaveIconTile({super.key, required this.icon,
    this.active = false, this.color});
  @override
  Widget build(BuildContext context) => WavePearlIcon(
    icon: icon, active: active, color: color, size: 49);
}

class WaveLabel extends StatelessWidget {
  final String text;
  const WaveLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 6),
    child: Text(text, style: const TextStyle(fontSize: 17,
      fontWeight: FontWeight.w800, color: WaveColors.ink)),
  );
}

class WaveNote extends StatelessWidget {
  final String text;
  const WaveNote(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      gradient: WaveDesignTokens.pearlGradient,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 1.4),
      boxShadow: WaveDesignTokens.cardShadows,
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const WavePearlIcon(icon: Icons.info_outline_rounded, size: 40),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
        style: const TextStyle(color: WaveColors.muted,
          fontSize: 12, height: 1.45))),
    ]),
  );
}

class WaveField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  const WaveField({super.key, required this.controller,
    required this.label, this.hint, this.keyboardType});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 5, right: 6),
          child: WavePearlIcon(icon: Icons.edit_outlined, size: 40),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 48),
      ),
    ),
  );
}

class WaveMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const WaveMetric({super.key, required this.label,
    required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      WavePearlIcon(icon: icon, size: 39),
      const SizedBox(height: 7),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: WaveColors.ink,
          fontWeight: FontWeight.w800, fontSize: 13)),
      Text(label, textAlign: TextAlign.center,
        style: const TextStyle(color: WaveColors.muted, fontSize: 12)),
    ]),
  );
}

class WaveEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const WaveEmptyState({super.key, required this.icon,
    required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => WaveGlassCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 5),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(17),
          decoration: const BoxDecoration(color: Color(0xFFDDF8F2),
            shape: BoxShape.circle),
          child: WavePearlIcon(icon: icon, size: 63)),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center,
          style: const TextStyle(color: WaveColors.ink,
            fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(color: WaveColors.muted,
            fontSize: 13, height: 1.45)),
      ]),
    ),
  );
}

/// Optional status representation for any flow that already has a loading state.
/// No timers/services/network activities are started by this widget.
class WaveLiquidSignal extends StatelessWidget {
  final String label;
  final double? progress;
  const WaveLiquidSignal({super.key, required this.label, this.progress});
  @override
  Widget build(BuildContext context) => WaveGlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const WavePearlIcon(icon: Icons.graphic_eq_rounded, size: 39),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(
          color: WaveColors.deepTeal, fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 14),
      ClipRRect(borderRadius: BorderRadius.circular(100),
        child: LinearProgressIndicator(value: progress, minHeight: 6)),
    ]),
  );
}

/// Floating capsule status / settings / billing surface without inventing
/// payments, account entitlement, balance, or existing app routes.
class WaveCapsulePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const WaveCapsulePanel({super.key, required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11)});
  @override
  Widget build(BuildContext context) => WaveGlassCard(
    radius: 30, padding: padding,
    child: child,
  );
}

class WaveGlassBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const WaveGlassBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onSelected,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.headphones_rounded),
        label: 'Audio',
      ),
      NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
      NavigationDestination(
        icon: Icon(Icons.sensors_rounded),
        label: 'Sessions',
      ),
    ],
  );
}

void waveToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
    ),
  );
}

Future<bool> confirmWaveAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
