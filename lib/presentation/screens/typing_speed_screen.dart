import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/submit_typing_answer.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:english_edu/domain/value_objects/typing_session.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// «Typing Speed»: перевод на экране, слово — с клавиатуры (ADR-037).
class TypingSpeedScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const TypingSpeedScreen({super.key});

  @override
  ConsumerState<TypingSpeedScreen> createState() => _TypingSpeedScreenState();
}

class _TypingSpeedScreenState extends ConsumerState<TypingSpeedScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _watch = Stopwatch();
  TypingSession? _session;
  Timer? _ticker;
  int _wpm = 0;
  bool _finishing = false;

  /// Последнее ошибочное слово: карточка помощника живёт до следующего
  /// ответа и не ставит заезд на паузу (ADR-042).
  Word? _lastWrongWord;
  String _lastWrongInput = '';

  /// Ключ зелёной вспышки поля ввода после верного ответа (Phase 29b).
  int _flashKey = 0;

  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    // SnackBar живёт на корневом messenger: без этого он переживает экран
    // и всплывает поверх Home (Phase 29b).
    _messenger?.hideCurrentSnackBar();
    _ticker?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = await ref.read(generateTypingSessionProvider)();
    if (!mounted) {
      return;
    }
    _watch
      ..reset()
      ..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() {
      _session = session;
      _finishing = false;
      _wpm = 0;
      _lastWrongWord = null;
      _lastWrongInput = '';
    });
    _focus.requestFocus();
  }

  /// WPM в реальном времени: верные слова в минуту от начала заезда.
  void _tick() {
    final session = _session;
    if (!mounted || session == null || _watch.elapsed.inSeconds < 1) {
      return;
    }
    setState(() {
      _wpm = (session.correct * 60 / _watch.elapsed.inSeconds).round();
    });
  }

  Future<void> _submit(String value) async {
    final session = _session;
    final word = session?.current;
    if (session == null || word == null || _finishing) {
      return;
    }

    // Правильность считает домен: экран и сессия не должны расходиться.
    final wasCorrect = SubmitTypingAnswer.matches(word, value);

    if (wasCorrect) {
      _lastWrongWord = null;
      _lastWrongInput = '';
      _flashKey++;
    } else {
      _lastWrongWord = word;
      _lastWrongInput = value.trim();
    }

    // Отклик не ожидается: на его Future нельзя завязывать переход к слову.
    unawaited(
      wasCorrect ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact(),
    );

    final next = ref.read(submitTypingAnswerProvider)(session, value);
    _input.clear();
    if (next.isFinished) {
      setState(() => _session = next);
      await _finish(next);
      return;
    }
    setState(() => _session = next);
    _focus.requestFocus();
  }

  /// Считает результат, сохраняет рекорд и показывает итоги.
  Future<void> _finish(TypingSession session) async {
    if (_finishing) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    _finishing = true;
    _ticker?.cancel();
    _watch.stop();

    final TypingRecord record;
    try {
      record = await ref.read(saveTypingRecordProvider)(
        wordsCount: session.length,
        correctCount: session.correct,
        durationSeconds: _watch.elapsed.inSeconds,
      );
      ref.invalidate(bestTypingRecordProvider);
    } on Object {
      if (mounted) {
        setState(() => _finishing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.typingSaveFailed(lang))));
      }
      return;
    }

    if (!mounted) {
      return;
    }
    final again = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.typingRunDone(lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.typingWpm(record.wpm, lang)),
            Text(S.typingAccuracy(record.accuracyPercent, lang)),
            Text(S.typingScore(record.score, lang)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.commonExit(lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.commonAgain(lang)),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (again ?? false) {
      await _load();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final session = _session;
    final current = session?.current;

    return Scaffold(
      appBar: AppBar(title: Text(S.gameTitle('typing', lang))),
      body: session == null
          ? const Center(child: CircularProgressIndicator())
          : current == null
          ? Center(child: Text(S.commonEmptyDictionary(lang)))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${session.index}/${session.length} · $_wpm WPM',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    current.translation,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Подсказка отсекает синонимы: «еда» — meal, а не food.
                  Text(
                    S.typingLetterHint(
                      current.term.length,
                      current.term.substring(0, 1),
                      lang,
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                        controller: _input,
                        focusNode: _focus,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(fontSize: 24),
                        onSubmitted: (value) => unawaited(_submit(value)),
                      )
                      .animate(
                        key: ValueKey('flash-$_flashKey'),
                        autoPlay: _flashKey > 0,
                      )
                      .tint(
                        color: Colors.green,
                        begin: 0.3,
                        end: 0,
                        duration: 700.ms,
                      ),
                  if (_lastWrongWord != null) ...[
                    const SizedBox(height: 16),
                    _errorCard(context, _lastWrongWord!, _lastWrongInput, lang),
                  ],
                ],
              ),
            ),
    );
  }

  /// Карточка ошибки с кнопкой помощника (ADR-042).
  Widget _errorCard(
    BuildContext context,
    Word word,
    String input,
    AppLanguage lang,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              S.incorrect(lang),
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          ErrorHelperButton(
            gameType: 'typing',
            context:
                'Слово: "${word.term}". '
                'Перевод: "${word.translation}". '
                'Пользователь ввёл: "$input".',
          ),
        ],
      ),
    );
  }
}
