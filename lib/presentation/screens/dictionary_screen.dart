import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_category.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/add_word_dialog.dart';
import 'package:english_edu/presentation/widgets/word_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Вкладка слова��я.
enum DictionaryTab {
  /// Все слова, включая те, у которых ещё нет прогресса.
  all,

  /// Слова в статусе `learning`.
  learning,

  /// Слова в статусе `mastered`.
  mastered,
}

/// Словарь: список, поиск, двойной фильтр (CEFR + категория), добавление слова.
///
/// Уровень и категория фильтруются в `dictionaryEntriesProvider` (Phase 39a)
/// и складываются по AND; вкладка статуса применяется локально. Категория
/// выбирается в bottom sheet (Phase 39c), а не рядом чипов.
/// «Все» — все слова. «Изучаю» — `status.learning`. «Выучено» —
/// `status.mastered`. Слова без прогресса (`status == null`) видны только во
/// вкладке «Все» и помечены как новые.
class DictionaryScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _search = TextEditingController();
  DictionaryTab _tab = DictionaryTab.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DictionaryEntry> _applyTab(List<DictionaryEntry> entries) =>
      switch (_tab) {
        DictionaryTab.all => entries,
        DictionaryTab.learning => [
          for (final entry in entries)
            if (entry.status == WordStatus.learning) entry,
        ],
        DictionaryTab.mastered => [
          for (final entry in entries)
            if (entry.status == WordStatus.mastered) entry,
        ],
      };

  void _reload() => ref.invalidate(dictionaryEntriesProvider);

  /// Открывает диалог добавления и сообщает итог (ADR-031).
  ///
  /// Гомоним сохраняется как отдельная карточка, поэтому успешный исход один:
  /// список перечитывается и показывается «Добавлено». `null` — пользователь
  /// отменил, реакции нет.
  Future<void> _addWord() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    final outcome = await showDialog<AddWordOutcome>(
      context: context,
      builder: (context) => const AddWordDialog(),
    );
    if (!mounted || outcome == null) {
      return;
    }
    ref.invalidate(dictionaryEntriesProvider);
    _showMessage(S.wordAdded(lang));
  }

  void _showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final selectedLevel = ref.watch(dictionaryLevelFilterProvider);
    final selectedCategory = ref.watch(dictionaryCategoryFilterProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.dictionary(lang)),
        // Словарь открывается вкладкой через go: pop не сработает, возврат
        // на главную — как в Profile.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: S.back(lang),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: S.addWordTooltip(lang),
            onPressed: _addWord,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: S.searchHint(lang),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => ref
                  .read(dictionarySearchQueryProvider.notifier)
                  .update(value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final level in <CefrLevel?>[null, ...CefrLevel.values])
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(level?.label ?? S.allLevels(lang)),
                      selected: selectedLevel == level,
                      onSelected: (_) => ref
                          .read(dictionaryLevelFilterProvider.notifier)
                          .update(level),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openCategorySheet(lang),
                icon: const Icon(Icons.tune, size: 18),
                label: Text(
                  '${S.filterCategories(lang)}: '
                  '${_categoryLabel(selectedCategory, lang)}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<DictionaryTab>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: Theme.of(context).textTheme.bodySmall,
            ),
            segments: [
              ButtonSegment(
                value: DictionaryTab.all,
                label: Text(S.tabAll(lang)),
              ),
              ButtonSegment(
                value: DictionaryTab.learning,
                label: Text(S.tabLearning(lang)),
              ),
              ButtonSegment(
                value: DictionaryTab.mastered,
                label: Text(S.tabMastered(lang)),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (selection) =>
                setState(() => _tab = selection.first),
          ),
          Expanded(
            child: ref
                .watch(dictionaryEntriesProvider)
                .when(
                  data: (entries) => _buildList(entries, lang),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      _ErrorState(onRetry: _reload, lang: lang),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<DictionaryEntry> entries, AppLanguage lang) {
    // Уровень и категория уже отфильтрованы провайдером (Phase 39a);
    // вкладка применяется локально и сужает список по AND.
    final filtered = _applyTab(entries);
    if (filtered.isEmpty) {
      final colors = Theme.of(context).colorScheme;
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_off_outlined,
                size: 32,
                color: colors.outline,
              ),
              const SizedBox(height: 8),
              Text(
                _emptyMessage(lang),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _resetFilters,
                child: Text(S.resetFilters(lang)),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => WordListItem(
        entry: filtered[index],
        lang: lang,
        onStatusChanged: (target) =>
            _changeStatus(filtered[index].word.id, target),
      ),
    );
  }

  /// Ручная смена статуса слова и обновление списка (Phase 39e).
  Future<void> _changeStatus(WordId id, WordStatus target) async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    try {
      await ref.read(updateWordStatusProvider)(id, target);
      ref.invalidate(dictionaryEntriesProvider);
    } on Object catch (_) {
      if (mounted) {
        _showMessage(S.saveFailed(lang));
      }
    }
  }

  /// Разные сообщения: пустой словарь, пустой поиск, пустая вкладка.
  ///
  /// Порядок важен: пустой результат поиска не означает пустой словарь.
  String _emptyMessage(AppLanguage lang) {
    if (_search.text.trim().isNotEmpty) {
      return S.emptySearch(lang);
    }
    if (ref.read(dictionaryCategoryFilterProvider) != WordCategory.all) {
      return S.emptyCategory(lang);
    }
    if (ref.read(dictionaryLevelFilterProvider) != null) {
      return S.emptyLevel(lang);
    }
    if (_tab != DictionaryTab.all) {
      return S.emptyTab(lang);
    }
    return S.emptyDictionary(lang);
  }

  /// Сбрасывает категорию и уровень на «Все» (Phase 39c).
  void _resetFilters() {
    ref
        .read(dictionaryCategoryFilterProvider.notifier)
        .update(WordCategory.all);
    ref.read(dictionaryLevelFilterProvider.notifier).update(null);
  }

  /// Лист категорий (Phase 39c): Wrap всех 23 значений в
  /// DraggableScrollableSheet — удобно листать на малых экранах; активный
  /// чип подсвечен primary. Выбор закрывает лист и обновляет кнопку.
  Future<void> _openCategorySheet(AppLanguage lang) async {
    final selected = ref.read(dictionaryCategoryFilterProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final colors = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.filterCategories(lang),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in WordCategory.values)
                          ChoiceChip(
                            label: Text(_categoryLabel(category, lang)),
                            selected: selected == category,
                            selectedColor: colors.primary,
                            checkmarkColor: colors.onPrimary,
                            labelStyle: TextStyle(
                              color: selected == category
                                  ? colors.onPrimary
                                  : colors.onSurface,
                            ),
                            onSelected: (_) {
                              ref
                                  .read(
                                    dictionaryCategoryFilterProvider.notifier,
                                  )
                                  .update(category);
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Метка категории через S: доменный enum не хранит UI-строки (ADR-043).
  String _categoryLabel(WordCategory category, AppLanguage lang) =>
      switch (category) {
        WordCategory.all => S.filterAll(lang),
        WordCategory.animals => S.categoryAnimals(lang),
        WordCategory.nature => S.categoryNature(lang),
        WordCategory.food => S.categoryFood(lang),
        WordCategory.verbs => S.categoryVerbs(lang),
        WordCategory.adverbs => S.categoryAdverbs(lang),
        WordCategory.adjectives => S.categoryAdjectives(lang),
        WordCategory.home => S.categoryHome(lang),
        WordCategory.clothes => S.categoryClothes(lang),
        WordCategory.hobbies => S.categoryHobbies(lang),
        WordCategory.datetime => S.categoryDatetime(lang),
        WordCategory.languages => S.categoryLanguages(lang),
        WordCategory.countries => S.categoryCountries(lang),
        WordCategory.colors => S.categoryColors(lang),
        WordCategory.transport => S.categoryTransport(lang),
        WordCategory.computers => S.categoryComputers(lang),
        WordCategory.travel => S.categoryTravel(lang),
        WordCategory.health => S.categoryHealth(lang),
        WordCategory.body => S.categoryBody(lang),
        WordCategory.weather => S.categoryWeather(lang),
        WordCategory.school => S.categorySchool(lang),
        WordCategory.professions => S.categoryProfessions(lang),
        WordCategory.family => S.categoryFamily(lang),
      };
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.lang});

  final VoidCallback onRetry;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.dictionaryLoadFailed(lang)),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: Text(S.retry(lang))),
        ],
      ),
    ),
  );
}
