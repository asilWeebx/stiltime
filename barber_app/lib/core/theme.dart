import 'package:flutter/material.dart';

class AppColors {
  // Brand — soft blue
  static const primary = Color(0xFF4E6EF5);
  static const primaryLight = Color(0xFFEEF1FE);
  static const primaryDark = Color(0xFF3451D1);

  // Backgrounds (warm neutral)
  static const background = Color(0xFFFAF9F7);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF5F2EE);
  static const beige = Color(0xFFEDE8E0);
  static const warmGray = Color(0xFFF2EFE9);

  // Text
  static const text = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textHint = Color(0xFFAAAAAA);
  static const textTertiary = textHint;

  // Status
  static const success = Color(0xFF2AA771);
  static const successLight = Color(0xFFE6F7F0);
  static const warning = Color(0xFFDDA74A);
  static const warningLight = Color(0xFFFFF8E6);
  static const error = Color(0xFFE84C4C);
  static const errorLight = Color(0xFFFEEEEE);
  static const info = Color(0xFF4E6EF5);
  static const infoLight = Color(0xFFEEF1FE);

  // Border
  static const border = Color(0xFFE9E4DC);
  static const borderLight = Color(0xFFF0EDE8);

  // Gradients
  static const gradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientSoft = LinearGradient(
    colors: [Color(0xFFFAF9F7), Color(0xFFEDE8E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 1)),
      ];
}

ThemeData barberTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1, space: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.warmGray,
      selectedColor: AppColors.primaryLight,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
  );
}
