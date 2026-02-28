import 'package:flutter/material.dart';

class AdminColors {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF111827);
  static const secondary = Color(0xFF6E56A0);
  static const primary = Color(0xFFEEE7FA);
  static const accent = Color(0xFF24DFC5);
  static const divider = Color(0xFFE5E7EB);
  static const muted = Color(0xFF64748B);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
}

class AdminIcons {
  static const paw = 'assets/icons/heart-bold.svg';
  static const home = 'assets/icons/home.svg';
  static const heart = 'assets/icons/heart.svg';
  static const flag = 'assets/icons/flag.svg';
  static const search = 'assets/icons/search.svg';
  static const blockUser = 'assets/icons/block-user.svg';
  static const library = 'assets/icons/library.svg';
  static const dangerTriangle = 'assets/icons/danger-triangle.svg';
  static const lightbulb = 'assets/icons/lightbulb.svg';
  static const user = 'assets/icons/user.svg';
  static const bell = 'assets/icons/bell.svg';
  static const exit = 'assets/icons/exit.svg';
}

ThemeData adminTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: AdminColors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AdminColors.secondary,
      primary: AdminColors.secondary,
      surface: AdminColors.white,
    ),
    dividerColor: AdminColors.divider,
    cardTheme: CardThemeData(
      color: AdminColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AdminColors.divider),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AdminColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AdminColors.black,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AdminColors.black,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: AdminColors.black,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        color: AdminColors.black,
      ),
    ),
  );
}
