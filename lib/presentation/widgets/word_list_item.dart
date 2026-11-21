import 'dart:async';

import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/ai_avatar.dart';
import 'package:english_edu/presentation/widgets/app_bottom_sheet.dart';
import 'package:english_edu/presentation/widgets/cefr_badge.dart';
import 'package:english_edu/presentation/widgets/ipa_text.dart';
import 'package:english_edu/presentation/widgets/part_of_speech_chip.dart';
import 'package:english_edu/presentation/widgets/word_example_sheet.dart';
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
    this.onStatusChanged,
    super.key,
  });

  /// Запись словаря.
  final DictionaryEntry entry;

  /// Язык интерфейса; ru по умолчанию (Phase 27b).
  final AppLanguage lang;

  /// Коллбэк ручного действия со статусом (Phase 39e): new → learning,
  /// learning → mastered, mastered → newWord (сброс/удаление).
  ///
  /// null — кнопка действия не рендерится.
  final void Function(WordStatus target)? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = entry.word;
    final ipa = IpaText.stripSlashes(word.transcription ?? '');
    final pos = (word.partOfSpeech ?? '').trim();
    final hasMeta = ipa.isNotEmpty || pos.isNotEmpty;
    final statusColor = _statusColor(entry.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          // Phase 53b: пример — в шторке AppBottomSheet, не в SnackBar.
          unawaited(
            AppBottomSheet.show<void>(
              context,
              WordExampleSheet(word: word, lang: lang),
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
                  if (onStatusChanged != null)
                    IconButton(
                      icon: Icon(
                        _statusIcon(entry.status),
                        color: _statusIconColor(entry.status),
                      ),
                      tooltip: _statusTooltip(entry.status, lang),
                      onPressed: () =>
                          onStatusChanged!(_statusTarget(entry.status)),
                    ),
                  IconButton(
                    icon: const CircleAvatar(
                      key: Key('word-ai-avatar'),
                      radius: 14,
                      backgroundImage: AssetImage(aiAvatarAsset),
                    ),
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
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasMeta)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            if (ipa.isNotEmpty)
                              IpaText(
                                ipa,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            if (ipa.isNotEmpty && pos.isNotEmpty)
                              const SizedBox(width: 8),
                            if (pos.isNotEmpty)
                              PartOfSpeechChip(partOfSpeech: pos),
                          ],
                        ),
                      ),
                    Text(word.translation, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
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

  /// Иконка действия со статусом (Phase 39e).
  IconData _statusIcon(WordStatus? status) => switch (status) {
    WordStatus.learning => Icons.check_circle_outline,
    WordStatus.mastered => Icons.delete_outline,
    _ => Icons.bookmark_add_outlined,
  };

  /// Цвет иконки действия: green — выучить, redAccent — сбросить.
  Color? _statusIconColor(WordStatus? status) => switch (status) {
    WordStatus.learning => Colors.green,
    WordStatus.mastered => Colors.redAccent,
    _ => null,
  };

  /// Тултип кнопки действия со статусом (Phase 39e).
  String _statusTooltip(WordStatus? status, AppLanguage lang) =>
      switch (status) {
        WordStatus.learning => S.markMastered(lang),
        WordStatus.mastered => S.resetWord(lang),
        _ => S.addToLearning(lang),
      };

  /// Целевой статус действия: new → learning → mastered → сброс.
  WordStatus _statusTarget(WordStatus? status) => switch (status) {
    WordStatus.learning => WordStatus.mastered,
    WordStatus.mastered => WordStatus.newWord,
    _ => WordStatus.learning,
  };
}
