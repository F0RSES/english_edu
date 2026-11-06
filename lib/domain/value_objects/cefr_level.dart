/// CEFR — Common European Framework of Reference for Languages (ADR-023).
///
/// Порядок значений задаёт шкалу сложности: `A0 < A1 < A2 < B1 < B2 < C1 < C2`.
/// Поэтому сравнение уровней делается через [index], а не через label.
///
/// `A0` нет в оригинальной шкале CEFR: это «Pre-A1» — слова, которые нужны до
/// первого уровня (артикли, базовые глаголы, числа).
enum CefrLevel {
  /// Pre-A1: самые частотные слова, до уровня A1.
  a0(label: 'A0', description: 'Pre-A1 (Beginner)'),

  /// A1: Beginner.
  a1(label: 'A1', description: 'Beginner'),

  /// A2: Elementary.
  a2(label: 'A2', description: 'Elementary'),

  /// B1: Intermediate.
  b1(label: 'B1', description: 'Intermediate'),

  /// B2: Upper-Intermediate.
  b2(label: 'B2', description: 'Upper-Intermediate'),

  /// C1: Advanced.
  c1(label: 'C1', description: 'Advanced'),

  /// C2: Proficiency.
  c2(label: 'C2', description: 'Proficiency');

  const CefrLevel({required this.label, required this.description});

  /// Короткая метка для бейджа и фильтра: `A0`…`C2`.
  final String label;

  /// Расшифровка для профиля и онбординга.
  final String description;

  /// Разбирает метку без учёта регистра.
  ///
  /// Бросает [ArgumentError] на неизвестном значении: молчаливая подмена
  /// уровня исказила бы фильтр очереди и подпись в профиле.
  static CefrLevel fromLabel(String label) => CefrLevel.values.firstWhere(
    (level) => level.label.toLowerCase() == label.toLowerCase(),
    orElse: () => throw ArgumentError('Unknown CEFR level: $label'),
  );
}
