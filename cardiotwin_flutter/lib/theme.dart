import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color bg        = Color(0xFF0A0E1A);
  static const Color surface   = Color(0xFF111827);
  static const Color surface2  = Color(0xFF1A2235);
  static const Color border    = Color(0xFF1E2D45);

  static const Color purple    = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFF9F67FF);
  static const Color teal      = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF14B8A6);

  static const Color green     = Color(0xFF10B981);
  static const Color orange    = Color(0xFFF59E0B);
  static const Color red       = Color(0xFFEF4444);

  static const Color textPrimary   = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF4A6080);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF0D9488)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0A1E), Color(0xFF0A1628)],
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: purple,
      secondary: teal,
      surface: surface,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFF),
    colorScheme: const ColorScheme.light(
      primary: purple,
      secondary: teal,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(
      ThemeData.light().textTheme,
    ),
  );
}

class AppConstants {
  static const String baseUrl = 'https://KarimAmer2004.pythonanywhere.com';
}
