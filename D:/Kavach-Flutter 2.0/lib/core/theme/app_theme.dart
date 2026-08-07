import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Digikavach Brand Colors (from splash / brand guidelines) ──────────────
  static const Color navyBlue     = Color(0xFF0D1F5C); // Primary navy blue
  static const Color navyLight    = Color(0xFF1A3A7A); // Lighter navy variant
  static const Color brandOrange  = Color(0xFFF26522); // Brand orange
  static const Color orangeLight  = Color(0xFFFF8C42); // Lighter orange accent

  // Legacy aliases kept for backward compatibility
  static const Color primaryColor  = navyBlue;
  static const Color primaryLight  = navyLight;
  static const Color secondaryColor = brandOrange;

  // Status Colors
  static const Color threatCritical = Color(0xFFEF4444); // Red
  static const Color threatWarning  = Color(0xFFF59E0B); // Amber
  static const Color threatSafe     = Color(0xFF22C55E); // Green

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark  = Color(0xFF070E1A);
  static const Color cardDark        = Color(0xFF0F1E3D);

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: navyBlue,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: navyBlue,
        secondary: brandOrange,
        error: threatCritical,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: navyBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navyBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: navyBlue),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brandOrange : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brandOrange.withOpacity(0.4) : Colors.grey.shade300),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: navyBlue,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: navyBlue,
        secondary: brandOrange,
        error: threatCritical,
        surface: cardDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: navyBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: brandOrange),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brandOrange : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brandOrange.withOpacity(0.4) : Colors.grey.shade700),
      ),
    );
  }
}
