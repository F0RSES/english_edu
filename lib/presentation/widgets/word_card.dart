import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Карточка слова: до раскрытия виден только термин, после — перевод и пример.
class WordCard extends ConsumerWidget {
  /// Создаёт карточку.
  const WordCard({
    required this.word,
    required this.revealed,
    required this.onTap,
    super.key,
  });

  /// Слово, которое показывается.
  final Word word;

  /// Показан ли перевод.
  final bool revealed;

  /// Вызывается по тапу на карточку.
  final VoidCallback onTap;

  /// Озвучивает термин настройками из `UserSettings`.
  ///
  /// Ошибка плагина не должна ломать урок: логируем и показываем SnackBar.
  Future<void> _speak(BuildContext context, WidgetRef ref) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).get();
      await ref.read(ttsProvider).speak(
            word.term,
            voice: settings.ttsVoice,
            speed: settings.ttsSpeed,
          );
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('TTS failed', error, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Озвучка недоступна')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      word.term,
                      style: theme.textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    tooltip: 'Озвучить',
                    onPressed: () => _speak(context, ref),
                  ),
                ],
              ),
              if (word.transcription != null) ...[
                const SizedBox(height: 8),
                Text(
                  word.transcription!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: revealed
                    ? _Revealed(word: word)
                    : const Text('Нажмите, чтобы увидеть перевод'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Revealed extends StatelessWidget {
  const _Revealed({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('revealed'),
      children: [
        Text(
          word.translation,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (word.exampleSentence != null) ...[
          const SizedBox(height: 12),
          Text(
            word.exampleSentence!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
