import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:english_edu/domain/value_objects/typing_session.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
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

    final typed = value.trim().toLowerCase();
    final expected = word.term.trim().toLowerCase();
    final wasCorrect = typed == expected;

    if (wasCorrect) {
      _lastWrongWord = null;
      _lastWrongInput = '';
    } else {
      _lastWrongWord = word;
      _lastWrongInput = value.trim();
    }

    // Отклик не ожидается: на его Future нельзя завязывать переход к слову.
    unawaited(
      wasCorrect ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact(),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(wasCorrect ? 'Верно!' : 'Было: ${word.term}'),
          backgroundColor: wasCorrect ? Colors.green : Colors.red,
          duration: const Duration(milliseconds: 700),
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить результат')),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }
    final again = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заезд завершён'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WPM: ${record.wpm}'),
            Text('Точность: ${record.accuracyPercent}%'),
            Text('Очки: ${record.score}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Выйти'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ещё раз'),
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
    final session = _session;
    final current = session?.current;

    return Scaffold(
      appBar: AppBar(title: const Text('Typing Speed')),
      body: session == null
          ? const Center(child: CircularProgressIndicator())
          : current == null
          ? const Center(child: Text('Добавьте слова в словарь'))
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
                  ),
                  if (_lastWrongWord != null) ...[
                    const SizedBox(height: 16),
                    _errorCard(context, _lastWrongWord!, _lastWrongInput),
                  ],
                ],
              ),
            ),
    );
  }

  /// Карточка ошибки с кнопкой помощника (ADR-042).
  Widget _errorCard(BuildContext context, Word word, String input) {
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
              'Неверно',
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
