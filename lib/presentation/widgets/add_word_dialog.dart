import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
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

/// Диалог добавления слова в словарь.
///
/// Возвращает `true` через `Navigator.pop`, если слово сохранено.
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

  Future<bool> _confirmDuplicate(String term) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Слово уже есть'),
        content: Text('«$term» уже в словаре. Добавить всё равно?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    return answer ?? false;
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
      final found = await repo.search(term);
      final duplicate = found.any((word) => word.term.toLowerCase() == term);
      if (duplicate && !await _confirmDuplicate(term)) {
        return;
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
      Navigator.of(context).pop(true);
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Add word failed', error, stack);
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить слово');
      }
    }
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
          DropdownButtonFormField<String?>(
            initialValue: _category,
            // Пустое значение = «без категории»: показываем подпись, иначе
            // поле выглядит незаполненным.
            hint: const Text(noCategoryLabel),
            decoration: const InputDecoration(labelText: 'Категория'),
            items: [
              const DropdownMenuItem<String?>(child: Text(noCategoryLabel)),
              for (final option in wordCategories)
                DropdownMenuItem<String?>(value: option, child: Text(option)),
            ],
            onChanged: (value) => setState(() => _category = value),
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
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Отмена'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Добавить')),
    ],
  );
}
