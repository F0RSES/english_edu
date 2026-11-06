import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/add_word_dialog.dart';
import 'package:english_edu/presentation/widgets/word_categories.dart';
import 'package:english_edu/presentation/widgets/word_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _addWord() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => const AddWordDialog(),
    );
    if (added ?? false) {
      ref.invalidate(dictionaryEntriesProvider);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Словарь'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Добавить слово',
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
            decoration: const InputDecoration(
              hintText: 'Поиск...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                ref.read(dictionarySearchQueryProvider.notifier).update(value),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final category in <String?>[null, ...wordCategories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category ?? 'Все категории'),
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
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(level?.label ?? 'Все уровни'),
                    selected: _selectedLevel == level,
                    onSelected: (_) => setState(() => _selectedLevel = level),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<DictionaryTab>(
          segments: const [
            ButtonSegment(value: DictionaryTab.all, label: Text('Все')),
            ButtonSegment(value: DictionaryTab.learning, label: Text('Изучаю')),
            ButtonSegment(
              value: DictionaryTab.mastered,
              label: Text('Выучено'),
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
                data: _buildList,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _ErrorState(onRetry: _reload),
              ),
        ),
      ],
    ),
  );

  Widget _buildList(List<DictionaryEntry> entries) {
    // Категория, уровень и вкладка складываются по AND: выбранные фильтры
    // сужают список, а не заменяют друг друга.
    final filtered = _applyLevel(_applyCategory(_applyTab(entries)));
    if (filtered.isEmpty) {
      return Center(child: Text(_emptyMessage()));
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => WordListItem(entry: filtered[index]),
    );
  }

  /// Разные сообщения: пустой словарь, пустой поиск, пустая вкладка.
  ///
  /// Порядок важен: пустой результат поиска не означает пустой словарь.
  String _emptyMessage() {
    if (_search.text.trim().isNotEmpty) {
      return 'Ничего не найдено';
    }
    if (_selectedCategory != null) {
      return 'В этой категории пока пусто';
    }
    if (_selectedLevel != null) {
      return 'Для этого уровня пока пусто';
    }
    if (_tab != DictionaryTab.all) {
      return 'В этой вкладке пока пусто';
    }
    return 'Словарь пуст — добавьте первое слово';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Не удалось загрузить словарь'),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    ),
  );
}
