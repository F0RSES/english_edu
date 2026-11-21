import 'dart:async';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/core/theme/app_colors.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/presentation/widgets/ai_word_helper.dart';
import 'package:english_edu/presentation/widgets/app_bottom_sheet.dart';
import 'package:english_edu/presentation/widgets/bulk_dictionary_sheet.dart';
import 'package:english_edu/presentation/widgets/sentence_analysis_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Пауза после неверного выбора: карточка красная, затем сброс (Phase 26b).
const _wrongResetDelay = Duration(milliseconds: 500);

/// Прозрачность фона правильного варианта (Phase 54b).
const _correctOptionBgAlpha = 0.2;

/// Мини-игра «Заполни пропуск» (ADR-025, Phase 26b).
///
/// Задание генерирует AI-прокси по случайному слову словаря и кэширует его в
/// БД, поэтому повторный показ того же слова не ходит в сеть. Пользователь
/// выбирает пропущенное слово из 5 вариантов тапом — без ввода текста.
/// Варианты перемешиваются (Phase 54a): прокси отдаёт correctWord первым.
class ClozeTestScreen extends ConsumerStatefulWidget {
  /// Создаёт экран; [random] внедряется для детерминированных тестов.
  ClozeTestScreen({super.key, Random? random}) : random = random ?? Random();

  /// Источник случайности: выбор слова и перемешивание вариантов (54a).
  final Random random;

  @override
  ConsumerState<ClozeTestScreen> createState() => _ClozeTestScreenState();
}

class _ClozeTestScreenState extends ConsumerState<ClozeTestScreen> {
  ClozeTask? _task;
  bool _loading = true;
  bool _solved = false;

  /// Выбранный неверный вариант: карточка красная до сброса через 500 мс.
  String? _wrongOption;

  /// Идёт пауза после неверного выбора: тапы заблокированы.
  bool _waiting = false;

  /// Правильное слово раскрыто в предложении после неверного ответа
  /// и живёт до следующего задания (Phase 30b).
  bool _revealed = false;

