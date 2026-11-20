import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/scramble_puzzle.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/ai_word_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Пауза после ответа: пользователь должен успеть увидеть результат.
const _feedbackDelay = Duration(milliseconds: 800);

/// Мини-игра «Собери слово» (ADR-027).
///
/// Показывает перевод и перемешанные буквы; слово собирается тапом по буквам,
/// а тап по поставленной букве возвращает её в пул (Phase 52c).
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

  /// Слова, чей прогресс уже записан в этой сессии (ADR-028).
  final Set<WordId> _recorded = {};

  /// Порог, после которого слово считается проваленным.
  static const _failedAttempts = 3;

  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    // SnackBar живёт на корневом messenger: без этого он переживает экран
    // и всплывает поверх Home (Phase 29b).
    _messenger?.hideCurrentSnackBar();
    super.dispose();
  }

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

  /// Убирает букву из клетки [position] и возвращает её в пул (Phase 52c).
  ///
  /// Ответ сдвигается влево; автопроверка срабатывает только на полном
  /// ответе, поэтому удаление буквы не запускает проверку.
  void _removeLetter(int position) {
    final puzzle = _puzzle;
    if (puzzle == null || _waiting || position >= _userAnswer.length) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    final letter = _userAnswer[position];
    // Буквы повторяются: освобождаем первую использованную кнопку пула
    // с этой буквой — иначе баланс букв сломается (например, две «p»).
    var poolIndex = -1;
    for (var i = 0; i < puzzle.scrambled.length; i++) {
      if (_used[i] && puzzle.scrambled[i] == letter) {
        poolIndex = i;
        break;
      }
    }
    if (poolIndex < 0) {
      return;
    }
    setState(() {
      _userAnswer = [..._userAnswer]..removeAt(position);
      _used = [..._used]..[poolIndex] = false;
      _hasError = false;
    });
  }

  /// Сверяет собранное слово с решением и показывает реакцию.
  Future<void> _check(ScramblePuzzle puzzle) async {
    if (_userAnswer.join().toLowerCase() == puzzle.solution) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _correctCount++;
        _pulseKey++;
        _waiting = true;
      });
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
    });
    // Ошибка видна по красной тряске поля; перевод и добавление слова —
    // через кнопку «Добавить в словарь» (Phase 30c).
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
        ..invalidate(dailyGoalProvider)
        // Профиль читает ачивки и аналитику (Phase 30a).
        ..invalidate(achievementsProvider)
        ..invalidate(analyticsProvider);
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

  Future<void> _showSummary() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.sessionDone(lang)),
        content: Text(S.sessionCorrect(_correctCount, _puzzles.length, lang)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/');
            },
            child: Text(S.sessionFinish(lang)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(_load());
            },
            child: Text(S.commonAgain(lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.gameTitle('scramble', lang)),
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
            ? _Loading(lang: lang)
            : puzzle == null
            ? _ErrorState(lang: lang, onRetry: _load)
            : _PuzzleView(
                puzzle: puzzle,
                answer: _userAnswer,
                used: _used,
                hasError: _hasError,
                shakeKey: _shakeKey,
                pulseKey: _pulseKey,
                correctCount: _correctCount,
                lang: lang,
                onTapLetter: _selectLetter,
                onRemoveLetter: _removeLetter,
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
    required this.lang,
    required this.onTapLetter,
    required this.onRemoveLetter,
    required this.onClear,
  });

  final ScramblePuzzle puzzle;
  final List<String> answer;
  final List<bool> used;
  final bool hasError;
  final int shakeKey;
  final int pulseKey;
  final int correctCount;
  final AppLanguage lang;
  final ValueChanged<int> onTapLetter;

  /// Тап по поставленной букве: возврат в пул (Phase 52c).
  final ValueChanged<int> onRemoveLetter;

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
          S.scrambleInstruction(lang),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _answerField(context),
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
        const SizedBox(height: 16),
        // Добавление загаданного слова в словарь (Phase 30c).
        AddToDictionaryButton(word: puzzle.solution),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.backspace_outlined),
              label: Text(S.scrambleClear(lang)),
            ),
            const Spacer(),
            Text(
              S.scrambleCorrectCount(correctCount, lang),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
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
            key: ValueKey('answer-square-$i'),
            letter: i < answer.length ? answer[i] : null,
            isNext: i == answer.length && !hasError,
            hasError: hasError,
            theme: theme,
            onTap: i < answer.length ? () => onRemoveLetter(i) : null,
          ),
      ],
    );

    final pulsing = field
        .animate(key: ValueKey('pulse-$pulseKey'), autoPlay: pulseKey > 0)
        .scaleXY(begin: 1, end: 1.08, duration: 150.ms, curve: Curves.easeOut)
        .then()
        .scaleXY(end: 1, duration: 220.ms, curve: Curves.easeOutBack);

    // Зелёная вспышка на 800 мс — синхронно с паузой перед переходом
    // к следующему слову: успех виден без SnackBar (Phase 29b).
    final green = pulsing
        .animate(key: ValueKey('green-$pulseKey'), autoPlay: pulseKey > 0)
        .tint(color: Colors.green, begin: 0.3, end: 0, duration: 800.ms);

    return green
        .animate(key: ValueKey('shake-$shakeKey'), autoPlay: shakeKey > 0)
        .shakeX(amount: 10, hz: 6, duration: 400.ms);
  }
}

/// Один квадрат поля ответа: буква, пунктир или подсветка следующего.
///
/// Тап по поставленной букве возвращает её в пул (Phase 52c). Буква
/// появляется в клетке пружинным масштабом (easeOutBack), а не телепортом.
class _AnswerSquare extends StatelessWidget {
  const _AnswerSquare({
    required this.letter,
    required this.isNext,
    required this.hasError,
    required this.theme,
    required this.onTap,
    super.key,
  });

  static const _squareWidth = 44.0;
  static const _squareHeight = 56.0;

  /// Длительность пружинного появления/исчезновения буквы.
  static const _popDuration = Duration(milliseconds: 250);

  final String? letter;
  final bool isNext;
  final bool hasError;
  final ThemeData theme;

  /// Тап по поставленной букве; null — клетка пуста.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final letter = this.letter;
    final filled = letter != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _squareWidth,
        height: _squareHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? hasError
                    ? colors.errorContainer
                    : colors.surfaceContainerHighest
              : null,
          borderRadius: BorderRadius.circular(8),
          border: filled && hasError
              ? Border.all(color: colors.error, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!filled)
              CustomPaint(
                size: const Size(_squareWidth, _squareHeight),
                painter: _DashedBorderPainter(
                  color: isNext ? colors.primary : colors.outlineVariant,
                ),
              ),
            AnimatedSwitcher(
              duration: _popDuration,
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: filled
                  ? Text(
                      letter,
                      key: ValueKey(letter),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(S.scramblePreparing(lang)),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.lang, required this.onRetry});

  final AppLanguage lang;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(S.commonLoadFailed(lang)),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: Text(S.retry(lang))),
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
