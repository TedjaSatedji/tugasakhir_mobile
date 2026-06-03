import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData darkCyberpunkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryNeon,
    scaffoldBackgroundColor: AppColors.darkBg,
    cardColor: AppColors.darkCard,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryNeon,
      onPrimary: Color(0xFF0F1411),
      secondary: AppColors.secondaryNeon,
      onSecondary: Color(0xFF1B160C),
      background: AppColors.darkBg,
      onBackground: AppColors.textPrimary,
      surface: AppColors.darkCard,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Color(0xFF2B0C08),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCard,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      selectedItemColor: AppColors.primaryNeon,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static ThemeData lightMinimalistTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryNeon,
    scaffoldBackgroundColor: AppColors.lightBg,
    cardColor: AppColors.lightCard,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textDark),
      bodyMedium: TextStyle(color: AppColors.textDark), // Fallback since there's no textDarkSecondary
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryNeon,
      brightness: Brightness.light,
      background: AppColors.lightBg,
      surface: AppColors.lightCard,
      secondary: AppColors.secondaryNeon,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightCard,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textDark),
      titleTextStyle: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightCard,
      selectedItemColor: AppColors.primaryNeon,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}