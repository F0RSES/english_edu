import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Пауза после верного ответа перед следующей карточкой.
const _feedbackDelay = Duration(milliseconds: 800);

/// Аудио-диктант (ADR-028).
///
/// TTS читает слово, пользователь печатает услышанное. Ответ сразу уходит в
/// SRS через `RecordReview` (BL-71), поэтому диктант — не развлечение, а
/// способ повлиять на расписание слов. Правильный ответ показывается только
/// после ошибки: иначе подсказка убивала бы смысл упражнения.
class ListeningDictationScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const ListeningDictationScreen({super.key});

  @override
  ConsumerState<ListeningDictationScreen> createState() =>
      _ListeningDictationScreenState();
}

class _ListeningDictationScreenState
    extends ConsumerState<ListeningDictationScreen> {
  final _controller = TextEditingController();

  List<Word> _queue = const [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  int _shakeKey = 0;
  int _pulseKey = 0;
  int _correctCount = 0;

  /// Показан правильный ответ: карточка ждёт «Следующее слово».
  bool _revealed = false;

  /// Идёт пауза после верного ответа: ввод заблокирован.
  bool _waiting = false;

  /// Слова, чей ответ уже записан в SRS: повторно не пишем (ADR-028).
  final Set<WordId> _recorded = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Word? get _word =>
      _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  /// Собирает новую сессию и читает первое слово.
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _queue = const [];
      _currentIndex = 0;
      _correctCount = 0;
      _revealed = false;
      _waiting = false;
      _hasError = false;
      _recorded.clear();
      _controller.clear();
    });
    try {
      final queue = await ref.read(generateDictationQueueProvider)();
      if (!mounted) {
        return;
      }
      setState(() {
        _queue = queue;
        _isLoading = false;
      });
      if (queue.isNotEmpty) {
        await _speak(queue.first.term);
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Dictation queue failed', error, stack);
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  /// Озвучивает [term] настройками из `UserSettings`.
  ///
  /// Ошибка плагина не ломает диктант: логируем и показываем подсказку, что
  /// озвучка недоступна — слово всё равно можно ввести, если пользователь
  /// помнит его.
  Future<void> _speak(String term) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).get();
      await ref
          .read(ttsProvider)
          .speak(term, voice: settings.ttsVoice, speed: settings.ttsSpeed);
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Dictation TTS failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Озвучка недоступна')));
      }
    }
  }

  /// Повторное прослушивание текущего слова.
  void _repeat() {
    final word = _word;
    if (word == null) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    unawaited(_speak(word.term));
  }

  /// Сверяет ввод с услышанным словом и записывает ответ в SRS.
  Future<void> _check() async {
    final word = _word;
    if (word == null || _waiting || _revealed) {
      return;
    }
    final input = _controller.text.trim().toLowerCase();
    final expected = word.term.trim().toLowerCase();
    if (input.isEmpty) {
      return;
    }

    if (input == expected) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _correctCount++;
        _hasError = false;
        _pulseKey++;
        _waiting = true;
      });
      _showMessage('Правильно!', correct: true);
      await _record(word.id, ReviewGrade.good);
      await Future<void>.delayed(_feedbackDelay);
      if (!mounted) {
        return;
      }
      _nextWord();
      return;
    }

    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _hasError = true;
      _shakeKey++;
      _revealed = true;
    });
    // «Неверно» показывает persistent-карточка рядом с раскрытым ответом:
    // SnackBar исчезает, а объяснение нужно позже (ADR-042).
    await _record(word.id, ReviewGrade.again);
  }

  /// Пишет ответ в SRS один раз на слово за сессию (ADR-028).
  ///
  /// Повторная запись того же слова перезаписала бы прогресс «угадыванием»:
  /// в диктанте пользователь может нажать Enter несколько раз подряд.
  Future<void> _record(WordId wordId, ReviewGrade grade) async {
    if (!_recorded.add(wordId)) {
      return;
    }
    try {
      await ref.read(recordReviewProvider).call(wordId, grade);
      if (!mounted) {
        return;
      }
      _invalidateHome();
    } on Object catch (error, stack) {
      // Сбой записи не должен обрывать сессию: ответ просто не попадёт в SRS.
      ref
          .read(loggerProvider)
          .error('Dictation SRS record failed', error, stack);
    }
  }

  /// Сбрасывает кэш главного экрана: ответы изменили серию, очередь и цель.
  void _invalidateHome() {
    ref
      ..invalidate(computeStreakProvider)
      ..invalidate(getTodayQueueProvider)
      ..invalidate(weakWordsQueueProvider)
      ..invalidate(dailyGoalProvider);
  }

  /// Переход к следующему слову (или диалог итогов после последнего).
  void _nextWord() {
    final next = _currentIndex + 1;
    setState(() {
      _currentIndex = next;
      _waiting = false;
      _revealed = false;
      _hasError = false;
      _controller.clear();
    });
    if (next >= _queue.length) {
      unawaited(_showSummary());
      return;
    }
    unawaited(_speak(_queue[next].term));
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
        content: Text('Верно: $_correctCount из ${_queue.length}'),
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
    final word = _word;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аудио-диктант'),
        actions: [
          if (_queue.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${_currentIndex + 1}/${_queue.length}'),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : word == null
            ? _ErrorState(onRetry: _load)
            : _DictationView(
                word: word,
                controller: _controller,
                revealed: _revealed,
                hasError: _hasError,
                shakeKey: _shakeKey,
                pulseKey: _pulseKey,
                onRepeat: _repeat,
                onCheck: () => unawaited(_check()),
                onNext: _nextWord,
                onChanged: () {
                  // Пользователь правит ввод — красная рамка больше не нужна.
                  if (_hasError) {
                    setState(() => _hasError = false);
                  }
                },
              ),
      ),
    );
  }
}

