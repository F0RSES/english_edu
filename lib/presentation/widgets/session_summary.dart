import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Итоги завершённой сессии.
class SessionSummary extends StatelessWidget {
  /// Создаёт экран итогов.
  const SessionSummary({
    required this.actualXp,
    required this.correct,
    required this.total,
    this.lang = AppLanguage.ru,
    super.key,
  });

  /// Сколько XP реально начислено доменом за сессию.
  final int actualXp;

  /// Сколько ответов зачтено верными.
  final int correct;

  /// Сколько карточек было в сессии.
  final int total;

  /// Язык интерфейса; ru по умолчанию (Phase 27b).
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        S.sessionDone(lang),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      Text(S.sessionCorrect(correct, total, lang)),
      Text(S.sessionXp(actualXp, lang)),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => context.go('/'),
        child: Text(S.sessionFinish(lang)),
      ),
    ],
  );
}
