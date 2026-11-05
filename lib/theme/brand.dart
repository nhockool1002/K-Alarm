import 'package:flutter/material.dart';

/// K-Alarm brand tokens — colors, type scale and the one shared theme
/// builder, kept in sync with the official brand guidelines
/// (Electric Indigo / Alert Coral / Wake Amber / Mission Emerald on an
/// Obsidian Night surface system).
class KColors {
  KColors._();

  // Primary & accents
  static const indigo = Color(0xFF6366F1); // Electric Indigo — focus, time
  static const coral = Color(0xFFFF4A3D); // Alert Coral — ringing / action
  static const coralLight = Color(0xFFFF6B5E);
  static const amber = Color(0xFFF59E0B); // Wake Amber — intermediate stage
  static const emerald = Color(0xFF10B981); // Mission Emerald — challenge complete

  // Dark UI spectrum
  static const night = Color(0xFF0B0F19); // App root canvas
  static const card = Color(0xFF131B2E); // Card / container surface
  static const surface = Color(0xFF1A2338);
  static const border = Color(0xFF1F293D); // Dividers & outlines
  static const mutedSlate = Color(0xFF94A3B8); // Secondary text & icons
}

/// Font families bundled under assets/fonts (see pubspec.yaml).
class KFonts {
  KFonts._();
  static const sans = 'Plus Jakarta Sans';
  static const mono = 'JetBrains Mono';
}

/// Brand accent color carried by each stage of a chain, cycling
/// Indigo → Coral → Amber → Emerald per the K-Chain timeline guideline.
Color kStageColor(int index) {
  const stageColors = [KColors.indigo, KColors.coral, KColors.amber, KColors.emerald];
  return stageColors[index % stageColors.length];
}

/// Tabular-figure monospace style for anything showing clock digits —
/// alarm times, countdowns, chain timelines — so the digits never jitter.
TextStyle kMonoTime({
  double fontSize = 20,
  FontWeight weight = FontWeight.w700,
  Color? color,
}) {
  return TextStyle(
    fontFamily: KFonts.mono,
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

ThemeData buildKAlarmTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: KColors.indigo,
    onPrimary: Colors.white,
    secondary: KColors.coral,
    onSecondary: Colors.white,
    tertiary: KColors.amber,
    onTertiary: Colors.black,
    error: KColors.coral,
    onError: Colors.white,
    surface: isDark ? KColors.card : Colors.white,
    onSurface: isDark ? Colors.white : const Color(0xFF0B0F19),
    surfaceContainerHighest: isDark ? KColors.surface : const Color(0xFFF1F3F9),
    outline: isDark ? KColors.border : const Color(0xFFD9DEE8),
  );

  final scaffoldBg = isDark ? KColors.night : const Color(0xFFF7F8FC);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBg,
    fontFamily: KFonts.sans,
    textTheme: const TextTheme().apply(fontFamily: KFonts.sans),
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      foregroundColor: isDark ? Colors.white : const Color(0xFF0B0F19),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: KFonts.sans,
        fontWeight: FontWeight.w800,
        fontSize: 20,
        letterSpacing: -0.2,
        color: isDark ? Colors.white : const Color(0xFF0B0F19),
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark ? KColors.card : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? KColors.border : const Color(0xFFE4E8F1)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? KColors.border : const Color(0xFFE4E8F1),
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KColors.indigo,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: KFonts.sans, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KColors.coral,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: KFonts.sans, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : const Color(0xFF0B0F19),
        side: BorderSide(color: isDark ? KColors.border : const Color(0xFFD9DEE8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? KColors.indigo : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KColors.indigo.withValues(alpha: 0.5)
            : null,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: KColors.coral,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? KColors.surface : const Color(0xFFF1F3F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? KColors.surface : const Color(0xFFF1F3F9),
      selectedColor: KColors.indigo,
      labelStyle: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B0F19)),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      side: BorderSide.none,
    ),
  );
}
