import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Радиус скругления карточек, полей и кнопок приложения.
const double appRadius = 20;

/// Мятный фон светлой темы: тот же оттенок, что у splash.
const _lightBackground = Color(0xFFF2F7F6);

/// Светлая тема.
///
/// Inter лежит в `assets/google_fonts/`, поэтому типографика работает офлайн:
/// сеть не нужна ни на первом запуске, ни в тестах.
ThemeData buildLightTheme() => _buildTheme(Brightness.light);

/// Тёмная тема.
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

/// Тема по умолчанию (светлая) — для тестов и превью.
ThemeData buildAppTheme() => buildLightTheme();

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final textTheme = GoogleFonts.interTextTheme(base.textTheme);
  final radius = BorderRadius.circular(appRadius);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: brightness == Brightness.light
        ? _lightBackground
        : base.scaffoldBackgroundColor,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Компактная кнопка: в диалогах и на карточках полноширинная
        // (Size.fromHeight) выглядела как полоса.
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Из textTheme, а не из голого TextStyle: иначе кнопка выпадает с
        // Inter на системный шрифт.
        textStyle: textTheme.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: textTheme.titleMedium,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(borderRadius: radius),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: radius),
      elevation: 8,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      // Стили текста берутся из textTheme: голый TextStyle потерял бы Inter.
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: radius.topLeft),
      ),
    ),
  );
}
