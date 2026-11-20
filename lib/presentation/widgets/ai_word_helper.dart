import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/word_category.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:english_edu/presentation/widgets/ai_avatar.dart';
import 'package:english_edu/presentation/widgets/part_of_speech_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Префиксы строк примера (Phase 51): маркеры языка, не локализуются.
const _exampleEnPrefix = 'EN: ';
const _exampleRuPrefix = 'RU: ';

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
            : const CircleAvatar(
                key: Key('ai-word-button-avatar'),
                radius: 12,
                backgroundImage: AssetImage(aiAvatarAsset),
              ),
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
              CircleAvatar(
                key: const Key('ai-word-avatar'),
                radius: widget.iconSize / 2,
                backgroundImage: const AssetImage(aiAvatarAsset),
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

/// Единая шторка разбора слова (Phase 51, ADR-049).
///
/// Вся информация в одном окне: слово крупно, транскрипция, часть речи
/// (чип с пояснением), перевод отдельным блоком, пример EN/RU. Внизу —
/// ровно одна кнопка действия по статусу прогресса; второй шторки нет.
class _WordTranslationSheet extends StatelessWidget {
  const _WordTranslationSheet({
    required this.word,
    required this.translation,
    this.revealWord = true,
  });

  final String word;
  final WordTranslation translation;
  final bool revealWord;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final example = translation.example;
    final exampleRu = translation.exampleRu;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (revealWord) ...[
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (translation.transcription != null)
                Text(
                  translation.transcription!,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (translation.partOfSpeech != null) ...[
                const SizedBox(height: 8),
                PartOfSpeechChip(partOfSpeech: translation.partOfSpeech!),
              ],
              const SizedBox(height: 16),
              // Перевод — отдельный блок, не сливается с фоном шторки.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  translation.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (example != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_exampleEnPrefix$example',
                        style: textTheme.bodyMedium,
                      ),
                      if (exampleRu != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$_exampleRuPrefix$exampleRu',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _WordActionButton(word: word, translation: translation),
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
/// Общая точка входа для кнопок «Разобрать слово» в играх: модалка
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
  await _openTranslationModal(
    context,
    word,
    translation,
    revealWord: revealWord,
  );
}

Future<void> _openTranslationModal(
  BuildContext context,
  String word,
  WordTranslation translation, {
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
    revealWord: revealWord,
  ),
);

/// Кнопка «Разобрать слово» для игр (Phase 30c, Phase 49).
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
    await _openTranslationModal(context, widget.word, translation);
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

/// Единственная кнопка действия в шторке разбора (Phase 51, ADR-049).
///
/// Состояние — по статусу прогресса (ADR-004): learning → корзина
/// («Удалить из изучения», сброс прогресса), иначе «+» («Добавить
/// в изучение»). Двух кнопок одновременно не бывает; второй шторки нет.
class _WordActionButton extends ConsumerStatefulWidget {
  const _WordActionButton({required this.word, required this.translation});

  final String word;
  final WordTranslation translation;

  @override
  ConsumerState<_WordActionButton> createState() => _WordActionButtonState();
}

class _WordActionButtonState extends ConsumerState<_WordActionButton> {
  Word? _word;
  WordStatus? _status;
  bool _checking = true;
  bool _checkFailed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  /// Состояние берётся из словаря и прогресса, а не из факта запроса:
  /// слово могло быть добавлено раньше или изменено в словаре.
  Future<void> _check() async {
    try {
      final found = await ref
          .read(wordRepositoryProvider)
          .findByTerm(widget.word);
      final status = found == null
          ? null
          : (await ref.read(progressRepositoryProvider).getByWordId(found.id))
                ?.status;
      if (!mounted) {
        return;
      }
      setState(() {
        _word = found;
        _status = status;
        _checking = false;
        _busy = false;
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

  bool get _isLearning => _status == WordStatus.learning;

  Future<void> _addToLearning() async {
    if (_busy) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _busy = true);
    try {
      final words = ref.read(wordRepositoryProvider);
      var word = _word;
      if (word == null) {
        final settings = await ref.read(settingsRepositoryProvider).get();
        final id = await words.nextId();
        word = Word(
          id: id,
          term: widget.word.trim().toLowerCase(),
          translation: widget.translation.text,
          transcription: widget.translation.transcription,
          partOfSpeech: widget.translation.partOfSpeech,
          exampleSentence: widget.translation.example,
          level: settings.preferredLevel,
        );
        await words.upsert(word);
      }
      // Сразу «Изучаю»: добавленное из игр/ИИ слово не лежит в «Новом».
      await ref.read(updateWordStatusProvider)(word.id, WordStatus.learning);
      if (!mounted) {
        return;
      }
      // Сброс фильтров словаря: слово должно быть видно в «Изучаю»
      // при любом прошлом поиске/уровне/категории (Phase 50).
      ref.read(dictionarySearchQueryProvider.notifier).update('');
      ref.read(dictionaryLevelFilterProvider.notifier).update(null);
      ref
          .read(dictionaryCategoryFilterProvider.notifier)
          .update(WordCategory.all);
      ref.invalidate(dictionaryEntriesProvider);
      _showMessage(S.wordAddedToLearning(lang));
      await _check();
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Word add failed', error, stack);
      if (mounted) {
        setState(() => _busy = false);
        _showMessage(S.wordSaveFailed(lang));
      }
    }
  }

  Future<void> _removeFromLearning() async {
    final word = _word;
    if (_busy || word == null) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _busy = true);
    try {
      // Убираем из изучения: прогресс удаляется, слово остаётся в словаре
      // как «Новое» (Phase 51); кастомные слова не удаляются.
      await ref.read(progressRepositoryProvider).deleteByWordId(word.id);
      if (!mounted) {
        return;
      }
      ref.invalidate(dictionaryEntriesProvider);
      _showMessage(S.wordRemovedFromLearning(lang));
      await _check();
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Word status reset failed', error, stack);
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
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    if (_busy) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FloatingActionButton.extended(
        key: const Key('word-action-button'),
        onPressed: () =>
            unawaited(_isLearning ? _removeFromLearning() : _addToLearning()),
        icon: Icon(_isLearning ? Icons.delete_outline : Icons.add),
        label: Text(
          _isLearning ? S.removeFromLearning(lang) : S.addToLearning(lang),
        ),
      ),
    );
  }
}
