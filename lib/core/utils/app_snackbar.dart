import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../extensions/theme_extensions.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    IconData? icon,
    SnackBarAction? action,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    final bgColor = isError ? AppColors.error : AppColors.primaryNeon;
    final defaultIcon = isError ? Icons.error_outline : Icons.check_circle_outline;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        action: action,
        content: Row(
          children: [
            Icon(
              icon ?? defaultIcon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
