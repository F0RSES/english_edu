import 'dart:async';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Мини-игра «Заполни пропуск» (ADR-025).
///
/// Задание генерирует AI-прокси по случайному слову словаря и кэширует его в
/// БД, поэтому повторный показ того же слова не ходит в сеть. Пользователь
/// вписывает пропущенное слово: регистр и пробелы по краям не важны.
class ClozeTestScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const ClozeTestScreen({super.key});

  @override
  ConsumerState<ClozeTestScreen> createState() => _ClozeTestScreenState();
}

class _ClozeTestScreenState extends ConsumerState<ClozeTestScreen> {
  final _random = Random();
  final _answer = TextEditingController();

  ClozeTask? _task;
  bool _loading = true;
  bool _solved = false;
  bool _hasError = false;

  /// Меняется при ошибке: новый ключ перезапускает shake-анимацию.
  int _shakeKey = 0;

  /// Меняется при верном ответе: новый ключ перезапускает пульс.
  int _pulseKey = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  /// Берёт случайное слово словаря и задание к нему.
  ///
  /// Слово выбирается до запроса: кэш заданий ключуется по `wordId`, поэтому
  /// «Следующее задание» может вернуть уже готовое задание без сети.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _solved = false;
      _hasError = false;
      _task = null;
      _answer.clear();
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

  /// Сравнивает ввод с ответом и показывает реакцию.
  Future<void> _check(ClozeTask task) async {
    if (_solved) {
      return;
    }
    final correct = _normalize(_answer.text) == _normalize(task.answer);
    if (correct) {
      setState(() {
        _solved = true;
        _hasError = false;
        _pulseKey++;
      });
      unawaited(HapticFeedback.selectionClick());
    } else {
      setState(() {
        _hasError = true;
        _shakeKey++;
      });
      unawaited(HapticFeedback.heavyImpact());
    }
    _showFeedback(correct: correct);
  }

  /// SnackBar с реакцией; на верном ответе сразу даёт «Далее».
  ///
  /// Кнопка «Следующее задание» остаётся на экране, поэтому действие в
  /// SnackBar подписано «Далее»: два одинаковых ярлыка на одном экране
  /// сбивали бы с толку.
  void _showFeedback({required bool correct}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(correct ? 'Верно!' : 'Неверно'),
          backgroundColor: correct ? Colors.green : Colors.red,
          action: correct
              ? SnackBarAction(
                  label: 'Далее',
                  textColor: Colors.white,
                  onPressed: () => unawaited(_load()),
                )
              : null,
        ),
      );
  }

  /// Регистр и пробелы по краям не важны; пунктуация внутри ответа — тоже.
  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp('[^a-z ]'), '');

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
                controller: _answer,
                solved: _solved,
                hasError: _hasError,
                shakeKey: _shakeKey,
                pulseKey: _pulseKey,
                onCheck: () => unawaited(_check(task)),
                onNext: () => unawaited(_load()),
                onChanged: () {
                  // Пользователь начал исправлять — красная рамка больше не
                  // актуальна, иначе ошибка «прилипает» к полю.
                  if (_hasError) {
                    setState(() => _hasError = false);
                  }
                },
              ),
      ),
    );
  }
}

class _TaskView extends StatelessWidget {
  const _TaskView({
    required this.task,
    required this.controller,
    required this.solved,
    required this.hasError,
    required this.shakeKey,
    required this.pulseKey,
    required this.onCheck,
    required this.onNext,
    required this.onChanged,
  });

  /// Пропуск в предложении, который визуально подчёркивается.
  static const _blank = '___';

  final ClozeTask task;
  final TextEditingController controller;
  final bool solved;
  final bool hasError;
  final int shakeKey;
  final int pulseKey;
  final VoidCallback onCheck;
  final VoidCallback onNext;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 28),
        // Поле и кнопка появляются с задержкой: сначала читают предложение.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _animatedField(context),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: solved ? onNext : onCheck,
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
              child: Text(solved ? 'Следующее задание' : 'Проверить'),
            ),
          ],
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
      ],
    );
  }

  /// Поле ввода с двумя независимыми анимациями: shake и pulse.
  ///
  /// Каждая обёрнута в свой `Animate` со своим ключом: смена ключа
  /// пересобирает виджет и проигрывает эффект заново, а `autoPlay` не даёт
  /// тряхнуть поле при первом появлении.
  Widget _animatedField(BuildContext context) {
    final field = TextField(
      controller: controller,
      enabled: !solved,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onCheck(),
      onChanged: (_) => onChanged(),
      style: const TextStyle(fontSize: 18),
      decoration: _decoration(context),
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

  /// Оформление поля: заливка без рамки, красная на ошибке, зелёная на успехе.
  InputDecoration _decoration(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final outline = hasError
        ? colors.error
        : solved
        ? Colors.green
        : null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: outline == null
          ? BorderSide.none
          : BorderSide(color: outline, width: 2),
    );

    return InputDecoration(
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      hintText: 'Введите слово...',
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border,
      suffixIcon: solved
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack)
          : null,
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
