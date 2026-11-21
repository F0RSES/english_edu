import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Лист массового добавления слов из задания в словарь (Phase 30b).
///
/// Контент для `AppBottomSheet.show` (Phase 53c): отступы и SafeArea
/// даёт шторка. Переводы грузятся параллельно: на каждое слово — свой
/// лоадер, ошибка одного слова не блокирует остальные. Иконка действия —
/// по статусу прогресса (Phase 52b, ADR-004): «+» добавляет в «Изучаю»,
/// корзина убирает из «Изучаю» без удаления слова. Наличие слова в БД
/// само по себе корзину не показывает: seed-слова не считаются
/// добавленными.
class BulkDictionarySheet extends ConsumerWidget {
  /// Создаёт лист для слов [words].
  const BulkDictionarySheet({required this.words, super.key});

  /// Слова задания (варианты ответа).
  final List<String> words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final theme = Theme.of(context);
    // Скролл снаружи (Phase 53c): строки — дети Column, без вложенного
    // ListView, иначе жесты скролла конфликтовали бы.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.wordsInTask(lang),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          for (final word in words) _BulkWordRow(word: word),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.close(lang)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка слова: перевод + кнопка действия по статусу (Phase 30b, 52b).
///
/// Перевод и слово из БД грузятся параллельно (record `.wait`), статус —
/// из прогресса; у строки свой лоадер и свой retry при ошибке.
class _BulkWordRow extends ConsumerStatefulWidget {
  const _BulkWordRow({required this.word});

  final String word;

  @override
  ConsumerState<_BulkWordRow> createState() => _BulkWordRowState();
}

class _BulkWordRowState extends ConsumerState<_BulkWordRow> {
  WordTranslation? _translation;
  Object? _error;
  Word? _existing;
  WordStatus? _status;
  bool _loading = true;
  bool _busy = false;

  /// Корзина только для «Изучаю»: наличие слова в БД не считается
  /// добавлением (Phase 52b, ADR-004).
  bool get _isLearning => _status == WordStatus.learning;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (translation, existing) = await (
        ref.read(translationGeneratorProvider).translate(widget.word),
        ref.read(wordRepositoryProvider).findByTerm(widget.word),
      ).wait;
      WordStatus? status;
      if (existing != null) {
        final progress = await ref
            .read(progressRepositoryProvider)
            .getByWordId(existing.id);
        status = progress?.status;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _translation = translation;
        _existing = existing;
        _status = status;
        _loading = false;
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Bulk translate failed', error, stack);
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _addToLearning() async {
    final translation = _translation;
    if (_busy || translation == null) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _busy = true);
    try {
      final words = ref.read(wordRepositoryProvider);
      var word = _existing;
      if (word == null) {
        final settings = await ref.read(settingsRepositoryProvider).get();
        final id = await words.nextId();
        word = Word(
          id: id,
          term: widget.word.trim().toLowerCase(),
          translation: translation.text,
          transcription: translation.transcription,
          partOfSpeech: translation.partOfSpeech,
          exampleSentence: translation.example,
          level: settings.preferredLevel,
        );
        await words.upsert(word);
      }
      // Сразу «Изучаю»: добавленное из игр слово не лежит в «Новом»
      // (паттерн Phase 51, ADR-004).
      await ref.read(updateWordStatusProvider)(word.id, WordStatus.learning);
      if (!mounted) {
        return;
      }
      setState(() {
        _existing = word;
        _status = WordStatus.learning;
        _busy = false;
      });
      ref.invalidate(dictionaryEntriesProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.wordAddedToLearning(lang))));
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Bulk add failed', error, stack);
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.wordSaveFailed(lang))));
      }
    }
  }

  Future<void> _removeFromLearning() async {
    final existing = _existing;
    if (_busy || existing == null) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _busy = true);
    try {
      // Убираем из изучения: прогресс удаляется, слово остаётся в словаре
      // как «Новое» (Phase 52b); seed-слова не удаляются.
      await ref.read(progressRepositoryProvider).deleteByWordId(existing.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _status = null;
        _busy = false;
      });
      ref.invalidate(dictionaryEntriesProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.wordRemovedFromLearning(lang))));
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Bulk remove failed', error, stack);
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.wordSaveFailed(lang))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final translation = _translation;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.word,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_error != null)
                  Text(
                    S.hintFailed(lang),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                else if (translation != null)
                  Text(
                    translation.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (_loading)
            const SizedBox.shrink()
          else if (_error != null)
            IconButton(
              tooltip: S.retry(lang),
              icon: const Icon(Icons.refresh),
              onPressed: () => unawaited(_load()),
            )
          else
            IconButton(
              tooltip: _isLearning
                  ? S.removeFromLearning(lang)
                  : S.addToLearning(lang),
              color: _isLearning
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              onPressed: _busy
                  ? null
                  : _isLearning
                  ? () => unawaited(_removeFromLearning())
                  : () => unawaited(_addToLearning()),
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isLearning
                          ? Icons.delete_outline
                          : Icons.add_circle_outline,
                    ),
            ),
        ],
      ),
    );
  }
}
