import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/scramble_puzzle.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Пауза после ответа: пользователь должен успеть увидеть результат.
const _feedbackDelay = Duration(milliseconds: 800);

/// Мини-игра «Собери слово» (ADR-027).
///
/// Показывает перевод и перемешанные буквы; слово собирается тапом по буквам.
/// Работает полностью офлайн — задания строятся из локального словаря, AI и
/// сеть не участвуют.
///
/// BL-71: Scramble теперь пишет прогресс в SRS — верный ответ уходит как
/// `good`, а слово, проваленное трижды, как `again`. Запись делается не больше
/// одного раза на слово за сессию, иначе частые «угадывания» испортили бы
/// расписание (ADR-028).
class WordScrambleScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const WordScrambleScreen({super.key});

  @override
  ConsumerState<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends ConsumerState<WordScrambleScreen> {
  List<ScramblePuzzle> _puzzles = const [];
  int _currentIndex = 0;
  List<String> _userAnswer = [];
  List<bool> _used = [];
  bool _isLoading = true;

  /// Неверный ответ: поле трясётся и красится в красный.
  bool _hasError = false;

  /// Идёт пауза после ответа: ввод заблокирован, иначе двойной тап перескочил
  /// бы через карточку.
  bool _waiting = false;

  int _shakeKey = 0;
  int _pulseKey = 0;
  int _correctCount = 0;

  /// Неудачные попытки на текущем слове: на третьей слово уходит в SRS как
  /// `again`, чтобы пользователь мог пойти дальше.
  int _wrongAttempts = 0;

  /// Карточка помощника видна после первой неудачной попытки и живёт до
  /// победы или скипа слова (ADR-042).
  bool _helperVisible = false;

  /// Последняя неудачная сборка: контекст для объяснения.
  String _lastWrongAnswer = '';

  /// Слова, чей прогресс уже записан в этой сессии (ADR-028).
  final Set<WordId> _recorded = {};

  /// Порог, после которого слово считается проваленным.
  static const _failedAttempts = 3;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  ScramblePuzzle? get _puzzle =>
      _currentIndex < _puzzles.length ? _puzzles[_currentIndex] : null;

  /// Собирает новую сессию из случайных слов словаря.
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _puzzles = const [];
      _currentIndex = 0;
      _correctCount = 0;
      _waiting = false;
      _userAnswer = [];
      _used = [];
      _hasError = false;
      _wrongAttempts = 0;
      _helperVisible = false;
      _lastWrongAnswer = '';
      _recorded.clear();
    });
    try {
      // Размер сессии — дефолт use case (10 карточек, ADR-027).
      final puzzles = await ref.read(generateScramblePuzzlesProvider)();
      if (!mounted) {
        return;
      }
      setState(() {
        _puzzles = puzzles;
        _isLoading = false;
        _used = List<bool>.filled(
          puzzles.isEmpty ? 0 : puzzles.first.scrambled.length,
          false,
        );
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Scramble puzzles failed', error, stack);
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  /// Добавляет букву из облака и автопроверяет собранное слово.
  void _selectLetter(int index) {
    final puzzle = _puzzle;
    if (puzzle == null || _waiting || _used[index]) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _userAnswer = [..._userAnswer, puzzle.scrambled[index]];
      _used = [..._used]..[index] = true;
      _hasError = false;
    });
    // Проверяем только по полному ответу: иначе ошибка мигала бы на середине.
    if (_userAnswer.length == puzzle.solution.length) {
      unawaited(_check(puzzle));
    }
  }

  /// Сверяет собранное слово с решением и показывает реакцию.
  Future<void> _check(ScramblePuzzle puzzle) async {
    if (_userAnswer.join().toLowerCase() == puzzle.solution) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _correctCount++;
        _pulseKey++;
        _waiting = true;
        _helperVisible = false;
      });
      _showMessage('Правильно!', correct: true);
      unawaited(_record(puzzle.word, ReviewGrade.good));
      await Future<void>.delayed(_feedbackDelay);
      if (!mounted) {
        return;
      }
      _advance();
      return;
    }

    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _hasError = true;
      _shakeKey++;
      _waiting = true;
      _wrongAttempts++;
      _helperVisible = true;
      _lastWrongAnswer = _userAnswer.join();
    });
    // «Неверно» показывает persistent-карточка под полем: SnackBar исчезает,
    // а объяснение нужно позже (ADR-042).
    // Слово провалено, если не собралось с трёх попыток: только тогда оно
    // уходит в SRS как `again`, чтобы одна опечатка не портила расписание.
    if (_wrongAttempts >= _failedAttempts) {
      unawaited(_record(puzzle.word, ReviewGrade.again));
    }
    await Future<void>.delayed(_feedbackDelay);
    if (!mounted) {
      return;
    }
    setState(() {
      _waiting = false;
      _userAnswer = [];
      _used = List<bool>.filled(puzzle.scrambled.length, false);
    });
  }

  /// Пишет ответ в SRS не больше одного раза на слово за сессию (ADR-028).
  ///
  /// Повторная запись перезаписала бы прогресс: пользователь может несколько
  /// раз собрать одно слово или ошибиться после верного ответа.
  Future<void> _record(WordId wordId, ReviewGrade grade) async {
    if (!_recorded.add(wordId)) {
      return;
    }
    try {
      await ref.read(recordReviewProvider).call(wordId, grade);
      if (!mounted) {
        return;
      }
      // Ответ меняет серию, очередь и дневную цель — как в уроке.
      ref
        ..invalidate(computeStreakProvider)
        ..invalidate(getTodayQueueProvider)
        ..invalidate(weakWordsQueueProvider)
        ..invalidate(dailyGoalProvider);
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .error('Scramble SRS record failed', error, stack);
    }
  }

  /// Переход к следующей карточке; после последней — диалог итогов.
  void _advance() {
    final next = _currentIndex + 1;
    setState(() {
      _currentIndex = next;
      _waiting = false;
      _userAnswer = [];
      _hasError = false;
      _wrongAttempts = 0;
      _helperVisible = false;
      _lastWrongAnswer = '';
      _used = List<bool>.filled(
        next < _puzzles.length ? _puzzles[next].scrambled.length : 0,
        false,
      );
    });
    if (next >= _puzzles.length) {
      unawaited(_showSummary());
    }
  }

  /// Сбрасывает собранные буквы, не меняя карточку.
  void _clear() {
    final puzzle = _puzzle;
    if (puzzle == null || _waiting) {
      return;
    }
    setState(() {
      _userAnswer = [];
      _hasError = false;
      _used = List<bool>.filled(puzzle.scrambled.length, false);
    });
  }

  void _showMessage(String text, {required bool correct}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: correct ? Colors.green : Colors.red,
          duration: const Duration(milliseconds: 700),
        ),
      );
  }

  Future<void> _showSummary() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сессия завершена'),
        content: Text('Верно: $_correctCount из ${_puzzles.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/');
            },
            child: const Text('Готово'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(_load());
            },
            child: const Text('Ещё раз'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Собери слово'),
        actions: [
          if (_puzzles.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentIndex + 1}/${_puzzles.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const _Loading()
            : puzzle == null
            ? _ErrorState(onRetry: _load)
            : _PuzzleView(
                puzzle: puzzle,
                answer: _userAnswer,
                used: _used,
                hasError: _hasError,
                shakeKey: _shakeKey,
                pulseKey: _pulseKey,
                correctCount: _correctCount,
                helperVisible: _helperVisible,
                lastWrongAnswer: _lastWrongAnswer,
                onTapLetter: _selectLetter,
                onClear: _clear,
              ),
      ),
    );
  }
}

