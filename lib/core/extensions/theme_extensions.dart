import 'package:flutter/material.dart';

extension ThemeColors on BuildContext {
  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get card => Theme.of(this).cardColor;
  Color get text => Theme.of(this).textTheme.bodyLarge?.color ?? Colors.white;
  Color get textDim => Theme.of(this).textTheme.bodyMedium?.color ?? Colors.grey;
  Color get primary => Theme.of(this).primaryColor;
}
