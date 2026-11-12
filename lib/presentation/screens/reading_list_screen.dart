import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/presentation/widgets/cefr_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Уровни фильтра: рассказы пишутся для A1–C1 (ADR-039).
const _filterLevels = <CefrLevel>[
  CefrLevel.a1,
  CefrLevel.a2,
  CefrLevel.b1,
  CefrLevel.b2,
  CefrLevel.c1,
];

/// Экран «Чтение»: рассказы по уровням CEFR (ADR-039).
class ReadingListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const ReadingListScreen({super.key});

  @override
  ConsumerState<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends ConsumerState<ReadingListScreen> {
  CefrLevel _level = CefrLevel.a1;

  @override
  void initState() {
    super.initState();
    unawaited(_initLevel());
  }

  /// Дефолт фильтра — уровень пользователя (ADR-023); пока настройки не
  /// прочитаны или при сбое показываем A1.
  Future<void> _initLevel() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).get();
      if (mounted) {
        setState(() => _level = settings.preferredLevel);
      }
    } on Object {
      if (mounted) {
        setState(() => _level = CefrLevel.a1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesByLevelProvider(_level));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чтение'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in _filterLevels)
                  ChoiceChip(
                    label: Text(level.label),
                    selected: _level == level,
                    onSelected: (_) => setState(() => _level = level),
                  ),
              ],
            ),
          ),
          Expanded(
            child: stories.when(
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Рассказы не загружены'))
                  : _StoryList(stories: items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  const Center(child: Text('Не удалось загрузить рассказы')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryList extends StatelessWidget {
  const _StoryList({required this.stories});

  final List<Story> stories;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: stories.length,
    itemBuilder: (context, index) {
      final story = stories[index];
      final count = story.wordCount;
      final unit = pluralize(count, one: 'слово', few: 'слова', many: 'слов');
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            story.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                CefrBadge(level: story.level),
                const SizedBox(width: 8),
                Text('$count $unit'),
              ],
            ),
          ),
          onTap: () => context.push('/reading/${story.id}'),
        ),
      );
    },
  );
}
