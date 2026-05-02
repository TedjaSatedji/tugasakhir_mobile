import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData darkCyberpunkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00E676), // Rich Mint Green
    scaffoldBackgroundColor: const Color(0xFF0D1117), // Deep blue-black
    cardColor: const Color(0xFF161B22), // Dark surface
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF3F4F6)),
      bodyMedium: TextStyle(color: Color(0xFF9CA3AF)),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E676),
      brightness: Brightness.dark,
      background: const Color(0xFF0D1117),
      surface: const Color(0xFF161B22),
      secondary: const Color(0xFFD500F9), // Cyberpunk Purple
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFF3F4F6)),
      titleTextStyle: TextStyle(color: Color(0xFFF3F4F6), fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161B22),
      selectedItemColor: Color(0xFF00E676),
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static ThemeData lightMinimalistTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF10B981), // Emerald Green
    scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Cool Gray
    cardColor: const Color(0xFFFFFFFF), // White
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1F2937)),
      bodyMedium: TextStyle(color: Color(0xFF6B7280)),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF10B981),
      brightness: Brightness.light,
      background: const Color(0xFFF3F4F6),
      surface: const Color(0xFFFFFFFF),
      secondary: const Color(0xFF6366F1), // Indigo
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF1F2937)),
      titleTextStyle: TextStyle(color: Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFF10B981),
      unselectedItemColor: Color(0xFF6B7280),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}