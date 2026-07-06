import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Brand — soft blue
  static const primary = Color(0xFF4E6EF5);
  static const primaryDark = Color(0xFF3451D1);
  static const primaryLight = Color(0xFFEEF1FE);

  // Warm neutrals (Apple × Airbnb palette)
  static const background = Color(0xFFFAF9F7);   // warm off-white
  static const surface = Colors.white;
  static const surfaceWarm = Color(0xFFF5F2EE);   // warm gray
  static const beige = Color(0xFFEDE8E0);
  static const warmGray = Color(0xFFF2EFE9);

  // Text
  static const text = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textTertiary = Color(0xFFAAAAAA);

  // Borders
  static const border = Color(0xFFE9E4DC);
  static const divider = Color(0xFFF0EDE8);

  // Status
  static const success = Color(0xFF2AA771);
  static const successLight = Color(0xFFE6F7F0);
  static const error = Color(0xFFE84C4C);
  static const errorLight = Color(0xFFFEEEEE);
  static const warning = Color(0xFFDDA74A);
  static const warningLight = Color(0xFFFFF8E6);
  static const star = Color(0xFFDDA74A);

  // Gradients
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF4E6EF5), Color(0xFF3451D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientGold = LinearGradient(
    colors: [Color(0xFFDDA74A), Color(0xFFC08A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 1)),
      ];
  static List<BoxShadow> get floatShadow => [
        BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 32, offset: const Offset(0, 8)),
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ];
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        surfaceTintColor: Colors.transparent,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWarm,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 15),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.warmGray,
        selectedColor: AppColors.primaryLight,
        side: BorderSide.none,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
    );
  }
}
