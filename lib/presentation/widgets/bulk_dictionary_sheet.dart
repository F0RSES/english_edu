import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Лист массового добавления слов из задания в словарь (Phase 30b).
///
/// Переводы грузятся параллельно: на каждое слово — свой лоадер, ошибка
/// одного слова не блокирует остальные. Удаление — без подтверждения:
/// массовый инструмент, слово можно вернуть (в AiWordHelper — с confirm).
class BulkDictionarySheet extends ConsumerWidget {
  /// Создаёт лист для слов [words].
  const BulkDictionarySheet({required this.words, super.key});

  /// Слова задания (варианты ответа).
  final List<String> words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [for (final word in words) _BulkWordRow(word: word)],
              ),
            ),
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
      ),
    );
  }
}

/// Строка слова: перевод + кнопка добавления/удаления (Phase 30b).
///
/// Перевод и наличие в словаре грузятся параллельно (record `.wait`),
/// у строки свой лоадер и свой retry при ошибке.
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
  bool _loading = true;
  bool _busy = false;

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
      if (!mounted) {
        return;
      }
      setState(() {
        _translation = translation;
        _existing = existing;
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

  Future<void> _add() async {
    final translation = _translation;
    if (_busy || translation == null) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _busy = true);
    try {
      final words = ref.read(wordRepositoryProvider);
      final settings = await ref.read(settingsRepositoryProvider).get();
      final id = await words.nextId();
      final word = Word(
        id: id,
        term: widget.word.trim().toLowerCase(),
        translation: translation.text,
        transcription: translation.transcription,
        partOfSpeech: translation.partOfSpeech,
        exampleSentence: translation.example,
        level: settings.preferredLevel,
      );
      await words.upsert(word);
      if (!mounted) {
        return;
      }
      setState(() {
        _existing = word;
        _busy = false;
      });
      ref.invalidate(dictionaryEntriesProvider);
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Bulk add failed', error, stack);
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.wordSaveFailed(lang))));
      }
    }
  }

  Future<void> _remove() async {
    final existing = _existing;
    if (_busy || existing == null) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _busy = true);
    try {
      await ref.read(wordRepositoryProvider).delete(existing.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _existing = null;
        _busy = false;
      });
      ref.invalidate(dictionaryEntriesProvider);
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
              tooltip: _existing != null
                  ? S.removeFromDictionary(lang)
                  : S.addToDictionary(lang),
              color: _existing != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              onPressed: _busy
                  ? null
                  : _existing != null
                  ? () => unawaited(_remove())
                  : () => unawaited(_add()),
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _existing != null
                          ? Icons.delete_outline
                          : Icons.add_circle_outline,
                    ),
            ),
        ],
      ),
    );
  }
}