/// Перевод-подсказка, поле ответа, облако букв и счётчики (ADR-027).
class _PuzzleView extends StatelessWidget {
  const _PuzzleView({
    required this.puzzle,
    required this.answer,
    required this.used,
    required this.hasError,
    required this.shakeKey,
    required this.pulseKey,
    required this.correctCount,
    required this.helperVisible,
    required this.lastWrongAnswer,
    required this.onTapLetter,
    required this.onClear,
  });

  final ScramblePuzzle puzzle;
  final List<String> answer;
  final List<bool> used;
  final bool hasError;
  final int shakeKey;
  final int pulseKey;
  final int correctCount;
  final bool helperVisible;
  final String lastWrongAnswer;
  final ValueChanged<int> onTapLetter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Перевод-подсказка в контейнере с лёгким акцентом (Phase 27c).
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Text(
                    puzzle.translation,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        ),
        const SizedBox(height: 8),
        Text(
          'Переведи и собери слово по буквам',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _answerField(context),
        if (helperVisible) ...[const SizedBox(height: 12), _errorCard(context)],
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < puzzle.scrambled.length; index++)
              Opacity(
                opacity: used[index] ? 0.3 : 1,
                child: FilledButton(
                  onPressed: used[index] ? null : () => onTapLetter(index),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(puzzle.scrambled[index]),
                ),
              ),
          ],
        ).animate(delay: 150.ms).fadeIn(duration: 350.ms),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('Очистить'),
            ),
            const Spacer(),
            Text(
              '$correctCount верно',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Карточка ошибки с кнопкой помощника (ADR-042).
  Widget _errorCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Неверно',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          ErrorHelperButton(
            gameType: 'word_scramble',
            context:
                'Нужно было собрать: "${puzzle.solution}". '
                'Пользователь собрал: "$lastWrongAnswer".',
          ),
        ],
      ),
    );
  }

  /// Поле ответа: N квадратов по длине слова, следующий подсвечен.
  ///
  /// Wrap, а не Row: длинное слово не влезает в одну строку на узком экране
  /// и переносится, вместо того чтобы вылезать за край (Phase 27a).
  Widget _answerField(BuildContext context) {
    final theme = Theme.of(context);
    final length = puzzle.solution.length;
    final field = Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < length; i++)
          _AnswerSquare(
            letter: i < answer.length ? answer[i] : null,
            isNext: i == answer.length && !hasError,
            hasError: hasError,
            theme: theme,
          ),
      ],
    );

    final pulsing = field
        .animate(key: ValueKey('pulse-$pulseKey'), autoPlay: pulseKey > 0)
        .scaleXY(begin: 1, end: 1.08, duration: 150.ms, curve: Curves.easeOut)
        .then()
        .scaleXY(end: 1, duration: 220.ms, curve: Curves.easeOutBack);

    return pulsing
        .animate(key: ValueKey('shake-$shakeKey'), autoPlay: shakeKey > 0)
        .shakeX(amount: 10, hz: 6, duration: 400.ms);
  }
}

/// Один квадрат поля ответа: буква, пунктир или подсветка следующего.
class _AnswerSquare extends StatelessWidget {
  const _AnswerSquare({
    required this.letter,
    required this.isNext,
    required this.hasError,
    required this.theme,
  });

  final String? letter;
  final bool isNext;
  final bool hasError;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    if (letter != null) {
      return Container(
        width: 44,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasError
              ? colors.errorContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: hasError ? Border.all(color: colors.error, width: 2) : null,
        ),
        child: Text(
          letter!,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      );
    }
    return SizedBox(
      width: 44,
      height: 56,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: isNext ? colors.primary : colors.outlineVariant,
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Готовим задание...'),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Не удалось загрузить'),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    ),
  );
}

/// Пунктирная рамка пустого слота ответа.
///
/// В Flutter нет dashed-border из коробки, а тянуть пакет ради одной рамки
/// несоразмерно: рисуем путь по метрикам RRect и режем его на штрихи.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  static const _dash = 6.0;
  static const _gap = 4.0;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
