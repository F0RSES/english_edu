import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Итоги завершённой сессии.
class SessionSummary extends StatelessWidget {
  /// Создаёт экран итогов.
  const SessionSummary({
    required this.actualXp,
    required this.correct,
    required this.total,
    super.key,
  });

  /// Сколько XP реально начислено доменом за сессию.
  final int actualXp;

  /// Сколько ответов зачтено верными.
  final int correct;

  /// Сколько карточек было в сессии.
  final int total;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Сессия завершена',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('Верно: $correct из $total'),
          Text('XP: $actualXp'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Готово'),
          ),
        ],
      );
}
