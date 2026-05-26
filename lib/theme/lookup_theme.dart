import 'package:flutter/material.dart';

const Color kBrandBlue = Color(0xFF28348A);
const Color kSkyBlue = Color(0xFF22A9E8);
const Color kInk = Color(0xFF172033);
const Color kSurface = Color(0xFFF5F7FB);

ThemeData buildLookUpTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBrandBlue,
      primary: kBrandBlue,
      secondary: kSkyBlue,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: kSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kInk,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kBrandBlue,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBrandBlue, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: kBrandBlue.withOpacity(0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? kBrandBlue
              : Colors.grey.shade700,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? kBrandBlue
              : Colors.grey.shade700,
        );
      }),
    ),
  );
}
