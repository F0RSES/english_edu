import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/cefr_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Размер точки индикатора прогресса (Phase 39d).
const _statusDotSize = 8.0;

/// Размер термина в строке словаря.
const _termFontSize = 18.0;

/// Строка словаря: слово, уровень, индикатор прогресса, «IPA • часть речи»,
/// перевод и быстрый доступ к ИИ-помощнику (Phase 39d).
///
/// Текстовых бейджей статуса нет: learning — янтарная точка, mastered —
/// зелёная, новое слово — без точки. Часть речи в среднем ряду отличает
/// гомонимы (ADR-031).
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
    final meta = _metaLine(word.transcription, word.partOfSpeech);
    final statusColor = _statusColor(entry.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          final example = word.exampleSentence;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(example ?? S.noExample(lang)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      word.term,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: _termFontSize,
                      ),
                    ),
                  ),
                  if (statusColor != null) ...[
                    Container(
                      key: const Key('word-status-dot'),
                      width: _statusDotSize,
                      height: _statusDotSize,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  CefrBadge(level: word.level),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: S.askAi(lang),
                    onPressed: () => context.push(
                      '/chat',
                      extra: S.aiWordPrompt(
                        word.term,
                        word.translation,
                        word.partOfSpeech,
                        lang,
                      ),
                    ),
                  ),
                ],
              ),
              if (meta != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(word.translation, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  /// Цвет индикатора прогресса; новое слово — без точки (Phase 39d).
  Color? _statusColor(WordStatus? status) => switch (status) {
    WordStatus.learning => Colors.amber,
    WordStatus.mastered => Colors.green,
    _ => null,
  };

  /// Средний ряд: «/IPA/ • partOfSpeech»; отсутствующее поле опускается.
  String? _metaLine(String? transcription, String? partOfSpeech) {
    final ipa = (transcription ?? '').trim();
    final pos = (partOfSpeech ?? '').trim();
    if (ipa.isEmpty && pos.isEmpty) {
      return null;
    }
    if (ipa.isEmpty) {
      return pos;
    }
    if (pos.isEmpty) {
      return ipa;
    }
    return '$ipa • $pos';
  }
}
