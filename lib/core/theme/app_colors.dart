import 'package:flutter/material.dart';

/// Единый источник акцентных цветов приложения (Phase 54b).
///
/// Бледно-фиолетовый акцент для важных выделений: правильные ответы,
/// ключевые слова в предложениях, strong в чате Маффина. Не зависит от
/// seed темы (teal): акцент одинаков во всём приложении.
class AppColors {
  const AppColors._();

  /// Акцент светлой темы: контраст на светлом фоне.
  static const accentPurpleLight = Color(0xFF6750A4);

  /// Акцент тёмной темы: читается на тёмном фоне.
  static const accentPurpleDark = Color(0xFFD0BCFF);

  /// Акцент по brightness темы [context].
  static Color accentPurple(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? accentPurpleDark
      : accentPurpleLight;
}
