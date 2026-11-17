import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_category.dart';
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
/// и складываются по AND; вкладка статуса применяется локально.
/// «Все» — все слова. «Изучаю» — `status.learning`. «Выучено» —
/// `status.mastered`. Слова без прогресса (`status == null`) видны только во
/// вкладке «Все» и помечены как новые.
class DictionaryScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

/// Высота ряда чипов категорий: ChoiceChip плюс вертикальные отступы.
const _categoryRowHeight = 48.0;

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
            child: Row(
              children: [
                Text(S.filterCategories(lang)),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: _categoryRowHeight,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final category in WordCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              label: Text(_categoryLabel(category, lang)),
                              selected: selectedCategory == category,
                              onSelected: (_) => ref
                                  .read(
                                    dictionaryCategoryFilterProvider.notifier,
                                  )
                                  .update(category),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<DictionaryTab>(
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
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_emptyMessage(lang)),
        ),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          WordListItem(entry: filtered[index], lang: lang),
    );
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
