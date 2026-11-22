import 'package:flutter/material.dart';

/// FINAL LOCKED WAVE visual primitives. Only the approved contrast treatment
/// changes foreground tones; never change route/business/audio behavior here.
abstract final class WaveDesignTokens {
  static const Color pearl = Color(0xFFFFFFFF);
  static const Color icePearl = Color(0xFFE4F9F6);
  static const Color pearlStroke = Color(0xFFFFFFFF);
  static const Color quietStroke = Color(0xFFCCEAE5);
  static const Color accessibleSecondary = Color(0xFF47676B);
  static const Color actionDark = Color(0xFF00686C);
  static const Color actionMid = Color(0xFF007C78);

  static const double pillRadius = 100;
  static const double cardRadius = 28;
  static const double minimumTouch = 48;
  static const double contentGap = 16;

  static const LinearGradient pearlGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pearl, icePearl],
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDFEFF), Color(0xFFE8FAF7)],
  );
  // The user approved contrast-only correction. White text over the brighter
  // turquoise/teal originals did not reach 4.5:1. Preserve the aqua identity
  // via the surrounding surfaces and use a darker teal CTA beneath white text.
  static const LinearGradient accessibleActionGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [actionMid, actionDark],
  );
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF03D9D2), Color(0xFF00A8A3)],
  );

  static List<BoxShadow> get pearlShadows => [
    BoxShadow(
      color: const Color(0xFF00686C).withValues(alpha: 0.15),
      blurRadius: 13,
      offset: const Offset(4, 6),
    ),
    const BoxShadow(
      color: Color(0xCCFFFFFF),
      blurRadius: 8,
      offset: Offset(-3, -3),
    ),
  ];
  static List<BoxShadow> get cardShadows => [
    BoxShadow(
      color: const Color(0xFF00686C).withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    const BoxShadow(
      color: Color(0xB3FFFFFF),
      blurRadius: 9,
      offset: Offset(-4, -4),
    ),
  ];
}
