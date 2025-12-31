import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppThemes {
  // LIGHT THEME
  static ThemeData lightMode = ThemeData(
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.light,
      background: Colors.white,
      surface: Colors.white,
    ),

    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xFF1DA1F2),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0.5,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1DA1F2),
      foregroundColor: Colors.white,
    ),

    cardColor: Colors.white,

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );

  // DARK THEME
  static ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    cardColor: Colors.black,

    primaryColor: Colors.black,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 0.5,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
    ),

    bottomAppBarTheme: const BottomAppBarTheme(
      color: Colors.black,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
    ), dialogTheme: DialogThemeData(backgroundColor: Colors.black), colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.dark,
      background: Colors.black,
      surface: Colors.black,
    ).copyWith(surface: Colors.black),
  );
}
