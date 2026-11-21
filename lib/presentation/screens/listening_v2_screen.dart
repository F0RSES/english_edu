import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/core/theme/app_colors.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/sentence_puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Длина сессии: после пятого предложения — итоги (Phase 36b).
const _sessionLength = 5;

/// Игра «Аудио-диктант предложений» (Phase 36b).
///
/// TTS озвучивает предложение из `exampleSentence` словаря (офлайн),
/// пользователь вводит услышанное. Сравнение ответа игнорирует регистр,
/// пунктуацию и лишние пробелы. Прогресс в SRS не пишется: тренируется
/// восприятие речи, а не запоминание конкретного слова.
class ListeningV2Screen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const ListeningV2Screen({super.key});

  @override
  ConsumerState<ListeningV2Screen> createState() => _ListeningV2ScreenState();
}

class _ListeningV2ScreenState extends ConsumerState<ListeningV2Screen> {
  final _controller = TextEditingController();

  List<SentencePuzzle> _queue = const [];
  int _currentIndex = 0;
  bool _isLoading = true;

  /// Перевод-подсказка раскрыт; сбрасывается на следующем предложении.
  bool _showTranslation = false;

  /// Ответ проверен: поле заблокировано, показано «Следующее».
  bool _checked = false;
  bool _wasCorrect = false;

  int _pulseKey = 0;
  int _correctCount = 0;

  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    // SnackBar живёт на корневом messenger: без этого он переживает экран
    // и всплывает поверх Home (Phase 29b).
    _messenger?.hideCurrentSnackBar();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  SentencePuzzle? get _puzzle =>
      _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  /// Собирает сессию из пяти предложений; счётчики обнуляются.
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _queue = const [];
      _currentIndex = 0;
      _correctCount = 0;
      _checked = false;
      _wasCorrect = false;
      _showTranslation = false;
      _controller.clear();
    });
    try {
      final generator = ref.read(generateListeningSentenceProvider);
      final queue = <SentencePuzzle>[];
      for (var i = 0; i < _sessionLength; i++) {
        queue.add(await generator());
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _queue = queue;
        _isLoading = false;
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Listening sentences failed', error, stack);
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  /// Озвучивает текущее предложение настройками пользователя.
  ///
  /// Ошибка плагина не ломает игру: озвучку можно повторить, а перевод
  /// раскрывается кнопкой — предложение можно ввести и по подсказке.
  Future<void> _speak() async {
    final puzzle = _puzzle;
    if (puzzle == null) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    try {
      final settings = await ref.read(settingsRepositoryProvider).get();
      await ref
          .read(ttsProvider)
          .speak(
            puzzle.sentence,
            voice: settings.ttsVoice,
            speed: settings.ttsSpeed,
          );
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Listening TTS failed', error, stack);
      if (mounted) {
        final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
        _messenger?.showSnackBar(
          SnackBar(content: Text(S.dictationTtsUnavailable(lang))),
        );
      }
    }
  }

  /// Нормализация: нижний регистр, без пунктуации, одиночные пробелы.
  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Сверяет ввод с услышанным предложением.
  void _check() {
    final puzzle = _puzzle;
    if (puzzle == null || _checked) {
      return;
    }
    if (_controller.text.trim().isEmpty) {
      return;
    }
    final correct = _normalize(_controller.text) == _normalize(puzzle.sentence);
    unawaited(
      correct ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact(),
    );
    setState(() {
      _checked = true;
      _wasCorrect = correct;
      if (correct) {
        _correctCount++;
        _pulseKey++;
      }
    });
  }

  /// Следующее предложение; после последнего — итоги.
  void _next() {
    final next = _currentIndex + 1;
    if (next >= _queue.length) {
      unawaited(_showSummary());
      return;
    }
    setState(() {
      _currentIndex = next;
      _checked = false;
      _wasCorrect = false;
      _showTranslation = false;
      _controller.clear();
    });
  }

  Future<void> _showSummary() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.sessionDone(lang)),
        content: Text(S.sessionCorrect(_correctCount, _queue.length, lang)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/');
            },
            child: Text(S.sessionFinish(lang)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(_load());
            },
            child: Text(S.commonAgain(lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.gameListeningV2(lang)),
        actions: [
          if (puzzle != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentIndex + 1}/${_queue.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : puzzle == null
            ? _ErrorState(lang: lang, onRetry: _load)
            : _SentenceView(
                puzzle: puzzle,
                controller: _controller,
                showTranslation: _showTranslation,
                checked: _checked,
                wasCorrect: _wasCorrect,
                pulseKey: _pulseKey,
                lang: lang,
                onSpeak: _speak,
                onShowTranslation: () =>
                    setState(() => _showTranslation = true),
                onCheck: _check,
                onNext: _next,
              ),
      ),
    );
  }
}

/// Динамик, перевод-подсказка, поле ввода и проверка.
class _SentenceView extends StatelessWidget {
  const _SentenceView({
    required this.puzzle,
    required this.controller,
    required this.showTranslation,
    required this.checked,
    required this.wasCorrect,
    required this.pulseKey,
    required this.lang,
    required this.onSpeak,
    required this.onShowTranslation,
    required this.onCheck,
    required this.onNext,
  });

  final SentencePuzzle puzzle;
  final TextEditingController controller;
  final bool showTranslation;
  final bool checked;
  final bool wasCorrect;
  final int pulseKey;
  final AppLanguage lang;
  final VoidCallback onSpeak;
  final VoidCallback onShowTranslation;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.listeningInstruction(lang),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: IconButton.filled(
              key: const ValueKey('speak-button'),
              onPressed: onSpeak,
              iconSize: 48,
              padding: const EdgeInsets.all(24),
              icon: const Icon(Icons.volume_up),
            ),
          ),
          const SizedBox(height: 8),
          if (showTranslation)
            Text(
              puzzle.translation,
              key: const ValueKey('translation-hint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
          else
            Center(
              child: TextButton(
                key: const ValueKey('show-translation'),
                onPressed: onShowTranslation,
                child: Text(
                  S.listeningShowTranslation(lang),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
                key: const ValueKey('answer-field'),
                controller: controller,
                enabled: !checked,
                minLines: 3,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                onSubmitted: (_) => onCheck(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  hintText: S.listeningHint(lang),
                  border: const OutlineInputBorder(),
                ),
              )
              .animate(key: ValueKey('pulse-$pulseKey'), autoPlay: pulseKey > 0)
              .tint(
                color: AppColors.accentPurple(context),
                begin: 0.3,
                end: 0,
                duration: 800.ms,
              ),
          const SizedBox(height: 16),
          if (checked && !wasCorrect) ...[
            Container(
              key: const ValueKey('wrong-card'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                S.listeningWrongAnswer(puzzle.sentence, lang),
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (checked)
            FilledButton(
              key: const ValueKey('next-button'),
              onPressed: onNext,
              child: Text(S.commonNextTask(lang)),
            )
          else
            FilledButton(
              key: const ValueKey('check-button'),
              onPressed: onCheck,
              child: Text(S.check(lang)),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.lang, required this.onRetry});

  final AppLanguage lang;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(S.commonLoadFailed(lang)),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: Text(S.retry(lang))),
      ],
    ),
  );
}
