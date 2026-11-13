import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/add_word_dialog.dart';
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
    final filtered = _applyTab(entries);
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
