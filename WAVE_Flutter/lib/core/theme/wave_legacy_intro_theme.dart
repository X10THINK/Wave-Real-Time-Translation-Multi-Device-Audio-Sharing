import 'package:flutter/material.dart';

abstract final class WaveLegacyColors {
  static const ink = Color(0xFF101732);
  static const muted = Color(0xFF55647B);
  static const deepTeal = Color(0xFF00686C);
  static const teal = Color(0xFF00A8A3);
  static const turquoise = Color(0xFF03D9D2);
  static const icy = Color(0xFFE8FAFD);
  static const lightAqua = Color(0xFFAFF8F4);
  static const blue = Color(0xFFB9E9FF);
  static const lavender = Color(0xFFE9E7FF);
  static const purple = Color(0xFF6252D7);
  static const success = Color(0xFF11A972);
  static const danger = Color(0xFFE84C55);
  static const warning = Color(0xFFCC8731);
}

ThemeData waveLegacyOnboardingTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: WaveLegacyColors.teal,
    brightness: Brightness.light,
    primary: WaveLegacyColors.deepTeal,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: WaveLegacyColors.icy,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 31,
        color: Color(0xFF101732),
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        color: Color(0xFF101732),
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        color: Color(0xFF101732),
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        color: Color(0xFF101732),
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: Color(0xFF101732)),
      bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF55647B), height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .82),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD0F1F1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: WaveLegacyColors.teal, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF55647B)),
    ),
  );
}
