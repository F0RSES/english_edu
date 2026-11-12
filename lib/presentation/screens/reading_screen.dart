import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Экран рассказа: текст, перевод по кнопке и незнакомые слова (ADR-039).
class ReadingScreen extends ConsumerStatefulWidget {
  /// Создаёт экран для [story].
  const ReadingScreen({required this.story, super.key});

  /// Рассказ, который читают.
  final Story story;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  var _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final story = widget.story;
    return Scaffold(
      appBar: AppBar(
        title: Text(story.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  story.text,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  setState(() => _showTranslation = !_showTranslation),
              child: Text(
                _showTranslation ? 'Скрыть перевод' : 'Показать перевод',
              ),
            ),
            if (_showTranslation) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    story.translation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => _UnknownWordsDialog(story: story),
              ),
              child: const Text('Незнакомые слова'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог незнакомых слов: список из текста рассказа и добавление в словарь.
class _UnknownWordsDialog extends ConsumerStatefulWidget {
  const _UnknownWordsDialog({required this.story});

  final Story story;

  @override
  ConsumerState<_UnknownWordsDialog> createState() =>
      _UnknownWordsDialogState();
}

class _UnknownWordsDialogState extends ConsumerState<_UnknownWordsDialog> {
  late final Future<List<String>> _unknown;
  var _adding = false;

  @override
  void initState() {
    super.initState();
    _unknown = ref.read(extractUnknownWordsProvider)(widget.story.text);
  }

  /// Добавляет слова с переводом-заглушкой «?»: пользователь отредактирует
  /// его вручную в словаре (ADR-039). Пропускать слово хуже, чем заглушка.
  Future<void> _add(List<String> words) async {
    setState(() => _adding = true);
    final repo = ref.read(wordRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final term in words) {
        final id = await repo.nextId();
        await repo.upsert(
          Word(id: id, term: term, translation: '?', level: widget.story.level),
        );
      }
      if (!mounted) {
        return;
      }
      ref.invalidate(dictionaryEntriesProvider);
      Navigator.of(context).pop();
      final unit = pluralize(
        words.length,
        one: 'слово',
        few: 'слова',
        many: 'слов',
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Добавлено ${words.length} $unit')),
      );
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Add unknown words failed', error, stack);
      if (mounted) {
        setState(() => _adding = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('Не удалось добавить слова')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Незнакомые слова'),
    content: SizedBox(
      width: double.maxFinite,
      child: FutureBuilder<List<String>>(
        future: _unknown,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Text('Не удалось разобрать текст');
          }
          final words = snapshot.data ?? const <String>[];
          if (words.isEmpty) {
            return const Text('Все слова в тексте уже в словаре.');
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final word in words)
                ListTile(dense: true, title: Text(word)),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Закрыть'),
      ),
      FutureBuilder<List<String>>(
        future: _unknown,
        builder: (context, snapshot) {
          final words = snapshot.data ?? const <String>[];
          if (words.isEmpty) {
            return const SizedBox.shrink();
          }
          final unit = pluralize(
            words.length,
            one: 'слово',
            few: 'слова',
            many: 'слов',
          );
          return FilledButton(
            onPressed: _adding ? null : () => _add(words),
            child: Text('Добавить ${words.length} $unit'),
          );
        },
      ),
    ],
  );
}
