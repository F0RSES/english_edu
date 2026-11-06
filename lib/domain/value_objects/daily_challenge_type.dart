import 'dart:math';

/// Тип ежедневного задания (Phase 15b, ADR-030).
///
/// Цель и награда живут в самом значении, а не в БД отдельно: тип — источник
/// правды для `goalValue` и `xpReward`, поэтому расхождение между ними
/// невозможно. В БД хранится имя значения ([name]), а не индекс: порядок
/// значений в коде может измениться, и числовой снимок стал бы неоднозначным.
enum DailyChallengeType {
  /// Повторить 20 слов — и новые, и просроченные.
  review20(label: 'Повтори 20 слов', goal: 20, xp: 50),

  /// Десять верных ответов подряд; провал обнуляет серию.
  streak10(label: 'Серия из 10 верных', goal: 10, xp: 30),

  /// Пять слов, показанных впервые.
  new5(label: 'Выучи 5 новых слов', goal: 5, xp: 40),

  /// Десять ответов подряд без единого провала; `hard` нейтрален.
  noMistakes(label: '10 без ошибок', goal: 10, xp: 60);

  const DailyChallengeType({
    required this.label,
    required this.goal,
    required this.xp,
  });

  /// Текст задания для карточки на главном экране.
  final String label;

  /// Сколько единиц нужно набрать.
  final int goal;

  /// Сколько XP начисляется за выполнение.
  final int xp;

  /// Случайный тип задания.
  ///
  /// [random] инжектится: тесты подставляют `Random(seed)` и получают
  /// детерминированный результат, приложение — несеяный.
  static DailyChallengeType random(Random random) =>
      values[random.nextInt(values.length)];

  /// Восстанавливает тип из имени значения, записанного в БД.
  ///
  /// Неизвестное имя — ошибка данных, а не повод молча выдать другое задание:
  /// иначе карточка показывала бы чужую цель.
  static DailyChallengeType fromName(String name) => values.firstWhere(
    (type) => type.name == name,
    orElse: () =>
        throw ArgumentError.value(name, 'name', 'unknown challenge type'),
  );
}
