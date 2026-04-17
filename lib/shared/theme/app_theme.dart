import 'package:flutter/material.dart';

// Onboarding pink-orange theme (matches Onboarding.css)
class OBColors {
  static const pink = Color(0xFFFF597D);
  static const orange = Color(0xFFFE7650);
  static const bg = Color(0xFFFFF1EA);
  static const border = Color(0xFFF0E4DE);
  static const pinkSoft = Color(0xFFFFEDF1);

  static const gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF597D), Color(0xFFFE7650)],
  );

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: Color(0xFFFF597D).withValues(alpha: 0.28),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ];
}

class AppColors {
  static const bg = Color(0xFFF4F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const accent = Color(0xFF16A34A);
  static const accentSoft = Color(0xFFDCFCE7);
  static const accentDark = Color(0xFF15803D);
  static const warm = Color(0xFFEA580C);
  static const warmSoft = Color(0xFFFFEDD5);
  static const support = Color(0xFFBE185D);
  static const supportSoft = Color(0xFFFCE7F3);
  static const accentOver = Color(0xFFDC2626);
  static const accentOverSoft = Color(0xFFFEF2F2);
}

class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppShadow {
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: AppColors.text),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          shadowColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            minimumSize: const Size(double.infinity, 54),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
      );
}
