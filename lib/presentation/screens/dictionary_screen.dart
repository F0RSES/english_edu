import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/add_word_dialog.dart';
import 'package:english_edu/presentation/widgets/word_categories.dart';
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

/// Словарь: список, поиск, фильтр по статусу, добавление слова.
///
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
  // null — фильтр по категории выключен («Все»).
  String? _selectedCategory;
  // null — фильтр по уровню выключен («Все уровни»).
  CefrLevel? _selectedLevel;

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

  /// Оставляет слова выбранной категории; при `null` не фильтрует.
  List<DictionaryEntry> _applyCategory(List<DictionaryEntry> entries) {
    final category = _selectedCategory;
    if (category == null) {
      return entries;
    }
    return [
      for (final entry in entries)
        if (entry.word.category == category) entry,
    ];
  }

  /// Оставляет слова выбранного уровня; при `null` не фильтрует.
  List<DictionaryEntry> _applyLevel(List<DictionaryEntry> entries) {
    final level = _selectedLevel;
    if (level == null) {
      return entries;
    }
    return [
      for (final entry in entries)
        if (entry.word.level == level) entry,
    ];
  }

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

  /// Имена категорий для фильтра (ADR-034).
  ///
  /// Пока список читается из БД, показывается базовый набор: фильтр не должен
  /// исчезать и «прыгать» при каждом открытии экрана.
  List<String> _categoryNames(WidgetRef ref) => ref
      .watch(userCategoriesProvider)
      .when(
        data: (categories) => [for (final item in categories) item.name],
        loading: () => wordCategories,
        error: (error, stack) => wordCategories,
      );

  void _showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
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
                for (final category in <String?>[null, ..._categoryNames(ref)])
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(category ?? S.allCategories(lang)),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                      selected: _selectedLevel == level,
                      onSelected: (_) => setState(() => _selectedLevel = level),
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
    // Категория, уровень и вкладка складываются по AND: выбранные фильтры
    // сужают список, а не заменяют друг друга.
    final filtered = _applyLevel(_applyCategory(_applyTab(entries)));
    if (filtered.isEmpty) {
      return Center(child: Text(_emptyMessage(lang)));
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
    if (_selectedCategory != null) {
      return S.emptyCategory(lang);
    }
    if (_selectedLevel != null) {
      return S.emptyLevel(lang);
    }
    if (_tab != DictionaryTab.all) {
      return S.emptyTab(lang);
    }
    return S.emptyDictionary(lang);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.lang});

  final VoidCallback onRetry;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(S.dictionaryLoadFailed(lang)),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: Text(S.retry(lang))),
      ],
    ),
  );
}
