import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/grammar/part_of_speech_glossary.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Чип части речи с пояснением по тапу (Phase 51, ADR-049).
///
/// Тексты пояснений — из глоссария (core/grammar), не хардкодятся в
/// виджете. Неизвестная часть речи — обычный Chip без тапа. Отступы
/// заданы, чтобы чип не слипался с соседним текстом.
class PartOfSpeechChip extends ConsumerWidget {
  /// Создаёт чип для [partOfSpeech] ('noun', 'verb', ...).
  const PartOfSpeechChip({required this.partOfSpeech, super.key});

  /// Часть речи, как её вернул прокси или seed.
  final String partOfSpeech;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final label = partOfSpeech.trim();
    final entry = PartOfSpeechGlossary.lookup(label);
    if (entry == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Chip(label: Text(label)),
      );
    }
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: InkWell(
        key: Key('pos-chip-${entry.key}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => unawaited(_openExplanation(context, entry, lang)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }

  Future<void> _openExplanation(
    BuildContext context,
    PartOfSpeechEntry entry,
    AppLanguage lang,
  ) {
    final isRu = lang == AppLanguage.ru;
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key} / ${isRu ? entry.ruName : entry.enName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isRu ? entry.ruDefinition : entry.enDefinition,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                '${S.posExample(lang)} ${entry.example}',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(S.gotIt(lang)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
