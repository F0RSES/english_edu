import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/usecases/submit_typing_answer.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:english_edu/domain/value_objects/typing_session.dart';
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
  bool _finishing = false;

  /// Прошедшее время заезда в секундах — таймер M:SS (Phase 55a).
  int _elapsedSeconds = 0;

  /// Цвет рамки поля после проверки: зелёный/красный, null — нейтральная.
  Color? _feedbackBorder;

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
      _elapsedSeconds = 0;
      _feedbackBorder = null;
    });
    _focus.requestFocus();
  }

  /// Таймер заезда: обновляет прошедшее время раз в секунду (Phase 55a).
  void _tick() {
    if (!mounted || _session == null) {
      return;
    }
    setState(() {
      _elapsedSeconds = _watch.elapsed.inSeconds;
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

    // Блиц: только цвет рамки, без плашек и шторки помощника (Phase 55a).
    setState(() {
      _feedbackBorder = wasCorrect ? Colors.green : Colors.redAccent;
    });

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
                  // Блиц-панель: таймер слева, прогресс справа (Phase 55a).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statChip(
                        icon: Icons.timer_outlined,
                        text: _formatElapsed(_elapsedSeconds),
                      ),
                      _statChip(
                        icon: Icons.format_list_numbered,
                        text: '${session.index} / ${session.length}',
                      ),
                    ],
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
                  // Рамка плавно меняет цвет на верный/неверный ответ.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _feedbackBorder ?? theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(fontSize: 24),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() => _feedbackBorder = null),
                      onSubmitted: (value) => unawaited(_submit(value)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Контейнер статистики блиц-панели: иконка + текст (Phase 55a).
  Widget _statChip({required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Прошедшее время в формате M:SS (например, 0:45).
  String _formatElapsed(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
