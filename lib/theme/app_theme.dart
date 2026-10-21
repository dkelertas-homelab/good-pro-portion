import 'package:flutter/material.dart';

class AppColors {
  static const teal = Color(0xFF0D9488);
  static const tealDark = Color(0xFF0F766E);
  static const tealSoft = Color(0xFFCCFBF1);
  static const coral = Color(0xFFFF6B4A);
  static const coralSoft = Color(0xFF3A221C);
  static const darkBg = Color(0xFF0F1218);
  static const darkSurface = Color(0xFF1A1F2A);
  static const lightBg = Color(0xFFF7F8FA);
}

ThemeData buildLightTheme() => _quiet(_light());

ThemeData _light() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: Brightness.light,
    primary: AppColors.teal,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBg,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        enableFeedback: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
  );
}

ThemeData buildDarkTheme() => _quiet(_dark());

ThemeData _dark() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.coral,
    brightness: Brightness.dark,
    primary: AppColors.coral,
    surface: AppColors.darkSurface,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkBg,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        enableFeedback: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
  );
}

/// No Android touch click sounds on any button or list tile (David: "no
/// beeps on or after any presses"). Filled buttons set it in their own theme.
ThemeData _quiet(ThemeData t) => t.copyWith(
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(enableFeedback: false),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(enableFeedback: false),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(enableFeedback: false),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(enableFeedback: false),
  ),
  listTileTheme: const ListTileThemeData(enableFeedback: false),
);
