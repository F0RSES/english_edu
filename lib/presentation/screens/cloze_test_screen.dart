import 'dart:async';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      setState(() => _solved = true);
      unawaited(HapticFeedback.mediumImpact());
    } else {
      unawaited(HapticFeedback.heavyImpact());
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Верно!' : 'Неверно'),
        backgroundColor: correct ? Colors.green : Colors.red,
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
                onCheck: () => unawaited(_check(task)),
                onNext: () => unawaited(_load()),
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
    required this.onCheck,
    required this.onNext,
  });

  final ClozeTask task;
  final TextEditingController controller;
  final bool solved;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          task.sentence,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dashed,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          enabled: !solved,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Пропущенное слово',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onCheck(),
        ),
        const SizedBox(height: 16),
        if (solved)
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Следующее задание'),
          )
        else
          FilledButton(onPressed: onCheck, child: const Text('Проверить')),
      ],
    );
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
