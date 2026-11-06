import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
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
    title: 'Карточки со словами',
    body:
        'Свайп вправо — «знаю», влево — «не знаю». '
        'Приложение само решает, когда показать слово снова.',
  ),
  _Slide(
    icon: Icons.local_fire_department_outlined,
    title: 'Серия и заморозки',
    body:
        'Занимайтесь каждый день: серия растёт, а за вехи дают '
        'заморозки, которые спасают один пропущенный день.',
  ),
  _Slide(
    icon: Icons.psychology_outlined,
    title: 'AI-подсказки',
    body:
        'Не запоминается слово? Нажмите «Подсказка» — ассоциацию '
        'придумает AI. Запрос уходит только по вашему нажатию.',
  ),
];

/// Онбординг: три экрана с анимацией и индикатором страниц.
///
/// Показывается по кнопке «Как это работает» в профиле: автоматический показ
/// при первом запуске требует сохранённого флага, а это изменение схемы БД
/// (отдельная задача, BL-61).
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Сохраняет флаг «онбординг пройден» и уходит на главную.
  ///
  /// Флаг пишется в БД: иначе экран показывался бы при каждом запуске. Ошибка
  /// записи не блокирует переход — пользователь просто увидит онбординг снова.
  Future<void> _finish() async {
    try {
      final repository = ref.read(settingsRepositoryProvider);
      final settings = await repository.get();
      await repository.save(settings.copyWith(hasSeenOnboarding: true));
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
    if (_page >= _slides.length - 1) {
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
    final isLast = _page == _slides.length - 1;
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
              itemCount: _slides.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
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
            count: _slides.length,
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
