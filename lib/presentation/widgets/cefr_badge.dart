import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:flutter/material.dart';

/// Цвет бейджа уровня (ADR-023).
///
/// Градиент «спокойный → тревожный»: A0/A1 не пугают новичка, C1/C2 явно
/// сигналят «это сложно». Значения фиксированы, а не берутся из темы: смысл
/// цвета — сам уровень, а не акцент приложения.
Color cefrLevelColor(CefrLevel level) => switch (level) {
  CefrLevel.a0 || CefrLevel.a1 => Colors.teal,
  CefrLevel.a2 => Colors.lightGreen,
  CefrLevel.b1 => Colors.amber,
  CefrLevel.b2 => Colors.orange,
  CefrLevel.c1 => Colors.deepOrange,
  CefrLevel.c2 => Colors.red,
};

/// Компактный бейдж уровня: `A1`, `B2`, …
///
/// Один виджет на карточку урока и на строку словаря, чтобы уровень выглядел
/// одинаково на всех экранах.
class CefrBadge extends StatelessWidget {
  /// Создаёт бейдж для [level].
  const CefrBadge({required this.level, this.dense = true, super.key});

  /// Уровень, который показывается.
  final CefrLevel level;

  /// Компактные отступы — для строк списка; на карточке можно крупнее.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = cefrLevelColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: dense ? 11 : 14,
        ),
      ),
    );
  }
}
