import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';
import 'package:english_edu/presentation/widgets/create_category_dialog.dart';
import 'package:english_edu/presentation/widgets/word_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Части речи, которые можно выбрать вручную.
const _partOfSpeechOptions = <String>[
  'article',
  'verb',
  'preposition',
  'conjunction',
  'pronoun',
  'adverb',
  'adjective',
  'noun',
  'interjection',
  'numeral',
];

/// Сентинел пункта «создать категорию» в выпадающем списке.
///
/// Отдельное значение, а не null: null означает «без категории», и путать эти
/// два случая нельзя.
const _createCategoryValue = '__create__';

/// Чем закончилось добавление слова.
///
/// Отдельный тип вместо `bool`: `null` означает «пользователь отменил», и это
/// надо отличать от сохранения. Значение одно, потому что с ADR-031 гомонимы
/// разрешены: отказ от добавления теперь выражается отменой диалога, а не
/// отдельным исходом «такое уже есть».
enum AddWordOutcome {
  /// Слово сохранено, в том числе как ещё одно значение гомонима.
  added,
}

/// Диалог добавления слова в словарь.
///
/// Возвращает [AddWordOutcome] через `Navigator.pop`: `added` — слово
/// сохранено, `null` — пользователь отменил. Если слово с таким `term` уже
/// есть, диалог предлагает добавить ещё одно значение (ADR-031).
class AddWordDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог.
  const AddWordDialog({super.key});

  @override
  ConsumerState<AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends ConsumerState<AddWordDialog> {
  final _term = TextEditingController();
  final _translation = TextEditingController();
  final _transcription = TextEditingController();
  final _example = TextEditingController();
  String? _partOfSpeech;
  String? _category;
  // Уровень нужен очереди дня: слово выше preferredLevel в урок не попадёт
  // (ADR-023).
  CefrLevel _level = CefrLevel.a1;
  String? _error;

  @override
  void dispose() {
    _term.dispose();
    _translation.dispose();
    _transcription.dispose();
    _example.dispose();
    super.dispose();
  }

  /// Спрашивает, добавить ли ещё одно значение для того же [term] (ADR-031).
  ///
  /// `true` — пользователь хочет отдельную карточку-гомоним, `false` — отмена
  /// (форма остаётся открытой, слово не сохраняется).
  Future<bool> _confirmHomonym(String term, List<Word> existing) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('«$term» уже есть в словаре'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Существующие значения:'),
            const SizedBox(height: 8),
            for (final word in existing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_senseLabel(word)),
              ),
            const SizedBox(height: 12),
            const Text('Добавить ещё одно значение?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Добавить как новое'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  /// Подпись значения для списка существующих senses.
  ///
  /// Часть речи — единственное, что отличает гомонимы друг от друга на глаз
  /// («яблоко (noun)» против «компания (proper noun)»).
  static String _senseLabel(Word word) {
    final partOfSpeech = word.partOfSpeech;
    return partOfSpeech == null
        ? '• ${word.translation}'
        : '• ${word.translation} ($partOfSpeech)';
  }

  Future<void> _submit() async {
    final term = _term.text.trim().toLowerCase();
    final translation = _translation.text.trim();
    if (term.isEmpty) {
      setState(() => _error = 'Введите слово');
      return;
    }
    if (translation.isEmpty) {
      setState(() => _error = 'Введите перевод');
      return;
    }

    final repo = ref.read(wordRepositoryProvider);
    try {
      // Все senses, а не один: гомонимы — это разные карточки с одним term
      // (ADR-031), и пользователю нужно увидеть, с чем он столкнулся.
      final existing = await repo.findAllByTerm(term);
      if (existing.isNotEmpty) {
        final addAsNew = await _confirmHomonym(term, existing);
        if (!mounted) {
          return;
        }
        // «Отмена» оставляет форму открытой — пользователь поправит слово.
        if (!addAsNew) {
          return;
        }
      }

      final id = await repo.nextId();
      await repo.upsert(
        Word(
          id: id,
          term: term,
          translation: translation,
          transcription: _optional(_transcription.text),
          partOfSpeech: _partOfSpeech,
          exampleSentence: _optional(_example.text),
          category: _category,
          level: _level,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(AddWordOutcome.added);
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Add word failed', error, stack);
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить слово');
      }
    }
  }

  /// Реакция на выбор категории: обычная — просто сохранить, «создать» —
  /// открыть диалог и выбрать только что созданную (ADR-034).
  Future<void> _onCategoryChanged(String? value) async {
    if (value != _createCategoryValue) {
      setState(() => _category = value);
      return;
    }

    final created = await showDialog<UserCategory>(
      context: context,
      builder: (context) => const CreateCategoryDialog(),
    );
    if (!mounted || created == null) {
      return;
    }
    ref.invalidate(userCategoriesProvider);
    setState(() => _category = created.name);
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Новое слово'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _term,
            decoration: const InputDecoration(labelText: 'Слово'),
          ),
          TextField(
            controller: _translation,
            decoration: const InputDecoration(labelText: 'Перевод'),
          ),
          TextField(
            controller: _transcription,
            decoration: const InputDecoration(labelText: 'Транскрипция'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _partOfSpeech,
            decoration: const InputDecoration(labelText: 'Часть речи'),
            items: [
              for (final option in _partOfSpeechOptions)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (value) => setState(() => _partOfSpeech = value),
          ),
          ref
              .watch(userCategoriesProvider)
              .when(
                data: (categories) => DropdownButtonFormField<String?>(
                  initialValue: _category,
                  // Пустое значение = «без категории»: показываем подпись,
                  // иначе поле выглядит незаполненным.
                  hint: const Text(noCategoryLabel),
                  decoration: const InputDecoration(labelText: 'Категория'),
                  items: [
                    const DropdownMenuItem<String?>(
                      child: Text(noCategoryLabel),
                    ),
                    for (final category in categories)
                      DropdownMenuItem<String?>(
                        value: category.name,
                        child: Text(category.name),
                      ),
                    const DropdownMenuItem<String?>(
                      value: _createCategoryValue,
                      child: Text('+ Создать категорию…'),
                    ),
                  ],
                  onChanged: _onCategoryChanged,
                ),
                // Категории нужны только для выбора: без них форма остаётся
                // рабочей, слово сохранится «без категории».
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
          DropdownButtonFormField<CefrLevel>(
            initialValue: _level,
            decoration: const InputDecoration(labelText: 'Уровень'),
            items: [
              for (final level in CefrLevel.values)
                DropdownMenuItem(
                  value: level,
                  child: Text('${level.label} — ${level.description}'),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _level = value);
              }
            },
          ),
          TextField(
            controller: _example,
            decoration: const InputDecoration(labelText: 'Пример'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Добавить')),
    ],
  );
}
