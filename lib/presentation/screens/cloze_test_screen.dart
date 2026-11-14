import 'dart:async';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Пауза после неверного выбора: карточка красная, затем сброс (Phase 26b).
const _wrongResetDelay = Duration(milliseconds: 500);

/// Мини-игра «Заполни пропуск» (ADR-025, Phase 26b).
///
/// Задание генерирует AI-прокси по случайному слову словаря и кэширует его в
/// БД, поэтому повторный показ того же слова не ходит в сеть. Пользователь
/// выбирает пропущенное слово из 5 вариантов тапом — без ввода текста.
class ClozeTestScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const ClozeTestScreen({super.key});

  @override
  ConsumerState<ClozeTestScreen> createState() => _ClozeTestScreenState();
}

class _ClozeTestScreenState extends ConsumerState<ClozeTestScreen> {
  final _random = Random();

  ClozeTask? _task;
  bool _loading = true;
  bool _solved = false;

  /// Выбранный неверный вариант: карточка красная до сброса через 500 мс.
  String? _wrongOption;

  /// Идёт пауза после неверного выбора: тапы заблокированы.
  bool _waiting = false;

  /// Последний неверный вариант: контекст для помощника (ADR-042).
  String? _lastWrongOption;

  /// Меняется при ошибке: новый ключ перезапускает shake-анимацию.
  int _shakeKey = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Берёт случайное слово словаря и задание к нему.
  ///
  /// Слово выбирается до запроса: кэш заданий ключуется по `wordId`, поэтому
  /// «Следующее задание» может вернуть уже готовое задание без сети.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _solved = false;
      _wrongOption = null;
      _waiting = false;
      _lastWrongOption = null;
      _task = null;
    });
    try {
      final words = await ref.read(wordRepositoryProvider).getAll();
      if (words.isEmpty) {
        throw StateError('dictionary is empty');
      }
      final word = words[_random.nextInt(words.length)];
      final task = await ref.read(getClozeTaskProvider)(word.id, word.term);
      if (!mounted) {
        return;
      }
      setState(() {
        _task = task;
        _loading = false;
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Cloze task failed', error, stack);
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  /// Тап по варианту: верный закрывает задание, неверный сбрасывается.
  Future<void> _choose(ClozeTask task, String option) async {
    if (_solved || _waiting) {
      return;
    }
    final correct =
        option.trim().toLowerCase() == task.correctWord.trim().toLowerCase();
    if (correct) {
      unawaited(HapticFeedback.selectionClick());
      setState(() {
        _solved = true;
        _wrongOption = null;
        _lastWrongOption = null;
      });
      _showSuccess();
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _wrongOption = option;
      _lastWrongOption = option;
      _waiting = true;
      _shakeKey++;
    });
    await Future<void>.delayed(_wrongResetDelay);
    if (!mounted) {
      return;
    }
    setState(() {
      _wrongOption = null;
      _waiting = false;
    });
  }

  /// SnackBar «Верно!» с действием «Далее».
  void _showSuccess() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Верно!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Далее',
            textColor: Colors.white,
            onPressed: () => unawaited(_load()),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return Scaffold(
      appBar: AppBar(title: const Text('Заполни пропуск')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : task == null
            ? _ErrorState(onRetry: _load)
            : _TaskView(
                task: task,
                solved: _solved,
                wrongOption: _wrongOption,
                lastWrongOption: _lastWrongOption,
                shakeKey: _shakeKey,
                onChoose: (option) => unawaited(_choose(task, option)),
                onNext: () => unawaited(_load()),
              ),
      ),
    );
  }
}

class _TaskView extends StatelessWidget {
  const _TaskView({
    required this.task,
    required this.solved,
    required this.wrongOption,
    required this.lastWrongOption,
    required this.shakeKey,
    required this.onChoose,
    required this.onNext,
  });

  /// Пропуск в предложении, который визуально подчёркивается.
  static const _blank = '___';

  final ClozeTask task;
  final bool solved;
  final String? wrongOption;
  final String? lastWrongOption;
  final int shakeKey;
  final ValueChanged<String> onChoose;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Предложение в карточке: текст не висит на голом фоне (Phase 27c).
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Text.rich(
                      TextSpan(
                        children: _sentenceSpans(
                          task.sentence,
                          TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.primary,
                            decorationThickness: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.45,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: ListView(
            children: [
              for (final option in task.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionCard(
                    option: option,
                    state: solved && _isCorrect(option)
                        ? _OptionState.correct
                        : option == wrongOption
                        ? _OptionState.wrong
                        : _OptionState.idle,
                    enabled: !solved,
                    shakeKey: shakeKey,
                    onTap: () => onChoose(option),
                  ),
                ),
              if (lastWrongOption != null && !solved) ...[
                const SizedBox(height: 4),
                _errorCard(context),
              ],
            ],
          ),
        ),
        if (solved)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton(
              onPressed: onNext,
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
              child: const Text('Следующее задание'),
            ),
          ),
      ],
    );
  }

  bool _isCorrect(String option) =>
      option.trim().toLowerCase() == task.correctWord.trim().toLowerCase();

  /// Карточка ошибки с кнопкой помощника: живёт до следующего выбора (ADR-042).
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
            gameType: 'cloze_test',
            context:
                'Предложение: "${task.sentence}". '
                'Пользователь выбрал: "$lastWrongOption". '
                'Правильный ответ: "${task.correctWord}".',
          ),
        ],
      ),
    );
  }

  /// Разбивает предложение на спаны, подчёркивая только пропуск.
  ///
  /// Плоский текст остаётся исходным (`toPlainText`), поэтому поиск по тексту
  /// в тестах и для accessibility видит то же предложение.
  List<InlineSpan> _sentenceSpans(String sentence, TextStyle blankStyle) {
    final spans = <InlineSpan>[];
    var rest = sentence;
    while (true) {
      final index = rest.indexOf(_blank);
      if (index < 0) {
        spans.add(TextSpan(text: rest));
        return spans;
      }
      if (index > 0) {
        spans.add(TextSpan(text: rest.substring(0, index)));
      }
      spans.add(TextSpan(text: _blank, style: blankStyle));
      rest = rest.substring(index + _blank.length);
      if (rest.isEmpty) {
        return spans;
      }
    }
  }
}

/// Состояние карточки-варианта (Phase 26b).
enum _OptionState { idle, correct, wrong }

/// Карточка варианта: тап, зелёная на успех, красная + shake на ошибке.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.state,
    required this.enabled,
    required this.shakeKey,
    required this.onTap,
  });

  final String option;
  final _OptionState state;
  final bool enabled;
  final int shakeKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color background;
    Color foreground;
    Color? border;
    switch (state) {
      case _OptionState.correct:
        background = Colors.green.shade50;
        foreground = Colors.green.shade800;
        border = Colors.green;
      case _OptionState.wrong:
        background = colors.errorContainer;
        foreground = colors.onErrorContainer;
        border = colors.error;
      case _OptionState.idle:
        background = colors.surfaceContainerHighest;
        foreground = colors.onSurface;
        border = null;
    }
    final card = Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('option-$option'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: border == null ? null : Border.all(color: border, width: 2),
          ),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
    if (state == _OptionState.wrong) {
      return card
          .animate(key: ValueKey('shake-$shakeKey'), autoPlay: true)
          .shakeX(amount: 8, hz: 6, duration: 400.ms);
    }
    return card;
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
