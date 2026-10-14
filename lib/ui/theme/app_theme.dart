import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// App-wide Material theme: cream pages, ink text, teal primary, Nunito with
/// heavy headings, rounded 20px cards.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      onPrimary: Colors.white,
      secondary: AppColors.sun,
      onSecondary: AppColors.ink,
      tertiary: AppColors.violet,
      error: AppColors.coral,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  final text = GoogleFonts.nunitoTextTheme(base.textTheme)
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
      .copyWith(
        headlineMedium: GoogleFonts.nunito(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      );

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.headlineMedium,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
  );
}
