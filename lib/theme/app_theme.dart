import 'package:flutter/material.dart';

/// Es Makker brand colours – a classic Danish card-game feel.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A237E); // deep navy
  static const Color secondary = Color(0xFFC62828); // rich red (card suit)
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color positive = Color(0xFF2E7D32); // green for positive scores
  static const Color negative = Color(0xFFC62828); // red for negative scores
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      centerTitle: true,
      elevation: 2,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.onSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
}
