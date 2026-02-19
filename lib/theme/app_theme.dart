import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textWhiteSecondary = Color(0xFFE0E0E0);
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentRedGlow = Color(0x66E53935);
  static const Color cardDark = Color(0xFF0A0A0A);
  static const Color borderGray = Color(0xFF1A1A1A);
  static const Color patternGray = Color(0xFF0F0F0F);

  // Typography
  static TextStyle get heading1 => GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textWhite,
        letterSpacing: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textWhite,
        letterSpacing: 0.8,
      );

  static TextStyle get heading3 => GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textWhite,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textWhite,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textWhiteSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textWhiteSecondary,
      );

  static TextStyle get label => GoogleFonts.orbitron(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textWhiteSecondary,
        letterSpacing: 0.5,
      );

  // Theme Data
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundBlack,
        colorScheme: const ColorScheme.dark(
          primary: accentRed,
          secondary: textWhite,
          surface: cardDark,
          background: backgroundBlack,
        ),
        textTheme: TextTheme(
          displayLarge: heading1,
          displayMedium: heading2,
          displaySmall: heading3,
          bodyLarge: bodyLarge,
          bodyMedium: bodyMedium,
          bodySmall: bodySmall,
          labelLarge: label,
        ),
        cardTheme: CardThemeData(
          color: cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderGray, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentRed,
            foregroundColor: textWhite,
            elevation: 8,
            shadowColor: accentRedGlow,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textWhite,
            side: const BorderSide(color: textWhite, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
}
