import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Один шаг онбординга.
class _Slide {
  const _Slide({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

const _slides = <_Slide>[
  _Slide(
    icon: Icons.style_outlined,
    title: 'Учи слова легко',
    body:
        'Свайп вправо — «знаю», влево — «не знаю». '
        'Приложение само решает, когда показать слово снова.',
  ),
  _Slide(
    icon: Icons.lightbulb_outline,
    title: 'AI-подсказки',
    body:
        'Не запоминается слово? Нажмите «Подсказка» — ассоциацию '
        'придумает AI. Запрос уходит только по вашему нажатию.',
  ),
  _Slide(
    icon: Icons.sports_esports_outlined,
    title: 'Играй и запоминай',
    body:
        '«Охота на ошибки»: найдите ошибку в предложении и выберите '
        'правильный вариант. Пять минут между делами.',
  ),
];

/// Онбординг: три знакомящих экрана и выбор уровня CEFR (ADR-023).
///
/// Показывается при первом запуске и по кнопке «Как это работает» в профиле.
/// Последняя страница — уровень: он фильтрует новые слова в очереди, поэтому
/// спрашивать его нужно до первого урока.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  // Уровень по умолчанию — A1: на нём же стоят слова без метки.
  CefrLevel _selectedLevel = CefrLevel.a1;

  /// Всего страниц: знакомство + выбор уровня.
  int get _pageCount => _slides.length + 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Сохраняет флаг «онбординг пройден» и выбранный уровень, уходит на главную.
  ///
  /// Флаг пишется в БД: иначе экран показывался бы при каждом запуске. Ошибка
  /// записи не блокирует переход — пользователь просто увидит онбординг снова.
  Future<void> _finish() async {
    try {
      final repository = ref.read(settingsRepositoryProvider);
      final settings = await repository.get();
      await repository.save(
        settings.copyWith(
          hasSeenOnboarding: true,
          preferredLevel: _selectedLevel,
        ),
      );
      ref.read(onboardingSeenProvider.notifier).markSeen();
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Onboarding save failed', error, stack);
    }
    if (!mounted) {
      return;
    }
    context.go('/');
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      unawaited(_finish());
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pageCount - 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Как это работает'),
        actions: [
          TextButton(
            onPressed: () => unawaited(_finish()),
            child: const Text('Пропустить'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pageCount,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                if (index == _slides.length) {
                  return _LevelPage(
                    selected: _selectedLevel,
                    onChanged: (level) =>
                        setState(() => _selectedLevel = level),
                  );
                }
                final slide = _slides[index];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                            slide.icon,
                            size: 96,
                            color: theme.colorScheme.primary,
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 32),
                      Text(
                            slide.title,
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          )
                          .animate(delay: 120.ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.25, curve: Curves.easeOutCubic),
                      const SizedBox(height: 16),
                      Text(
                        slide.body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 220.ms).fadeIn(duration: 350.ms),
                    ],
                  ),
                );
              },
            ),
          ),
          AnimatedSmoothIndicator(
            activeIndex: _page,
            count: _pageCount,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              activeDotColor: theme.colorScheme.primary,
              dotColor: theme.colorScheme.outlineVariant,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: _next,
              child: Text(isLast ? 'Начать' : 'Далее'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Последняя страница онбординга: выбор уровня CEFR (ADR-023).
///
/// Уровень влияет на новые слова в очереди, поэтому спрашивается до старта.
/// Выбор уходит наверх через [onChanged]: экран держит одно состояние на все
/// страницы и сохраняет его в настройки одним вызовом.
class _LevelPage extends StatelessWidget {
  const _LevelPage({required this.selected, required this.onChanged});

  final CefrLevel selected;
  final ValueChanged<CefrLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 96, color: theme.colorScheme.primary)
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 32),
          Text(
            'Какой у тебя уровень?',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Новые слова подбираются не выше выбранного уровня. '
            'Слова, которые вы уже учите, не фильтруются.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in CefrLevel.values)
                ChoiceChip(
                  label: Text(level.label),
                  tooltip: level.description,
                  selected: selected == level,
                  onSelected: (_) => onChanged(level),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            selected.description,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
