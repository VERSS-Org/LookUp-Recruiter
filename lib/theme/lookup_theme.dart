import 'package:flutter/material.dart';

const Color kBrandBlue = Color(0xFF28348A);
const Color kBrandBlueAlt = Color(0xFF3A4BC4);
const Color kSkyBlue = Color(0xFF22A9E8);
const Color kInk = Color(0xFF172033);
const Color kInkMuted = Color(0xFF6B7591);
const Color kSurface = Color(0xFFEFF2F9);
const Color kHairline = Color(0xFFE6EBF4);
const Color kFieldFill = Color(0xFFF3F5FB);

/// Degradado de marca usado en cabeceras y acentos destacados.
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kBrandBlue, Color(0xFF2F4FBE), kSkyBlue],
);

/// Sombra suave y aireada para tarjetas y superficies elevadas.
List<BoxShadow> softShadow({
  double opacity = 0.08,
  double blur = 24,
  double y = 12,
}) {
  return [
    BoxShadow(
      color: kBrandBlue.withValues(alpha: opacity),
      blurRadius: blur,
      offset: Offset(0, y),
    ),
  ];
}

ThemeData buildLookUpTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBrandBlue,
      primary: kBrandBlue,
      secondary: kSkyBlue,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: kSurface,
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: kInk, displayColor: kInk)
        .copyWith(
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kInk,
      surfaceTintColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: TextStyle(
        color: kInk,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shadowColor: kBrandBlue.withValues(alpha: 0.10),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        elevation: 2,
        shadowColor: kBrandBlue.withValues(alpha: 0.45),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBrandBlue,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: kBrandBlue.withValues(alpha: 0.35), width: 1.4),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kBrandBlue,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kBrandBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      extendedTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kFieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: kInkMuted),
      labelStyle: const TextStyle(color: kInkMuted),
      prefixIconColor: kInkMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kHairline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBrandBlue, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kHairline,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 3,
      shadowColor: kBrandBlue.withValues(alpha: 0.18),
      indicatorColor: kBrandBlue.withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? kBrandBlue : kInkMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? kBrandBlue : kInkMuted,
          size: 24,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        color: kInk,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBrandBlue),
    listTileTheme: const ListTileThemeData(iconColor: kBrandBlue),
  );
}
