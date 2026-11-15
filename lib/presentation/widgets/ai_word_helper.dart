import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI-помощник по слову (Phase 28b): словарный перевод через прокси и
/// добавление/удаление слова из словаря.
///
/// Перевод запрашивается только по явному тапу (паттерн ADR-019): учебный
/// цикл остаётся офлайн. В отличие от подсказки-ассоциации (`GetWordHint`),
/// результат — словарный перевод, пригодный для сохранения в словарь.
class AiWordHelper extends ConsumerStatefulWidget {
  /// Создаёт помощник для слова [word].
  ///
  /// [revealWord] = false — до ответа в игре: вместо слова кнопка
  /// «Не знаю слово», чтобы не раскрывать ответ раньше времени.
  const AiWordHelper({
    required this.word,
    this.revealWord = true,
    this.iconSize = 20,
    super.key,
  });

  /// Слово, которое переводим.
  final String word;

  /// Показывать ли само слово до запроса перевода.
  final bool revealWord;

  /// Размер иконки бота: у пропуска в cloze — компактнее (Phase 30b).
  final double iconSize;

  @override
  ConsumerState<AiWordHelper> createState() => _AiWordHelperState();
}

class _AiWordHelperState extends ConsumerState<AiWordHelper> {
  bool _loading = false;

