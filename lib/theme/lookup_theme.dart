import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Estilo tipografico breve para titulos de seccion en pantallas internas.
TextStyle kSectionTitleStyle = GoogleFonts.plusJakartaSans(
  fontSize: 18,
  fontWeight: FontWeight.w800,
  color: kInk,
  letterSpacing: -0.2,
);

/// Estilo tipografico para etiquetas de campo y leyendas muted.
TextStyle kLabelStyle = GoogleFonts.plusJakartaSans(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: kInkMuted,
  letterSpacing: 0.1,
);

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

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
      .apply(bodyColor: kInk, displayColor: kInk)
      .copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: kInk,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(height: 1.35, color: kInk),
      );

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kInk,
      surfaceTintColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: GoogleFonts.plusJakartaSans(
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
        textStyle: GoogleFonts.plusJakartaSans(
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
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBrandBlue,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: kBrandBlue.withValues(alpha: 0.35), width: 1.4),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kBrandBlue,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kBrandBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      extendedTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kFieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.plusJakartaSans(color: kInkMuted),
      labelStyle: GoogleFonts.plusJakartaSans(color: kInkMuted),
      floatingLabelStyle: GoogleFonts.plusJakartaSans(
        color: kBrandBlue,
        fontWeight: FontWeight.w600,
      ),
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
        (states) => GoogleFonts.plusJakartaSans(
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
      contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: kInk,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBrandBlue),
    listTileTheme: const ListTileThemeData(iconColor: kBrandBlue),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: kInk,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12),
    ),
  );
}

/// Widget reutilizable: titulo de seccion con punto acento y accion opcional.
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(title, style: kSectionTitleStyle),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
