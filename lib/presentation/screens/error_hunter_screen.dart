import 'dart:async';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Сравнение слов без регистра и пунктуации: «Book,» == «book».
String _normalizeWord(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-zа-яё]'), '');

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
      // Слова строго выбранного уровня (Phase 28b): раньше игра брала весь
      // словарь и могла дать задание выше уровня пользователя.
      final settings = await ref.read(settingsRepositoryProvider).get();
      final words = await ref
          .read(wordRepositoryProvider)
          .getByLevel(settings.preferredLevel);
      if (words.isEmpty) {
        throw StateError('dictionary is empty');
      }
      final word = words[_random.nextInt(words.length)];
      final task = await ref.read(generateErrorTaskProvider)(word.term);
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
    if (_solved || _normalizeWord(chunk) != _normalizeWord(task.wrongWord)) {
      return;
    }
    final solved = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => _OptionsSheet(task: task),
    );
    if (solved != true || !mounted) {
      return;
    }
    setState(() => _solved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Верно!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Scaffold(
      appBar: AppBar(title: Text(S.gameTitle('errorHunter', lang))),
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
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search, size: 16, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Найди ошибку и нажми на слово',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Предложение в контейнере: фон на тон ниже подсветки слов, чтобы
        // кликабельные слова не сливались с фоном (Phase 28b).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chunk in task.sentence.split(' '))
                _wordChip(context, chunk),
            ],
          ),
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

  /// Слово предложения: до ответа — кликабельная подсветка primary, после —
  /// ошибочное слово заменено на правильное и выделено зелёным (Phase 28b).
  Widget _wordChip(BuildContext context, String chunk) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isWrong = _normalizeWord(chunk) == _normalizeWord(task.wrongWord);
    final corrected = solved && isWrong;
    return InkWell(
      onTap: solved ? null : () => onWordTap(chunk),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: corrected
              ? Colors.green.withValues(alpha: 0.15)
              : solved
              ? null
              : colors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: corrected
              ? Border.all(color: Colors.green)
              : solved
              ? null
              : Border.all(color: colors.primary),
        ),
        child: Text(
          corrected ? task.correctWord : chunk,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: solved ? null : FontWeight.w600,
          ),
        ),
      ),
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
        const Text('Не удалось сгенерировать задание, попробуйте еще раз'),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    ),
  );
}

/// Лист с вариантами: правильный вспыхивает зелёным, неверный трясётся.
///
/// Лист не закрывается на ошибке — можно попробовать снова, не открывая
/// заново. При верном ответе закрывается сам и отдаёт `true`.
class _OptionsSheet extends StatefulWidget {
  const _OptionsSheet({required this.task});

  final ErrorHunterTask task;

  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
  String? _wrongOption;
  String? _correctOption;
  int _shakeCount = 0;

  Future<void> _choose(String option) async {
    if (option == widget.task.correctWord) {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _correctOption = option);
      // Даём вспышке доиграть, прежде чем закрывать лист.
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    if (!mounted) {
      return;
    }
    setState(() {
      _wrongOption = option;
      _shakeCount++;
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Ошибка'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Как правильно?'),
          ),
          for (final option in widget.task.options)
            ListTile(
                  key: ValueKey('option-$option'),
                  title: Text(option),
                  selected: option == _correctOption,
                  selectedTileColor: Colors.green.withValues(alpha: 0.15),
                  textColor: option == _correctOption
                      ? Colors.green.shade800
                      : theme.colorScheme.onSurface,
                  onTap: () => _choose(option),
                )
                .animate(
                  key: ValueKey(
                    'option-$option-$_shakeCount-${option == _wrongOption}',
                  ),
                )
                .shakeX(
                  amount: option == _wrongOption ? 6 : 0,
                  duration: 300.ms,
                ),
          if (_wrongOption != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _errorCard(context),
            ),
          ],
        ],
      ),
    );
  }

  /// Карточка ошибки с кнопкой помощника внутри листа вариантов (ADR-042).
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
            gameType: 'error_hunter',
            context:
                'Предложение: "${widget.task.sentence}". '
                'Пользователь выбрал: "$_wrongOption". '
                'Правильный ответ: "${widget.task.correctWord}".',
          ),
        ],
      ),
    );
  }
}
