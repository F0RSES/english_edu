import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_outcome.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/session_summary.dart';
import 'package:english_edu/presentation/widgets/swipe_card.dart';
import 'package:english_edu/presentation/widgets/word_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Режим урока (ADR-026).
///
/// Один экран на два сценария: обычная очередь дня и «добить проблемные
/// слова». Дублировать экран ради другого источника очереди — разъезжаться
/// в поведении карточки и отката, поэтому различие сведено к источнику данных
/// и заголовку.
enum LessonMode {
  /// Очередь дня: новые слова и повторения по расписанию SM-2.
  normal,

  /// Только проблемные слова: проваливали или просел ease (ADR-026).
  weak,

  /// Ранжированное повторение по приоритету (ADR-033).
  smart,
}

/// Экран урока: очередь карточек, оценка ответов, итоги.
class LessonScreen extends ConsumerStatefulWidget {
  /// Создаёт экран с очередью дня или с проблемными словами.
  const LessonScreen({super.key, this.mode = LessonMode.normal});

  /// Что показывать: обычную очередь или только проблемные слова.
  final LessonMode mode;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late final Future<TodayQueue> _queue;
  int _index = 0;
  bool _revealed = false;
  bool _finished = false;
  int _correct = 0;
  int _sessionXp = 0;
  WordId? _lastWordId;
  ReviewOutcome? _lastOutcome;

  @override
  void initState() {
    super.initState();
    // Очередь фиксируется на входе в урок: инвалидация провайдера во время
    // сессии не должна подменять карточки под пользователем.
    _queue = switch (widget.mode) {
      LessonMode.normal => ref.read(getTodayQueueProvider.future),
      LessonMode.weak => ref.read(weakWordsQueueProvider.future),
      LessonMode.smart => ref.read(smartReviewTodayQueueProvider.future),
    };
  }

  /// Сбрасывает кэш главного экрана: после ответов изменились серия, прогресс
  /// и дневная цель.
  ///
  /// Работает и в режиме [LessonMode.weak]: ответы пишутся тем же
  /// `RecordReview`, а он поднимает `DailyStats` — значит дневная цель и серия
  /// действительно меняются, и оставлять их устаревшими нельзя.
  ///
  /// `weakWordsQueueProvider` сбрасывается в обоих режимах: после ответов
  /// ease и `lapses` изменились, и счётчик на кнопке «Повторить сложные»
  /// должен пересчитаться, иначе бейдж живёт своей жизнью.
  void _invalidateHome() {
    ref
      ..invalidate(computeStreakProvider)
      ..invalidate(getTodayQueueProvider)
      ..invalidate(weakWordsQueueProvider)
      ..invalidate(smartReviewQueueProvider)
      ..invalidate(smartReviewTodayQueueProvider)
      ..invalidate(dailyGoalProvider);
  }

  /// Закрывает урок, предварительно помечая данные главного экрана устаревшими.
  void _close() {
    _invalidateHome();
    context.go('/');
  }

  /// Записывает ответ. Возвращает `false`, если сохранить не удалось.
  Future<bool> _grade(Word word, ReviewGrade grade, int total) async {
    try {
      final outcome = await ref.read(recordReviewProvider).call(word.id, grade);
      if (!mounted) {
        return false;
      }
      setState(() {
        _lastWordId = word.id;
        _lastOutcome = outcome;
        if (outcome.isCorrect) {
          _correct++;
        }
        _sessionXp += outcome.xpGained;
        _index++;
        _revealed = false;
        _finished = _index >= total;
      });
      // сессия закончилась — главный экран должен увидеть новые числа
      if (_finished) {
        unawaited(HapticFeedback.mediumImpact());
        _invalidateHome();
      }
      // Новый snackbar заменяет предыдущий, иначе он перекрывает кнопки.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('+${outcome.xpGained} XP'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      return true;
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('RecordReview failed', error, stack);
      await ref
          .read(crashReporterProvider)
          .captureException(error, stackTrace: stack, context: 'record_review');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить ответ')),
        );
      }
      return false;
    }
  }

  Future<void> _undo() async {
    final wordId = _lastWordId;
    final outcome = _lastOutcome;
    if (wordId == null || outcome == null) {
      return;
    }
    final undone = await ref.read(undoLastReviewProvider).call(wordId);
    if (!mounted || !undone) {
      return;
    }
    setState(() {
      _index--;
      _finished = false;
      _revealed = false;
      if (outcome.isCorrect) {
        _correct--;
      }
      _sessionXp -= outcome.xpGained;
      _lastWordId = null;
      _lastOutcome = null;
    });
  }

  /// Заголовок экрана: в режимах повторения своя подпись.
  String get _title => switch (widget.mode) {
    LessonMode.normal => 'Урок',
    LessonMode.weak => 'Сложные слова',
    LessonMode.smart => 'Умное повторение',
  };

  /// Идёт ли сессия: есть ответы или уже показан итог.
  ///
  /// Нужно для `PopScope`: пока сессия не начата, выход не требует вопроса.
  bool get _hasProgress => _index > 0 || _finished;

  /// Спрашивает подтверждение выхода из незавершённой сессии (BL-43).
  Future<void> _confirmExit() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Завершить сессию?'),
        content: const Text(
          'Прогресс текущей сессии сохранён. '
          'Недоделанные карточки вернутся в очередь.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (shouldPop != true || !mounted) {
      return;
    }
    _invalidateHome();
    Navigator.of(context).pop();
  }

  /// Экран урока поверх очереди дня.
  ///
  /// Пока сессия не начата, системный «назад» закрывает экран сразу. Если
  /// ответы уже есть — сначала вопрос: записи сохранены, но остаток очереди
  /// пользователь увидит только в следующем заходе.
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_hasProgress,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) {
        _invalidateHome();
        return;
      }
      await _confirmExit();
    },
    child: FutureBuilder<TodayQueue>(
      future: _queue,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _scaffold(
            _title,
            const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _scaffold(
            _title,
            const Center(child: Text('Не удалось загрузить очередь')),
          );
        }
        final queue = snapshot.data;
        if (queue == null || queue.all.isEmpty) {
          return _scaffold(_title, const Center(child: Text('На сегодня всё')));
        }
        final words = queue.all;
        if (_finished) {
          return _scaffold(
            _title,
            Center(
              child: SessionSummary(
                actualXp: _sessionXp,
                correct: _correct,
                total: words.length,
              ),
            ),
          );
        }
        return _scaffold(
          // В режимах повторения счётчик не показывается: заголовок задаёт
          // режим, а прогресс виден по карточкам (ADR-026, ADR-033).
          widget.mode == LessonMode.normal
              ? '${_index + 1}/${words.length}'
              : _title,
          _card(words[_index], words.length),
        );
      },
    ),
  );

  Widget _scaffold(String title, Widget body) => Scaffold(
    appBar: AppBar(
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: _lastWordId == null || _finished ? null : _undo,
        ),
      ],
    ),
    body: body,
  );

  Widget _card(Word word, int total) => Column(
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SwipeCard(
            key: ValueKey('card-${word.id.value}-$_index'),
            onSwiped: (direction) => unawaited(
              _grade(
                word,
                direction > 0 ? ReviewGrade.good : ReviewGrade.again,
                total,
              ),
            ),
            child: WordCard(
              word: word,
              revealed: _revealed,
              onTap: () => setState(() => _revealed = true),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _grade(word, ReviewGrade.again, total),
                child: const Text('Не знаю'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _grade(word, ReviewGrade.good, total),
                child: const Text('Знаю'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
