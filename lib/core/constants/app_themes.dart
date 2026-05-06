import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData darkCyberpunkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6AAF82), // Muted sage green
    scaffoldBackgroundColor: const Color(0xFF181C20), // Cool dark slate
    cardColor: const Color(0xFF21272E), // Deep slate surface
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE8E2D9)),
      bodyMedium: TextStyle(color: Color(0xFFB7B0A7)),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF6AAF82),
      onPrimary: Color(0xFF0F1411),
      secondary: Color(0xFFC9A86C),
      onSecondary: Color(0xFF1B160C),
      background: Color(0xFF181C20),
      onBackground: Color(0xFFE8E2D9),
      surface: Color(0xFF21272E),
      onSurface: Color(0xFFE8E2D9),
      error: Color(0xFFEF6A5B),
      onError: Color(0xFF2B0C08),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF21272E),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFE8E2D9)),
      titleTextStyle: TextStyle(color: Color(0xFFE8E2D9), fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF21272E),
      selectedItemColor: Color(0xFF6AAF82),
      unselectedItemColor: Color(0xFFB7B0A7),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static ThemeData lightMinimalistTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF4A8C62), // Muted green
    scaffoldBackgroundColor: const Color(0xFFF4F1EC), // Warm paper
    cardColor: const Color(0xFFFFFFFF), // Clean white
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2E3237)),
      bodyMedium: TextStyle(color: Color(0xFF6F757B)),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A8C62),
      brightness: Brightness.light,
      background: const Color(0xFFF4F1EC),
      surface: const Color(0xFFFFFFFF),
      secondary: const Color(0xFFA07840), // Gold/XP
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF2E3237)),
      titleTextStyle: TextStyle(color: Color(0xFF2E3237), fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFF4A8C62),
      unselectedItemColor: Color(0xFF6F757B),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}