import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/core/theme/app_colors.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/ai_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Префикс английского примера в данных (Phase 51) — на экране не нужен.
const _enPrefix = 'EN:';

/// Радиус аватара Маффина на кнопке перевода.
const _muffinRadius = 12.0;

/// Шторка примера слова (Phase 53b): английское предложение с подсветкой
/// слова, разделитель и русский перевод.
///
/// Перевода нет — кнопка «Перевести» с Маффином: запрос к прокси уходит
/// только по явному нажатию (ADR-019), результат кэшируется в памяти
/// (`sentenceTranslationProvider`). Ошибка не ломает шторку: перевод
/// можно запросить повторно.
class WordExampleSheet extends ConsumerStatefulWidget {
  /// Создаёт шторку для слова [word].
  const WordExampleSheet({
    required this.word,
    this.exampleRu,
    this.lang = AppLanguage.ru,
    super.key,
  });

  /// Слово, чей пример показываем.
  final Word word;

  /// Готовый русский перевод примера, если он есть.
  ///
  /// Seed хранит только EN (Phase 51); null — показываем кнопку перевода.
  final String? exampleRu;

  /// Язык интерфейса.
  final AppLanguage lang;

  @override
  ConsumerState<WordExampleSheet> createState() => _WordExampleSheetState();
}

class _WordExampleSheetState extends ConsumerState<WordExampleSheet> {
  bool _translating = false;
  WordStatus? _status;
  bool _statusLoading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final example = _example;
    if (example != null && widget.exampleRu == null) {
      // Кэш сессии: повторное открытие показывает перевод без запроса.
      // exists не инициализирует провайдер — сеть только по нажатию.
      final provider = sentenceTranslationProvider(example);
      if (ref.exists(provider) && ref.read(provider) is AsyncData<String>) {
        _translating = true;
      }
    }
    unawaited(_loadStatus());
  }

  /// Статус изучения слова — для кнопки «Добавить/Убрать» (Phase 55b).
  Future<void> _loadStatus() async {
    final progress = await ref
        .read(progressRepositoryProvider)
        .getByWordId(widget.word.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _status = progress?.status;
      _statusLoading = false;
    });
  }

  bool get _isLearning => _status == WordStatus.learning;

  /// Переключает статус изучения (UpdateWordStatus, ADR-004).
  Future<void> _toggleStatus() async {
    if (_busy) {
      return;
    }
    final lang = widget.lang;
    setState(() => _busy = true);
    try {
      if (_isLearning) {
        await ref
            .read(progressRepositoryProvider)
            .deleteByWordId(widget.word.id);
        if (!mounted) {
          return;
        }
        setState(() {
          _status = null;
          _busy = false;
        });
        ref.invalidate(dictionaryEntriesProvider);
        _showMessage(S.wordRemovedFromLearning(lang));
      } else {
        await ref.read(updateWordStatusProvider)(
          widget.word.id,
          WordStatus.learning,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _status = WordStatus.learning;
          _busy = false;
        });
        ref.invalidate(dictionaryEntriesProvider);
        _showMessage(S.wordAddedToLearning(lang));
      }
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        _showMessage(S.wordSaveFailed(lang));
      }
    }
  }

  void _showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Пример без префикса «EN:»; null — примера нет.
  String? get _example {
    final raw = widget.word.exampleSentence?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final stripped = raw.startsWith(_enPrefix)
        ? raw.substring(_enPrefix.length).trim()
        : raw;
    return stripped.isEmpty ? null : stripped;
  }

  void _translate() {
    final example = _example;
    if (example == null) {
      return;
    }
    // Повтор после ошибки сбрасывает кэш ошибки: запрос уходит заново.
    ref.invalidate(sentenceTranslationProvider(example));
    setState(() => _translating = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final example = _example;
    final base = theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface);
    final highlight = AppColors.accentPurple(context);
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (example == null)
            Text(S.noExample(widget.lang), style: theme.textTheme.bodyLarge)
          else ...[
            RichText(
              key: const Key('example-sentence'),
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                children: _highlightedSpans(
                  example,
                  widget.word.term,
                  base,
                  highlight,
                ),
              ),
            ),
            Divider(thickness: 1, color: scheme.outlineVariant, height: 24),
            _translationSection(example, theme),
          ],
          const SizedBox(height: 16),
          _statusButton(theme),
        ],
      ),
    );
  }

  /// Кнопка статуса: «+» добавить в изучение / корзина убрать (Phase 55b).
  Widget _statusButton(ThemeData theme) {
    if (_statusLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final learning = _isLearning;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('example-status-button'),
        onPressed: _busy ? null : _toggleStatus,
        style: learning
            ? FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              )
            : null,
        icon: Icon(learning ? Icons.delete_outline : Icons.add),
        label: Text(
          learning
              ? S.removeFromLearning(widget.lang)
              : S.addToLearning(widget.lang),
        ),
      ),
    );
  }

  /// Спаны предложения: искомое слово подсвечено, остальное — onSurface.
  ///
  /// Границы слова (`\b`) и регистронезависимость: «a» не подсвечивается
  /// внутри «apple».
  List<TextSpan> _highlightedSpans(
    String sentence,
    String term,
    TextStyle? base,
    Color highlight,
  ) {
    final pattern = RegExp(
      '\\b${RegExp.escape(term)}\\b',
      caseSensitive: false,
    );
    final spans = <TextSpan>[];
    var start = 0;
    for (final match in pattern.allMatches(sentence)) {
      if (match.start > start) {
        spans.add(
          TextSpan(text: sentence.substring(start, match.start), style: base),
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
    if (start < sentence.length) {
      spans.add(TextSpan(text: sentence.substring(start), style: base));
    }
    return spans;
  }

  Widget _translationSection(String example, ThemeData theme) {
    final ru = widget.exampleRu;
    if (ru != null) {
      return Text(ru, style: theme.textTheme.bodyLarge);
    }
    final provider = sentenceTranslationProvider(example);
    final cached = ref.exists(provider) ? ref.read(provider) : null;
    if (!_translating && cached is! AsyncData<String>) {
      return _translateButton();
    }
    return ref
        .watch(provider)
        .when(
          data: (text) => Text(text, style: theme.textTheme.bodyLarge),
          loading: () => Center(
            child: Semantics(
              label: S.loading(widget.lang),
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.translateError(widget.lang),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              _translateButton(),
            ],
          ),
        );
  }

  Widget _translateButton() => FilledButton.tonalIcon(
    key: const Key('translate-example-button'),
    onPressed: _translate,
    icon: const CircleAvatar(
      radius: _muffinRadius,
      backgroundImage: AssetImage(aiAvatarAsset),
    ),
    label: Text(S.translateButton(widget.lang)),
  );
}
