/// Русская плюрализация числительного.
///
/// Русский язык требует три формы: «1 день», «2 дня», «5 дней». Формы задаёт
/// вызывающий, поэтому хелпер не знает конкретного слова.
///
/// Отдельное правило для 11–14: они всегда «many», хотя заканчиваются на 1–4
/// («11 дней», не «11 день»). Ноль попадает в «many» («0 дней»).
String pluralize(
  int n, {
  required String one,
  required String few,
  required String many,
}) {
  final lastDigit = n % 10;
  final lastTwo = n % 100;
  if (lastDigit == 1 && lastTwo != 11) {
    return one;
  }
  if (lastDigit >= 2 && lastDigit <= 4 && (lastTwo < 12 || lastTwo > 14)) {
    return few;
  }
  return many;
}