  /// Меняется при ошибке: новый ключ перезапускает shake-анимацию.
  int _shakeKey = 0;

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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Берёт случайное слово словаря и задание к нему.
  ///
  /// Слово выбирается до запроса: кэш заданий ключуется по `wordId`, поэтому
  /// «Следующее задание» может вернуть уже готовое задание без сети.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _solved = false;
      _wrongOption = null;
      _waiting = false;
      _revealed = false;
      _task = null;
    });
    try {
      // Слова строго выбранного уровня (Phase 28b): раньше игра брала весь
      // словарь и могла дать задание выше уровня пользователя.
      final settings = await ref.read(settingsRepositoryProvider).get();
      final words = await ref
          .read(wordRepositoryProvider)
          .getByLevel(settings.preferredLevel);
      if (words.isEmpty) {
        throw StateError('dictionary is empty');
      }
      final word = words[widget.random.nextInt(words.length)];
      final task = await ref.read(getClozeTaskProvider)(word.id, word.term);
      if (!mounted) {
        return;
      }
      // Прокси отдаёт correctWord первым (Phase 54a): перемешиваем копию
      // один раз на загрузку — порядок стабилен до следующего задания,
      // кэш не мутируется (options в ClozeTask — unmodifiable).
      final shuffled = task.copyWith(
        options: List<String>.from(task.options)..shuffle(widget.random),
      );
      setState(() {
        _task = shuffled;
        _loading = false;
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Cloze task failed', error, stack);
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  /// Тап по варианту: верный закрывает задание, неверный сбрасывается.
  Future<void> _choose(ClozeTask task, String option) async {
    if (_solved || _waiting) {
      return;
    }
    final correct =
        option.trim().toLowerCase() == task.correctWord.trim().toLowerCase();
    if (correct) {
      unawaited(HapticFeedback.selectionClick());
      setState(() {
        _solved = true;
        _wrongOption = null;
      });
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _wrongOption = option;
      _revealed = true;
      _waiting = true;
      _shakeKey++;
    });
    await Future<void>.delayed(_wrongResetDelay);
    if (!mounted) {
      return;
    }
    setState(() {
      _wrongOption = null;
      _waiting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Scaffold(
      appBar: AppBar(title: Text(S.gameTitle('cloze', lang))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : task == null
            ? _ErrorState(lang: lang, onRetry: _load)
            : _TaskView(
                task: task,
                solved: _solved,
                revealed: _revealed,
                wrongOption: _wrongOption,
                shakeKey: _shakeKey,
                lang: lang,
                onChoose: (option) => unawaited(_choose(task, option)),
                onNext: () => unawaited(_load()),
              ),
      ),
    );
  }
}

class _TaskView extends StatelessWidget {
  const _TaskView({
    required this.task,
    required this.solved,
    required this.revealed,
    required this.wrongOption,
    required this.shakeKey,
    required this.lang,
    required this.onChoose,
    required this.onNext,
  });

  /// Пропуск в предложении, который визуально подчёркивается.
  static const _blank = '___';

  final ClozeTask task;
  final bool solved;
  final bool revealed;
  final String? wrongOption;
  final int shakeKey;
  final AppLanguage lang;
  final ValueChanged<String> onChoose;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Предложение в карточке: текст не висит на голом фоне (Phase 27c).
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                      TextSpan(
                        children: _sentenceSpans(
                          task.sentence,
                          TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.accentPurple(context),
                            decorationThickness: 2,
                            color: AppColors.accentPurple(context),
                          ),
                          revealedWord: revealed || solved
                              ? task.correctWord
                              : null,
                        ),
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.45,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                if (revealed || solved) ...[
                  const SizedBox(height: 12),
                  AiWordHelper(word: task.correctWord, iconSize: 16),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: ListView(
            children: [
              for (final option in task.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionCard(
                    option: option,
                    state: solved && _isCorrect(option)
                        ? _OptionState.correct
                        : option == wrongOption
                        ? _OptionState.wrong
                        : _OptionState.idle,
                    enabled: !solved,
                    shakeKey: shakeKey,
                    onTap: () => onChoose(option),
                  ),
                ),
            ],
          ),
        ),
        // Разбор предложения — главная кнопка (Phase 54c); слова задания
        // (массовое добавление, Phase 52b) — отдельная иконка рядом.
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => unawaited(
                    SentenceAnalysisSheet.show(
                      context,
                      sentence: task.sentence,
                      correctWord: task.correctWord,
                      lang: lang,
                    ),
                  ),
                  icon: const Icon(Icons.menu_book),
                  label: Text(S.parseSentence(lang)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('cloze-bulk-words'),
                tooltip: S.wordsInTask(lang),
                icon: const Icon(Icons.list_alt),
                onPressed: () => unawaited(_openBulkSheet(context)),
              ),
            ],
          ),
        ),
        if (solved)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(S.commonNextTask(lang)),
            ),
          ),
      ],
    );
  }

  bool _isCorrect(String option) =>
      option.trim().toLowerCase() == task.correctWord.trim().toLowerCase();

  /// Лист слов задания в едином стиле AppBottomSheet (Phase 30b, 53c).
  Future<void> _openBulkSheet(BuildContext context) =>
      AppBottomSheet.show<void>(
        context,
        BulkDictionarySheet(words: task.options),
      );

  /// Разбивает предложение на спаны, подчёркивая только пропуск.
  ///
  /// Плоский текст остаётся исходным (`toPlainText`), поэтому поиск по тексту
  /// в тестах и для accessibility видит то же предложение.
  List<InlineSpan> _sentenceSpans(
    String sentence,
    TextStyle blankStyle, {
    String? revealedWord,
  }) {
    final spans = <InlineSpan>[];
    var rest = sentence;
    while (true) {
      final index = rest.indexOf(_blank);
      if (index < 0) {
        spans.add(TextSpan(text: rest));
        return spans;
      }
      if (index > 0) {
        spans.add(TextSpan(text: rest.substring(0, index)));
      }
      spans.add(
        TextSpan(
          text: revealedWord ?? _blank,
          style: revealedWord == null
              ? blankStyle
              : blankStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
        ),
      );
      rest = rest.substring(index + _blank.length);
      if (rest.isEmpty) {
        return spans;
      }
    }
  }
}

/// Состояние карточки-варианта (Phase 26b).
enum _OptionState { idle, correct, wrong }

/// Карточка варианта: тап, фиолетовая на успех (54b), красная + shake
/// на ошибке.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.state,
    required this.enabled,
    required this.shakeKey,
    required this.onTap,
  });

  final String option;
  final _OptionState state;
  final bool enabled;
  final int shakeKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = AppColors.accentPurple(context);
    Color background;
    Color foreground;
    Color? border;
    switch (state) {
      case _OptionState.correct:
        background = accent.withValues(alpha: _correctOptionBgAlpha);
        foreground = accent;
        border = accent;
      case _OptionState.wrong:
        background = colors.errorContainer;
        foreground = colors.onErrorContainer;
        border = colors.error;
      case _OptionState.idle:
        background = colors.surfaceContainerHighest;
        foreground = colors.onSurface;
        border = null;
    }
    final card = Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('option-$option'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: border == null ? null : Border.all(color: border, width: 2),
          ),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
    if (state == _OptionState.correct) {
      // Успех виден без SnackBar: зелёная карточка + pulse (Phase 29b).
      return card
          .animate(key: ValueKey('pulse-$option'), autoPlay: true)
          .scaleXY(begin: 1, end: 1.05, duration: 200.ms, curve: Curves.easeOut)
          .then()
          .scaleXY(end: 1, duration: 200.ms, curve: Curves.easeOutBack);
    }
    if (state == _OptionState.wrong) {
      return card
          .animate(key: ValueKey('shake-$shakeKey'), autoPlay: true)
          .shakeX(amount: 8, hz: 6, duration: 400.ms);
    }
    return card;
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
