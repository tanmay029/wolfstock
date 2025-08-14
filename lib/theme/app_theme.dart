import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00D4AA);
  static const Color accentColor = Color(0xFF007AFF);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color successColor = Color(0xFF00D4AA);

  static ThemeData lightTheme = ThemeData(
    primarySwatch: MaterialColor(0xFF00D4AA, {
      50: const Color(0xFFE6FBF7),
      100: const Color(0xFFB3F3E6),
      200: const Color(0xFF80EBD5),
      300: const Color(0xFF4DE3C4),
      400: const Color(0xFF26DDB7),
      500: const Color(0xFF00D4AA),
      600: const Color(0xFF00BF97),
      700: const Color(0xFF00A684),
      800: const Color(0xFF008E71),
      900: const Color(0xFF006B51),
    }),
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primarySwatch: MaterialColor(0xFF00D4AA, {
      50: const Color(0xFFE6FBF7),
      100: const Color(0xFFB3F3E6),
      200: const Color(0xFF80EBD5),
      300: const Color(0xFF4DE3C4),
      400: const Color(0xFF26DDB7),
      500: const Color(0xFF00D4AA),
      600: const Color(0xFF00BF97),
      700: const Color(0xFF00A684),
      800: const Color(0xFF008E71),
      900: const Color(0xFF006B51),
    }),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2D2D2D),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
}
