import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/memory_card.dart';
import 'package:english_edu/domain/value_objects/memory_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Игра «Memory»: найти пары EN ↔ RU за минимум ходов (ADR-036).
class WordMatchScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const WordMatchScreen({super.key});

  @override
  ConsumerState<WordMatchScreen> createState() => _WordMatchScreenState();
}

class _WordMatchScreenState extends ConsumerState<WordMatchScreen> {
  MemoryGame? _game;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final game = await ref.read(generateMemoryGameProvider)();
    if (!mounted) {
      return;
    }
    setState(() => _game = game);
  }

  void _onTap(MemoryCard card) {
    final game = _game;
    if (game == null || card.state != MemoryCardState.hidden) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());

    final flip = ref.read(flipMemoryCardProvider);
    final next = flip(game, card.id);
    setState(() => _game = next);

    if (next.isWon) {
      unawaited(_showWin(next));
      return;
    }
    if (next.flippedCardIds.length == 2) {
      // Задержку держит UI: домен о времени не знает.
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) {
          return;
        }
        setState(() => _game = flip.resetFlipped(_game!));
      });
    }
  }

  Future<void> _showWin(MemoryGame game) async {
    unawaited(HapticFeedback.mediumImpact());
    final restart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Победа!'),
        content: Text('Все пары найдены за ${game.moves} ходов.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Выйти'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Заново'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (restart ?? false) {
      setState(() => _game = null);
      await _load();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Match'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('Ходы: ${game?.moves ?? 0}'),
            ),
          ),
        ],
      ),
      body: game == null
          ? const Center(child: CircularProgressIndicator())
          : game.cards.isEmpty
          ? const Center(child: Text('Добавьте слова в словарь'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                itemCount: game.cards.length,
                itemBuilder: (context, index) => _MemoryTile(
                  // Ключ по id карточки, а не по позиции: расклад тасуется,
                  // и тест должен находить конкретную карточку.
                  key: ValueKey('memory-card-${game.cards[index].id}'),
                  card: game.cards[index],
                  onTap: () => _onTap(game.cards[index]),
                ),
              ),
            ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.card, required this.onTap, super.key});

  final MemoryCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matched = card.state == MemoryCardState.matched;
    final visible = card.state != MemoryCardState.hidden;

    final background = switch (card.state) {
      MemoryCardState.hidden => scheme.surfaceContainerHighest,
      MemoryCardState.matched => Colors.green.withAlpha(77),
      MemoryCardState.flipped =>
        card.isEnglish ? scheme.primaryContainer : scheme.tertiaryContainer,
    };

    return Opacity(
      opacity: matched ? 0.6 : 1,
      child: GestureDetector(
        onTap: visible ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: matched
              ? Icon(Icons.check, color: scheme.primary)
              : Text(
                  visible ? card.text : '?',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: visible ? 14 : 28,
                    fontWeight: visible ? FontWeight.bold : FontWeight.w400,
                    color: scheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
