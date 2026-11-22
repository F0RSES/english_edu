import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/core/theme/app_colors.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:english_edu/domain/value_objects/typing_result.dart';
import 'package:english_edu/presentation/widgets/app_bottom_sheet.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:english_edu/presentation/widgets/word_example_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Фильтр порядка строк результатов (Phase 55b).
enum _ResultFilter { order, correctFirst, wrongFirst }

/// Экран результатов заезда «Typing Speed» (Phase 55b).
///
/// Заменяет финальный AlertDialog: сводка (точность/WPM/время), фильтр
/// порядка и прокручиваемый список ответов. У каждой строки — Маффин
/// (объяснение ошибки) и словарь (пример + добавление в «Изучаю»).
/// «Ещё раз» возвращает true, «Закрыть» — false.
class TypingResultsSheet extends ConsumerStatefulWidget {
  /// Создаёт экран результатов для [results] со сводкой [record].
  const TypingResultsSheet({
    required this.results,
    required this.record,
    this.lang = AppLanguage.ru,
    super.key,
  });

  /// Ответы заезда в порядке ввода.
  final List<TypingResult> results;

  /// Сводка заезда (точность, WPM, длительность).
  final TypingRecord record;

  /// Язык интерфейса.
  final AppLanguage lang;

  /// Открывает шторку результатов; возвращает true для «Ещё раз».
  static Future<bool?> show(
    BuildContext context, {
    required List<TypingResult> results,
    required TypingRecord record,
    AppLanguage lang = AppLanguage.ru,
  }) => AppBottomSheet.show<bool>(
    context,
    TypingResultsSheet(results: results, record: record, lang: lang),
  );

  @override
  ConsumerState<TypingResultsSheet> createState() => _TypingResultsSheetState();
}

class _TypingResultsSheetState extends ConsumerState<TypingResultsSheet> {
  _ResultFilter _filter = _ResultFilter.order;

  /// Копия списка, отсортированная по выбранному фильтру.
  List<TypingResult> get _sorted {
    final list = [...widget.results];
    int byTime(TypingResult a, TypingResult b) =>
        a.timestamp.compareTo(b.timestamp);
    list.sort((a, b) {
      switch (_filter) {
        case _ResultFilter.order:
          return byTime(a, b);
        case _ResultFilter.correctFirst:
          final c = (b.isCorrect ? 1 : 0) - (a.isCorrect ? 1 : 0);
          return c != 0 ? c : byTime(a, b);
        case _ResultFilter.wrongFirst:
          final c = (a.isCorrect ? 1 : 0) - (b.isCorrect ? 1 : 0);
          return c != 0 ? c : byTime(a, b);
      }
    });
    return list;
  }

  /// Длительность в формате M:SS.
  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final record = widget.record;
    final sorted = _sorted;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.typingResults(widget.lang),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${record.accuracyPercent}% · ${record.wpm} WPM '
            '· ${_formatTime(record.durationSeconds)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButton<_ResultFilter>(
            key: const Key('results-filter'),
            value: _filter,
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: _ResultFilter.order,
                child: Text(S.typingFilterOrder(widget.lang)),
              ),
              DropdownMenuItem(
                value: _ResultFilter.correctFirst,
                child: Text(S.typingFilterCorrect(widget.lang)),
              ),
              DropdownMenuItem(
                value: _ResultFilter.wrongFirst,
                child: Text(S.typingFilterWrong(widget.lang)),
              ),
            ],
            onChanged: (value) =>
                setState(() => _filter = value ?? _ResultFilter.order),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('results-again'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(S.commonAgain(widget.lang)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: const Key('results-close'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(S.close(widget.lang)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              key: const Key('results-list'),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _ResultRow(result: sorted[index], lang: widget.lang),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка результата: ввод • точка • правильное слово + действия.
class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.lang});

  final TypingResult result;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result.userInput.isEmpty ? '—' : result.userInput,
              key: Key('result-input-${result.correctWord}'),
              style: TextStyle(
                color: result.isCorrect ? scheme.onSurface : scheme.error,
              ),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: result.isCorrect ? Colors.green : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.correctWord,
              style: TextStyle(
                color: AppColors.accentPurple(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ErrorHelperButton(
            gameType: 'typing',
            compact: true,
            context:
                'Слово: "${result.correctWord}". '
                'Перевод: "${result.translation}". '
                'Пользователь ввёл: "${result.userInput}".',
          ),
          IconButton(
            key: Key('result-dictionary-${result.correctWord}'),
            tooltip: result.correctWord,
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => AppBottomSheet.show<void>(
              context,
              WordExampleSheet(word: result.word, lang: lang),
            ),
          ),
        ],
      ),
    );
  }
}
