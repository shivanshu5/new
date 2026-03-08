import 'package:flutter/material.dart';

class AppTheme {
  // Primary gradient stops
  static const Color violet    = Color(0xFF8A2BE2);
  static const Color hotPink   = Color(0xFFFF1493);
  static const Color mint      = Color(0xFF00FFC6);
  static const Color electricBlue = Color(0xFF3D8BFF);
  static const Color background = Color(0xFF0E0A1F);
  static const Color surface    = Color(0xFF1A1330);
  static const Color surfaceAlt = Color(0xFF201840);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [violet, hotPink, mint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [electricBlue, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: violet,
      colorScheme: const ColorScheme.dark(
        primary: violet,
        secondary: hotPink,
        tertiary: mint,
        surface: background,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge:   TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyMedium:   TextStyle(color: Colors.white70),
        bodySmall:    TextStyle(color: Colors.white54),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: violet, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: violet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: mint,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.1)),
      cardColor: surface,
    );
  }
}
