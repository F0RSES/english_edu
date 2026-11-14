import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/cefr_badge.dart';
import 'package:flutter/material.dart';

/// Строка словаря: слово, перевод, бейдж уровня и чип статуса.
class WordListItem extends StatelessWidget {
  /// Создаёт строку.
  const WordListItem({
    required this.entry,
    this.lang = AppLanguage.ru,
    super.key,
  });

  /// Запись словаря.
  final DictionaryEntry entry;

  /// Язык интерфейса; ru по умолчанию (Phase 27b).
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = entry.word;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          word.term,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Часть речи рядом с переводом: так гомонимы («яблоко (noun)» и
              // «компания (proper noun)») различимы в списке (ADR-031).
              word.partOfSpeech == null
                  ? word.translation
                  : '${word.translation} (${word.partOfSpeech})',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
            ),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CefrBadge(level: word.level),
            const SizedBox(width: 6),
            Chip(
              label: Text(_statusLabel(entry.status)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        onTap: () {
          final example = word.exampleSentence;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(example ?? S.noExample(lang)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(WordStatus? status) => switch (status) {
    null || WordStatus.newWord => S.statusNew(lang),
    WordStatus.learning => S.statusLearning(lang),
    WordStatus.mastered => S.statusMastered(lang),
  };
}