  /// Запрашивает перевод и открывает лист; ошибка — SnackBar, игра жива.
  Future<void> _openSheet() async {
    if (_loading) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _loading = true);
    final translation = await fetchWordTranslation(context, ref, widget.word);
    if (!mounted) {
      return;
    }
    // Loading снимается до открытия листа: иначе спиннер под модалкой
    // анимируется бесконечно и pumpAndSettle в тестах не завершается.
    setState(() => _loading = false);
    if (translation == null) {
      return;
    }
    await _openTranslationModal(
      context,
      widget.word,
      translation,
      lang,
      revealWord: widget.revealWord,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    if (!widget.revealWord) {
      return FilledButton.tonalIcon(
        onPressed: _loading ? null : () => unawaited(_openSheet()),
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.smart_toy),
        label: Text(S.dontKnowWord(lang)),
      );
    }
    return InkWell(
      onTap: _loading ? null : () => unawaited(_openSheet()),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.smart_toy,
                color: scheme.primary,
                size: widget.iconSize,
              ),
            const SizedBox(width: 6),
            Text(
              widget.word,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Содержимое листа перевода: слово, перевод, транскрипция, часть речи,
/// пример и кнопки add/remove (Phase 30c: общий для AiWordHelper и игр).
class _WordTranslationSheet extends StatelessWidget {
  const _WordTranslationSheet({
    required this.word,
    required this.translation,
    required this.lang,
    this.revealWord = true,
  });

  final String word;
  final WordTranslation translation;
  final AppLanguage lang;
  final bool revealWord;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    S.aiHelperTitle(lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (revealWord) ...[
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(translation.text, style: const TextStyle(fontSize: 20)),
              if (translation.transcription != null) ...[
                const SizedBox(height: 8),
                Text(
                  translation.transcription!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              if (translation.partOfSpeech != null) ...[
                const SizedBox(height: 8),
                Chip(label: Text(translation.partOfSpeech!)),
              ],
              if (translation.example != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '«${translation.example!}»',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  _AddRemoveWordButton(word: word, translation: translation),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(S.close(lang)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Запрашивает словарный перевод слова через прокси (Phase 30c).
///
/// При ошибке показывает SnackBar и возвращает null: игра не должна
/// ломаться из-за недоступности прокси (паттерн ADR-019).
Future<WordTranslation?> fetchWordTranslation(
  BuildContext context,
  WidgetRef ref,
  String word,
) async {
  final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
  try {
    return await ref.read(translationGeneratorProvider).translate(word);
  } on Object catch (error, stack) {
    ref.read(loggerProvider).warn('Word translation failed', error, stack);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.hintFailed(lang))));
    }
    return null;
  }
}

/// Открывает модалку перевода слова с add/remove (Phase 30c).
///
/// Общая точка входа для кнопок «Добавить в словарь» в играх: модалка
/// та же, что у AiWordHelper.
Future<void> showWordTranslationSheet(
  BuildContext context,
  WidgetRef ref,
  String word, {
  bool revealWord = true,
}) async {
  final translation = await fetchWordTranslation(context, ref, word);
  if (translation == null || !context.mounted) {
    return;
  }
  final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
  await _openTranslationModal(
    context,
    word,
    translation,
    lang,
    revealWord: revealWord,
  );
}

Future<void> _openTranslationModal(
  BuildContext context,
  String word,
  WordTranslation translation,
  AppLanguage lang, {
  bool revealWord = true,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => _WordTranslationSheet(
    word: word,
    translation: translation,
    lang: lang,
    revealWord: revealWord,
  ),
);

/// Кнопка «Добавить в словарь» для игр (Phase 30c).
///
/// Открывает модалку перевода одного слова с add/remove — унификация
/// с Cloze Test: одно слово, одна модалка, без дублирующих карточек.
class AddToDictionaryButton extends ConsumerStatefulWidget {
  /// Создаёт кнопку для слова [word].
  const AddToDictionaryButton({required this.word, super.key});

  /// Слово, которое можно добавить в словарь.
  final String word;

  @override
  ConsumerState<AddToDictionaryButton> createState() =>
      _AddToDictionaryButtonState();
}

class _AddToDictionaryButtonState extends ConsumerState<AddToDictionaryButton> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    final translation = await fetchWordTranslation(context, ref, widget.word);
    if (!mounted) {
      return;
    }
    // Спиннер снимается до открытия листа: иначе pumpAndSettle не завершится.
    setState(() => _loading = false);
    if (translation == null) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    await _openTranslationModal(context, widget.word, translation, lang);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return FilledButton.tonalIcon(
      onPressed: _loading ? null : () => unawaited(_open()),
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.menu_book),
      label: Text(S.addToDictionary(lang)),
    );
  }
}

/// Кнопка добавления/удаления слова внутри листа помощника (Phase 28b).
///
/// Состояние берётся из словаря (`findByTerm`), а не из факта запроса:
/// слово могло быть добавлено раньше или удалено в словаре.
class _AddRemoveWordButton extends ConsumerStatefulWidget {
  const _AddRemoveWordButton({required this.word, required this.translation});

  final String word;
  final WordTranslation translation;

  @override
  ConsumerState<_AddRemoveWordButton> createState() =>
      _AddRemoveWordButtonState();
}

class _AddRemoveWordButtonState extends ConsumerState<_AddRemoveWordButton> {
  Word? _existing;
  bool _checking = true;
  bool _checkFailed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    try {
      final found = await ref
          .read(wordRepositoryProvider)
          .findByTerm(widget.word);
      if (!mounted) {
        return;
      }
      setState(() {
        _existing = found;
        _checking = false;
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Word lookup failed', error, stack);
      if (mounted) {
        // Без знания о наличии слова кнопку не показываем: «добавить»
        // вслепую создало бы дубликат (ADR-024).
        setState(() {
          _checking = false;
          _checkFailed = true;
        });
      }
    }
  }

  Future<void> _add() async {
    if (_busy) {
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
        translation: widget.translation.text,
        transcription: widget.translation.transcription,
        partOfSpeech: widget.translation.partOfSpeech,
        exampleSentence: widget.translation.example,
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
      // Словарь на соседней вкладке не должен показывать устаревший список.
      ref.invalidate(dictionaryEntriesProvider);
      _showMessage(S.wordAdded(lang));
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Word add failed', error, stack);
      if (mounted) {
        setState(() => _busy = false);
        _showMessage(S.wordSaveFailed(lang));
      }
    }
  }

  Future<void> _remove() async {
    final existing = _existing;
    if (_busy || existing == null) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.removeConfirmTitle(lang)),
        content: Text(S.removeConfirmBody(existing.term, lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.cancel(lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.removeFromDictionary(lang)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
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
      _showMessage(S.wordRemoved(lang));
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Word remove failed', error, stack);
      if (mounted) {
        setState(() => _busy = false);
        _showMessage(S.wordSaveFailed(lang));
      }
    }
  }

  void _showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    if (_checking || _checkFailed) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final exists = _existing != null;
    return IconButton(
      tooltip: exists ? S.removeFromDictionary(lang) : S.addToDictionary(lang),
      color: exists ? scheme.error : scheme.primary,
      onPressed: _busy
          ? null
          : exists
          ? () => unawaited(_remove())
          : () => unawaited(_add()),
      icon: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(exists ? Icons.delete_outline : Icons.add_circle_outline),
    );
  }
}
