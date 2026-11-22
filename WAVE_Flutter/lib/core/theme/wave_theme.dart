import 'package:flutter/material.dart';
import 'wave_design_tokens.dart';

abstract final class WaveColors {
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

ThemeData waveTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: WaveColors.teal,
    brightness: Brightness.light,
    primary: WaveColors.deepTeal,
    onPrimary: Colors.white,
    surface: Colors.white,
  );
  final capsule = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(WaveDesignTokens.pillRadius),
  );
  final pearlCapsule = OutlineInputBorder(
    borderRadius: BorderRadius.circular(WaveDesignTokens.pillRadius),
    borderSide: const BorderSide(color: WaveDesignTokens.quietStroke),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: WaveColors.icy,
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 31, color: WaveColors.ink,
          fontWeight: FontWeight.w800, height: 1.12),
      headlineMedium: TextStyle(fontSize: 27, color: WaveColors.ink,
          fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontSize: 22, color: WaveColors.ink,
          fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontSize: 17, color: WaveColors.ink,
          fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 15, color: WaveColors.ink),
      bodyMedium: TextStyle(fontSize: 13, color: WaveColors.muted, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      border: pearlCapsule,
      enabledBorder: pearlCapsule,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WaveDesignTokens.pillRadius),
        borderSide: const BorderSide(color: WaveColors.deepTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WaveDesignTokens.pillRadius),
        borderSide: const BorderSide(color: Color(0xFFA82232), width: 1.5),
      ),
      labelStyle: const TextStyle(color: WaveColors.muted),
      hintStyle: const TextStyle(color: WaveColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WaveColors.deepTeal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFDAE8E6),
        disabledForegroundColor: WaveColors.muted,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: capsule,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WaveColors.deepTeal,
        side: const BorderSide(color: WaveColors.deepTeal),
        minimumSize: const Size(48, 48),
        shape: capsule,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: WaveColors.deepTeal,
        minimumSize: const Size(48, 48),
        shape: capsule,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WaveDesignTokens.cardRadius),
        side: const BorderSide(color: Colors.white, width: 1.5),
      ),
      elevation: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFF8FFFD),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Colors.white, width: 1.5),
      ),
      titleTextStyle: const TextStyle(fontFamily: 'Roboto',
        color: WaveColors.ink, fontSize: 21, fontWeight: FontWeight.w800),
      contentTextStyle: const TextStyle(fontFamily: 'Roboto',
        color: WaveColors.muted, fontSize: 14, height: 1.45),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: const Color(0xFFF8FFFD),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: WaveColors.deepTeal,
      contentTextStyle: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: capsule,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFD8F8F2),
      disabledColor: const Color(0xFFE1E8E8),
      checkmarkColor: WaveColors.deepTeal,
      labelStyle: const TextStyle(color: WaveColors.deepTeal,
          fontWeight: FontWeight.w700),
      side: const BorderSide(color: WaveDesignTokens.quietStroke),
      shape: capsule,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: WaveColors.deepTeal,
      inactiveTrackColor: const Color(0xFFD2EDE9),
      thumbColor: Colors.white,
      overlayColor: WaveColors.teal.withValues(alpha: .12),
      trackHeight: 8,
      valueIndicatorColor: WaveColors.deepTeal,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white :
          WaveColors.deepTeal),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? WaveColors.deepTeal :
          const Color(0xFFDDEDE9)),
      trackOutlineColor: const WidgetStatePropertyAll(
          WaveDesignTokens.quietStroke),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: WaveColors.deepTeal,
      linearTrackColor: Color(0xFFD8F3F0),
      circularTrackColor: Color(0xFFD8F3F0),
    ),
    iconTheme: const IconThemeData(color: WaveColors.deepTeal),
  );
}
