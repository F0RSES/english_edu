import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:flutter/material.dart';

/// Строка словаря: слово, перевод, чип статуса.
class WordListItem extends StatelessWidget {
  /// Создаёт строку.
  const WordListItem({required this.entry, super.key});

  /// Запись словаря.
  final DictionaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = entry.word;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          word.term,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word.translation),
            if (word.transcription != null)
              Text(
                word.transcription!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(_statusLabel(entry.status)),
          visualDensity: VisualDensity.compact,
        ),
        onTap: () {
          final example = word.exampleSentence;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(example ?? 'Пример отсутствует'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(WordStatus? status) => switch (status) {
    null || WordStatus.newWord => 'новое',
    WordStatus.learning => 'изучаю',
    WordStatus.mastered => 'выучено',
  };
}
