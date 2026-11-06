import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Карточка слова: до раскрытия виден только термин, после — перевод и пример.
///
/// После раскрытия доступна AI-подсказка (ADR-019): ассоциация запрашивается
/// только по нажатию, ошибка сети не ломает урок.
class WordCard extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<WordCard> createState() => _WordCardState();
}

class _WordCardState extends ConsumerState<WordCard> {
  String? _association;
  bool _loading = false;

  /// Озвучивает термин настройками из `UserSettings`.
  ///
  /// Ошибка плагина не должна ломать урок: логируем и показываем SnackBar.
  Future<void> _speak() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).get();
      await ref
          .read(ttsProvider)
          .speak(
            widget.word.term,
            voice: settings.ttsVoice,
            speed: settings.ttsSpeed,
          );
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('TTS failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Озвучка недоступна')));
      }
    }
  }

  /// Берёт подсказку из кэша или у AI-прокси (ADR-019).
  ///
  /// Сеть — только по нажатию и только если кэша нет. Ошибка показывается
  /// SnackBar'ом, карточка остаётся рабочей.
  Future<void> _loadAssociation() async {
    setState(() => _loading = true);
    try {
      final association = await ref
          .read(getWordHintProvider)
          .call(widget.word.id, widget.word.term);
      if (!mounted) {
        return;
      }
      setState(() {
        _association = association;
        _loading = false;
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('AI hint failed', error, stack);
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить подсказку')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = widget.word;
    return GestureDetector(
      onTap: widget.onTap,
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
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    tooltip: 'Озвучить',
                    onPressed: _speak,
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
                child: widget.revealed
                    ? _Revealed(word: word)
                    : const Text('Нажмите, чтобы увидеть перевод'),
              ),
              // Подсказка доступна только после раскрытия: до ответа она
              // подсказывала бы перевод.
              if (widget.revealed) ...[
                const SizedBox(height: 12),
                if (_association case final association?)
                  _AssociationCard(text: association)
                else
                  TextButton.icon(
                    onPressed: _loading ? null : _loadAssociation,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lightbulb, color: Colors.amber),
                    label: const Text('Подсказка'),
                  ),
              ],
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Плашка с ассоциацией от AI.
class _AssociationCard extends StatelessWidget {
  const _AssociationCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
