import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/sentence_puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Пауза после неверного ответа: тряска должна доиграть до сброса.
const _feedbackDelay = Duration(milliseconds: 800);

/// Длина сессии: после пятого предложения — итоги (Phase 35).
const _sessionLength = 5;

/// Игра «Собери предложение» (Phase 35).
///
/// Перевод-подсказка сверху; слова тапом уходят из облака в поле ответа и
/// обратно. Источник задания — `exampleSentence` словаря (офлайн), при его
/// отсутствии — AI-прокси. Прогресс в SRS не пишется: игра тренирует
/// порядок слов, а не запоминание конкретного слова.
class SentenceBuilderScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const SentenceBuilderScreen({super.key});

  @override
  ConsumerState<SentenceBuilderScreen> createState() =>
      _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends ConsumerState<SentenceBuilderScreen> {
  SentencePuzzle? _puzzle;
  bool _isLoading = true;

  /// Индексы слов в поле ответа: повторы различаются позицией, не текстом.
  List<int> _answer = [];

  bool _solved = false;
  bool _hasError = false;

  /// Идёт пауза после неверного ответа: ввод заблокирован.
  bool _waiting = false;

  int _shakeKey = 0;
  int _pulseKey = 0;
  int _solvedCount = 0;
  int _firstTryCorrect = 0;
  bool _madeMistake = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Загружает следующее задание, сохраняя счётчики сессии.
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _puzzle = null;
      _answer = [];
      _solved = false;
      _hasError = false;
      _waiting = false;
      _madeMistake = false;
    });
    try {
      final puzzle = await ref.read(generateSentencePuzzleProvider)();
      if (!mounted) {
        return;
      }
      setState(() {
        _puzzle = puzzle;
        _isLoading = false;
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Sentence puzzle failed', error, stack);
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  /// Новая сессия: счётчики обнуляются (кнопка «Ещё раз» в итогах).
  void _restart() {
    _solvedCount = 0;
    _firstTryCorrect = 0;
    unawaited(_load());
  }

  /// Тап по слову в облаке: слово уходит в поле ответа.
  void _selectWord(int index) {
    final puzzle = _puzzle;
    if (puzzle == null || _solved || _waiting || _answer.contains(index)) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _answer = [..._answer, index];
      _hasError = false;
    });
  }

  /// Тап по плашке ответа: слово возвращается в облако.
  void _removeWord(int position) {
    if (_solved || _waiting) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _answer = [..._answer]..removeAt(position);
      _hasError = false;
    });
  }

  /// Сверяет порядок слов с предложением-решением.
  Future<void> _check() async {
    final puzzle = _puzzle;
    if (puzzle == null || _solved || _waiting) {
      return;
    }
    final assembled = [for (final index in _answer) puzzle.shuffledWords[index]]
        .join(' ');
    if (assembled == puzzle.sentence) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _solved = true;
        _pulseKey++;
        _solvedCount++;
        if (!_madeMistake) {
          _firstTryCorrect++;
        }
      });
      return;
    }

    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _hasError = true;
      _shakeKey++;
      _waiting = true;
      _madeMistake = true;
    });
    await Future<void>.delayed(_feedbackDelay);
    if (!mounted) {
      return;
    }
    // Сброс: слова возвращаются в облако, задание остаётся тем же.
    setState(() {
      _answer = [];
      _hasError = false;
      _waiting = false;
    });
  }

  /// После пятого предложения — итоги, иначе следующее задание.
  void _next() {
    if (_solvedCount >= _sessionLength) {
      unawaited(_showSummary());
      return;
    }
    unawaited(_load());
  }

  Future<void> _showSummary() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.sessionDone(lang)),
        content: Text(S.sessionCorrect(_firstTryCorrect, _sessionLength, lang)),
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
              _restart();
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
        title: Text(S.gameSentenceBuilder(lang)),
        actions: [
          if (puzzle != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_solvedCount/$_sessionLength',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : puzzle == null
            ? _ErrorState(lang: lang, onRetry: _load)
            : _PuzzleView(
                puzzle: puzzle,
                answer: _answer,
                solved: _solved,
                hasError: _hasError,
                waiting: _waiting,
                shakeKey: _shakeKey,
                pulseKey: _pulseKey,
                lang: lang,
                onSelectWord: _selectWord,
                onRemoveWord: _removeWord,
                onCheck: _check,
                onNext: _next,
              ),
      ),
    );
  }
}

/// Перевод-подсказка, поле ответа, облако слов и кнопка проверки.
class _PuzzleView extends StatelessWidget {
  const _PuzzleView({
    required this.puzzle,
    required this.answer,
    required this.solved,
    required this.hasError,
    required this.waiting,
    required this.shakeKey,
    required this.pulseKey,
    required this.lang,
    required this.onSelectWord,
    required this.onRemoveWord,
    required this.onCheck,
    required this.onNext,
  });

  final SentencePuzzle puzzle;
  final List<int> answer;
  final bool solved;
  final bool hasError;
  final bool waiting;
  final int shakeKey;
  final int pulseKey;
  final AppLanguage lang;
  final ValueChanged<int> onSelectWord;
  final ValueChanged<int> onRemoveWord;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allUsed = answer.length == puzzle.shuffledWords.length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              puzzle.translation,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.sentenceInstruction(lang),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _answerField(colors),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < puzzle.shuffledWords.length; index++)
                if (!answer.contains(index))
                  FilledButton(
                    key: ValueKey('word-$index'),
                    onPressed: waiting || solved
                        ? null
                        : () => onSelectWord(index),
                    child: Text(puzzle.shuffledWords[index]),
                  ),
            ],
          ),
          const SizedBox(height: 24),
          if (solved)
            FilledButton(
              key: const ValueKey('next-button'),
              onPressed: onNext,
              child: Text(S.commonNextTask(lang)),
            )
          else
            FilledButton(
              key: const ValueKey('check-button'),
              onPressed: allUsed && !waiting ? onCheck : null,
              child: Text(S.check(lang)),
            ),
        ],
      ),
    );
  }

  /// Поле ответа: плашки слов; тап возвращает слово в облако.
  Widget _answerField(ColorScheme colors) {
    final field = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError
            ? colors.errorContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: hasError ? Border.all(color: colors.error, width: 2) : null,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var position = 0; position < answer.length; position++)
            ActionChip(
              key: ValueKey('answer-$position'),
              label: Text(puzzle.shuffledWords[answer[position]]),
              onPressed: waiting || solved
                  ? null
                  : () => onRemoveWord(position),
            ),
        ],
      ),
    );
    // Зелёная вспышка на верный ответ и тряска на неверный (Phase 29b).
    return field
        .animate(key: ValueKey('pulse-$pulseKey'), autoPlay: pulseKey > 0)
        .tint(color: Colors.green, begin: 0.3, end: 0, duration: 800.ms)
        .animate(key: ValueKey('shake-$shakeKey'), autoPlay: shakeKey > 0)
        .shakeX(amount: 10, hz: 6, duration: 400.ms);
  }
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
