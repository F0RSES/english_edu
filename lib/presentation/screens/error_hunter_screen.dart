import 'dart:async';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Мини-игра «Охота на ошибки» (Phase 8).
///
/// Задание генерирует AI-прокси по случайному слову из словаря. Пользователь
/// находит ошибочное слово в предложении и выбирает правильный вариант:
/// неверный ответ не закрывает задание, верный открывает «Следующее».
class ErrorHunterScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const ErrorHunterScreen({super.key});

  @override
  ConsumerState<ErrorHunterScreen> createState() => _ErrorHunterScreenState();
}

class _ErrorHunterScreenState extends ConsumerState<ErrorHunterScreen> {
  final _random = Random();

  ErrorHunterTask? _task;
  bool _loading = true;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Загружает новое задание по случайному слову словаря.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _solved = false;
      _task = null;
    });
    try {
      final words = await ref.read(wordRepositoryProvider).getAll();
      if (words.isEmpty) {
        throw StateError('dictionary is empty');
      }
      final word = words[_random.nextInt(words.length)];
      final task = await ref
          .read(errorTaskGeneratorProvider)
          .generateErrorTask(word.term);
      if (!mounted) {
        return;
      }
      setState(() {
        _task = task;
        _loading = false;
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Error hunter task failed', error, stack);
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  /// Реакция на тап по слову предложения.
  ///
  /// Реагируем только на ошибочное слово: остальные — просто текст, иначе
  /// пользователь тыкал бы вслепую.
  Future<void> _onWordTap(ErrorHunterTask task, String chunk) async {
    if (_solved || _normalize(chunk) != _normalize(task.wrongWord)) {
      return;
    }
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Как правильно?'),
            ),
            for (final option in task.options)
              ListTile(
                title: Text(option),
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) {
      return;
    }
    if (chosen == task.correctWord) {
      setState(() => _solved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Верно!'), backgroundColor: Colors.green),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ошибка'), backgroundColor: Colors.red),
    );
  }

  /// Сравнивает слова без регистра и пунктуации: «Book,» == «book».
  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp('[^a-zа-яё]'), '');

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return Scaffold(
      appBar: AppBar(title: const Text('Охота на ошибки')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : task == null
            ? _ErrorState(onRetry: _load)
            : _TaskView(
                task: task,
                solved: _solved,
                onWordTap: (chunk) => _onWordTap(task, chunk),
                onNext: _load,
              ),
      ),
    );
  }
}

class _TaskView extends StatelessWidget {
  const _TaskView({
    required this.task,
    required this.solved,
    required this.onWordTap,
    required this.onNext,
  });

  final ErrorHunterTask task;
  final bool solved;
  final void Function(String chunk) onWordTap;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Найди ошибку и нажми на слово',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chunk in task.sentence.split(' '))
              InkWell(
                onTap: solved ? null : () => onWordTap(chunk),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(chunk, style: theme.textTheme.titleLarge),
                ),
              ),
          ],
        ),
        const Spacer(),
        if (solved)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('Следующее задание'),
            ),
          ),
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
        const Text('Не удалось загрузить задание'),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    ),
  );
}
