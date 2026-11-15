import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/phrase.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Разговорник: фразы по темам с поиском (ADR-038).
class PhrasebookScreen extends ConsumerWidget {
  /// Создаёт экран.
  const PhrasebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.gameTitle('phrasebook', lang)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: S.back(lang),
          onPressed: () => context.pop(),
        ),
      ),
      body: ref
          .watch(phrasesProvider)
          .when(
            data: (phrases) => phrases.isEmpty
                ? Center(child: Text(S.phrasebookNotLoaded(lang)))
                : _PhrasebookBody(phrases: phrases, lang: lang),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text(S.phrasebookLoadFailed(lang))),
          ),
    );
  }
}

class _PhrasebookBody extends StatefulWidget {
  const _PhrasebookBody({required this.phrases, required this.lang});

  final List<Phrase> phrases;
  final AppLanguage lang;

  @override
  State<_PhrasebookBody> createState() => _PhrasebookBodyState();
}

class _PhrasebookBodyState extends State<_PhrasebookBody> {
  final _search = TextEditingController();
  var _query = '';
  String? _selectedLevel;

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
    return [
      for (final item in items)
        if ((_selectedLevel == null ||
                item.level.toLowerCase() == _selectedLevel) &&
            (needle.isEmpty ||
                item.phrase.toLowerCase().contains(needle) ||
                item.translation.toLowerCase().contains(needle)))
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
              decoration: InputDecoration(
                labelText: S.phrasebookSearch(widget.lang),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final level in <String?>[
                  null,
                  'a1',
                  'a2',
                  'b1',
                  'b2',
                  'c1',
                  'c2',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        level?.toUpperCase() ?? S.phrasebookAll(widget.lang),
                      ),
                      selected: _selectedLevel == level,
                      onSelected: (_) => setState(() => _selectedLevel = level),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: S.phrasebookAll(widget.lang)),
              for (final category in categories) Tab(text: category),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PhraseList(items: _visible(widget.phrases), lang: widget.lang),
                for (final category in categories)
                  _PhraseList(
                    items: _visible([
                      for (final item in widget.phrases)
                        if (item.category == category) item,
                    ]),
                    lang: widget.lang,
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
  const _PhraseList({required this.items, required this.lang});

  final List<Phrase> items;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(S.phrasebookNothingFound(lang)));
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
            trailing: Chip(
              label: Text(
                item.level.toUpperCase(),
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }
}
