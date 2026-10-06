import 'package:flutter/material.dart';
import 'muse_colors.dart';
import 'muse_spacing.dart';

class MuseTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MuseColors.background,
      primaryColor: MuseColors.mindCyan,
      colorScheme: const ColorScheme.dark(
        primary: MuseColors.mindCyan,
        secondary: MuseColors.breathMint,
        surface: MuseColors.surface,
        error: MuseColors.fitPoor,
        onPrimary: Color(0xFF001B2E),
        onSurface: MuseColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MuseColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: MuseColors.textPrimary),
        titleTextStyle: TextStyle(
          color: MuseColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MuseColors.mindCyan,
          foregroundColor: const Color(0xFF001F3F),
          elevation: 0,
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: MuseSpacing.roundedPill,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MuseColors.textPrimary,
          side: const BorderSide(color: MuseColors.border, width: 1.2),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: MuseSpacing.roundedPill,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MuseColors.mindCyan,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MuseColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: MuseColors.textTertiary, fontSize: 14),
        labelStyle: const TextStyle(color: MuseColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
          borderSide: const BorderSide(color: MuseColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
          borderSide: const BorderSide(color: MuseColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
          borderSide: const BorderSide(color: MuseColors.mindCyan, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: MuseColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