/// Кнопка динамика, поле ввода, раскрытый ответ и кнопка действия.
class _DictationView extends StatelessWidget {
  const _DictationView({
    required this.word,
    required this.controller,
    required this.revealed,
    required this.hasError,
    required this.shakeKey,
    required this.pulseKey,
    required this.onRepeat,
    required this.onCheck,
    required this.onNext,
    required this.onChanged,
  });

  final Word word;
  final TextEditingController controller;
  final bool revealed;
  final bool hasError;
  final int shakeKey;
  final int pulseKey;
  final VoidCallback onRepeat;
  final VoidCallback onCheck;
  final VoidCallback onNext;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              IconButton(
                    onPressed: onRepeat,
                    iconSize: 48,
                    padding: const EdgeInsets.all(30),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                    icon: const Icon(Icons.volume_up),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.85, 0.85)),
              const SizedBox(height: 8),
              Text(
                'Нажми, чтобы услышать ещё раз',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _field(context),
        if (revealed) ...[
          const SizedBox(height: 16),
          _RevealedAnswer(word: word),
          const SizedBox(height: 12),
          _errorCard(context),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: revealed ? onNext : onCheck,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(revealed ? 'Следующее слово' : 'Проверить'),
        ),
      ],
    );
  }

  /// Карточка ошибки с кнопкой помощника: живёт до следующего слова (ADR-042).
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
            gameType: 'listening',
            context:
                'Слово: "${word.term}". '
                'Пользователь ввёл: "${controller.text}".',
          ),
        ],
      ),
    );
  }

  /// Поле ввода: заливка без рамки, красная на ошибке, зелёная на успехе.
  Widget _field(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final outline = hasError
        ? colors.error
        : pulseKey > 0
        ? Colors.green
        : null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: outline == null
          ? BorderSide.none
          : BorderSide(color: outline, width: 2),
    );

    final field = TextField(
      controller: controller,
      enabled: !revealed,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onCheck(),
      onChanged: (_) => onChanged(),
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        hintText: 'Введите слово...',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border,
      ),
    );

    final pulsing = field
        .animate(key: ValueKey('pulse-$pulseKey'), autoPlay: pulseKey > 0)
        .scaleXY(begin: 1, end: 1.04, duration: 150.ms, curve: Curves.easeOut)
        .then()
        .scaleXY(end: 1, duration: 220.ms, curve: Curves.easeOutBack);

    return pulsing
        .animate(key: ValueKey('shake-$shakeKey'), autoPlay: shakeKey > 0)
        .shakeX(amount: 10, hz: 6, duration: 400.ms);
  }
}

/// Правильный ответ после ошибки: слово и транскрипция.
class _RevealedAnswer extends StatelessWidget {
  const _RevealedAnswer({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                word.term,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (word.transcription case final transcription?)
                Text(
                  transcription,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.secondary,
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
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
