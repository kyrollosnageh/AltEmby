// lib/core/theme/app_theme.dart
//
// Design system: Video Streaming/OTT — Cinema dark + play red
// Palette source: UI/UX Pro Max (Video Streaming/OTT recommendation)
// Typography: Inter (clean, premium, cinematic feel)

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Cinema streaming palette
  // Deep indigo used for dialogs and elevated surfaces
  static const _primaryDeep = Color(0xFF0F0F23);
  static const _secondary = Color(0xFF1E1B4B);
  static const _accent = Color(0xFFE11D48); // Play red — CTAs, progress
  static const _background = Color(0xFF000000);
  static const _surface = Color(0xFF0C0C0D);
  static const _card = Color(0xFF0C0C0D);
  static const _muted = Color(0xFF181818);
  static const _border = Color(0xFF312E81);
  static const _textPrimary = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: _accent,
      onPrimary: Colors.white,
      secondary: _secondary,
      onSecondary: Colors.white,
      surface: _surface,
      surfaceContainerHighest: _primaryDeep,
      onSurface: _textPrimary,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      outline: _border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _border.withAlpha(40)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        indicatorColor: _accent.withAlpha(30),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: _textSecondary),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: _textSecondary, fontSize: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border.withAlpha(80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        filled: true,
        fillColor: _muted,
        hintStyle: const TextStyle(color: _textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: BorderSide(color: _border.withAlpha(120)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _muted,
        selectedColor: _accent.withAlpha(40),
        labelStyle: const TextStyle(color: _textPrimary, fontSize: 13),
        side: BorderSide(color: _border.withAlpha(60)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: _border.withAlpha(40)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _accent,
        linearTrackColor: _muted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surface,
        contentTextStyle: const TextStyle(color: _textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: _textPrimary, height: 1.5),
        bodyMedium: TextStyle(color: _textPrimary, height: 1.5),
        bodySmall: TextStyle(color: _textSecondary, height: 1.5),
        labelLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 48),
        ),
      ),
    );
  }
}
