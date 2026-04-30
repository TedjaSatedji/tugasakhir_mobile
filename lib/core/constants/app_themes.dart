import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData darkCyberpunkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryNeon,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryNeon,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCard,
      elevation: 0,
      centerTitle: true,
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
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryNeon,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightCard,
      elevation: 0,
      centerTitle: true,
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