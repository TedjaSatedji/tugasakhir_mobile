import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary
  static const Color primaryNeon = Color(0xFF00FF41);
  static const Color secondaryNeon = Color(0xFF00D9FF);
  
  // Background
  static const Color darkBg = Color(0xFF0A0E27);
  static const Color darkCard = Color(0xFF1a1f3a);
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  
  // Text
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textDark = Color(0xFF1F2937);
  
  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFB923C);
  static const Color info = Color(0xFF3B82F6);
  
  // Special
  static const Color xpColor = Color(0xFFFFD700);
  static const Color levelUpColor = Color(0xFF8B5CF6);

  // Helper untuk opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}