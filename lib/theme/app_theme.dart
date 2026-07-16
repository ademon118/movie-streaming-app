import 'package:flutter/material.dart';

class AppTheme {
  static const Color scaffoldBackground = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF16161D);
  static const Color surfaceElevated = Color(0xFF1E1E28);
  static const Color accent = Color(0xFFE0A100);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3BD);
  static const Color posterPlaceholder = Color(0xFF2A2A33);

  static ThemeData get darkCinema {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    final colorScheme = ColorScheme.dark(
      surface: surface,
      primary: accent,
      onPrimary: scaffoldBackground,
      secondary: accent,
      onSecondary: scaffoldBackground,
      onSurface: textPrimary,
      error: const Color(0xFFFF6B6B),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.2),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? accent : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? accent : textSecondary,
          );
        }),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ).copyWith(
        titleLarge: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: const TextStyle(
          color: textPrimary,
          fontSize: 14,
        ),
        bodySmall: const TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}
