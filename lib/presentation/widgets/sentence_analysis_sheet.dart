import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/core/theme/app_colors.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/presentation/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Маркер пропуска в предложении Cloze (как `___` в ClozeTask).
const _blank = '___';

/// Шторка разбора предложения (Phase 54c): перевод + грамматическое время.
///
/// Единый стиль `AppBottomSheet`. Запрос к прокси уходит при открытии
/// (явное действие пользователя), результат кэшируется в памяти
/// (`sentenceAnalysisProvider`). Ключевое слово подсвечено фиолетовым
/// (`AppColors.accentPurple`). Ошибка — текст и кнопка «Повторить».
class SentenceAnalysisSheet extends ConsumerWidget {
  /// Создаёт шторку для [sentence] с ключевым словом [correctWord].
  const SentenceAnalysisSheet({
    required this.sentence,
    required this.correctWord,
    this.lang = AppLanguage.ru,
    super.key,
  });

  /// Предложение с пропуском `___`; пропуск заменяется на [correctWord].
  final String sentence;

  /// Ключевое слово — подсвечивается в восстановленном предложении.
  final String correctWord;

  /// Язык интерфейса.
  final AppLanguage lang;

  /// Открывает шторку разбора в едином стиле `AppBottomSheet`.
  static Future<void> show(
    BuildContext context, {
    required String sentence,
    required String correctWord,
    AppLanguage lang = AppLanguage.ru,
  }) => AppBottomSheet.show<void>(
    context,
    SentenceAnalysisSheet(
      sentence: sentence,
      correctWord: correctWord,
      lang: lang,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final analysis = ref.watch(sentenceAnalysisProvider(sentence));
    final restored = sentence.replaceAll(_blank, correctWord);
    final base = theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface);
    final highlight = AppColors.accentPurple(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.sentenceAnalysisTitle(lang),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          key: const Key('analysis-sentence'),
          textScaler: MediaQuery.textScalerOf(context),
          text: TextSpan(
            children: _spans(restored, correctWord, base, highlight),
          ),
        ),
        Divider(thickness: 1, color: scheme.outlineVariant, height: 24),
        analysis.when(
          data: (data) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.translation, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Chip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(data.tense),
              ),
            ],
          ),
          loading: () => const SizedBox(
            width: double.infinity,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.translateError(lang),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                key: const Key('analysis-retry'),
                onPressed: () =>
                    ref.invalidate(sentenceAnalysisProvider(sentence)),
                child: Text(S.retry(lang)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Спаны предложения: ключевое слово подсвечено, остальное — onSurface.
  ///
  /// Границы слова (`\b`) и регистронезависимость: «a» не подсвечивается
  /// внутри «apple» (как в WordExampleSheet).
  List<TextSpan> _spans(
    String text,
    String word,
    TextStyle? base,
    Color highlight,
  ) {
    final pattern = RegExp(
      '\\b${RegExp.escape(word)}\\b',
      caseSensitive: false,
    );
    final spans = <TextSpan>[];
    var start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(text: text.substring(start, match.start), style: base),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: base?.copyWith(color: highlight),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: base));
    }
    return spans;
  }
}
