import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/phrase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Разговорник: фразы по темам с поиском (ADR-038).
class PhrasebookScreen extends ConsumerWidget {
  /// Создаёт экран.
  const PhrasebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Разговорник'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Назад',
        onPressed: () => context.pop(),
      ),
    ),
    body: ref
        .watch(phrasesProvider)
        .when(
          data: (phrases) => phrases.isEmpty
              ? const Center(child: Text('Фразы не загружены'))
              : _PhrasebookBody(phrases: phrases),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              const Center(child: Text('Не удалось загрузить фразы')),
        ),
  );
}

class _PhrasebookBody extends StatefulWidget {
  const _PhrasebookBody({required this.phrases});

  final List<Phrase> phrases;

  @override
  State<_PhrasebookBody> createState() => _PhrasebookBodyState();
}

class _PhrasebookBodyState extends State<_PhrasebookBody> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Категории из данных: новая тема в контенте создаёт новую вкладку.
  List<String> get _categories {
    final seen = <String>[];
    for (final item in widget.phrases) {
      if (!seen.contains(item.category)) {
        seen.add(item.category);
      }
    }
    return seen;
  }

  List<Phrase> _visible(List<Phrase> items) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) {
      return items;
    }
    return [
      for (final item in items)
        if (item.phrase.toLowerCase().contains(needle) ||
            item.translation.toLowerCase().contains(needle))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    return DefaultTabController(
      length: categories.length + 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Поиск',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Все'),
              for (final category in categories) Tab(text: category),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PhraseList(items: _visible(widget.phrases)),
                for (final category in categories)
                  _PhraseList(
                    items: _visible(
                      [
                        for (final item in widget.phrases)
                          if (item.category == category) item,
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhraseList extends StatelessWidget {
  const _PhraseList({required this.items});

  final List<Phrase> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Ничего не найдено'));
    }
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              item.phrase,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.translation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
