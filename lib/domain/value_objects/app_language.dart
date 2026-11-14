/// Язык интерфейса приложения (Phase 27b, ADR-043).
///
/// Только UI-строки: учебный контент (слова, фразы, рассказы) остаётся
/// на английском независимо от выбранного языка.
enum AppLanguage {
  /// Русский (по умолчанию).
  ru(code: 'ru', label: 'Русский'),

  /// English.
  en(code: 'en', label: 'English');

  const AppLanguage({required this.code, required this.label});

  /// Код языка: хранится в БД и снимках экспорта.
  final String code;

  /// Название языка для меню выбора (на самом языке).
  final String label;

  /// Восстанавливает язык по коду; неизвестный код — ru (fallback).
  static AppLanguage fromCode(String code) =>
      values.firstWhere((language) => language.code == code, orElse: () => ru);
}
