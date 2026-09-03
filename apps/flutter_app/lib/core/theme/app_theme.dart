import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF070B10);
  static const surface = Color(0xFF0D151F);
  static const surfaceAlt = Color(0xFF111C27);
  static const border = Color(0x303F6B8C);
  static const cyan = Color(0xFF30B7FF);
  static const purple = Color(0xFFAE76FF);
  static const green = Color(0xFF25D38B);
  static const red = Color(0xFFFF4E55);
  static const amber = Color(0xFFF5B83F);
  static const text = Color(0xFFEDF4FF);
  static const muted = Color(0xFF8292A7);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      surface: surface,
      error: red,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      fontFamily: 'sans-serif',
      useMaterial3: true,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text, fontSize: 13),
        bodySmall: TextStyle(color: muted, fontSize: 11),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }
}
