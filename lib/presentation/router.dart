import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/presentation/screens/achievements_screen.dart';
import 'package:english_edu/presentation/screens/chat_screen.dart';
import 'package:english_edu/presentation/screens/cloze_test_screen.dart';
import 'package:english_edu/presentation/screens/dictionary_screen.dart';
import 'package:english_edu/presentation/screens/error_hunter_screen.dart';
import 'package:english_edu/presentation/screens/home_screen.dart';
import 'package:english_edu/presentation/screens/lesson_screen.dart';
import 'package:english_edu/presentation/screens/listening_dictation_screen.dart';
import 'package:english_edu/presentation/screens/onboarding_screen.dart';
import 'package:english_edu/presentation/screens/phrasebook_screen.dart';
import 'package:english_edu/presentation/screens/profile_screen.dart';
import 'package:english_edu/presentation/screens/reading_list_screen.dart';
import 'package:english_edu/presentation/screens/reading_screen.dart';
import 'package:english_edu/presentation/screens/settings_screen.dart';
import 'package:english_edu/presentation/screens/typing_speed_screen.dart';
import 'package:english_edu/presentation/screens/word_match_screen.dart';
import 'package:english_edu/presentation/screens/word_scramble_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Путь онбординга.
const _onboardingPath = '/onboarding';

/// Маршруты приложения.
///
/// `redirect` держит гейт онбординга: пока флаг в БД не выставлен, любой
/// маршрут ведёт на `/onboarding`. Ручной вход из профиля идёт с `?manual=1`,
/// иначе его тут же отбрасывало бы на главную.
final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    redirect: (context, state) {
      final seen = ref.read(onboardingSeenProvider);
      final onOnboarding = state.matchedLocation == _onboardingPath;
      final manual = state.uri.queryParameters['manual'] == '1';
      if (!seen && !onOnboarding) {
        return _onboardingPath;
      }
      if (seen && onOnboarding && !manual) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/lesson',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const LessonScreen()),
      ),
      GoRoute(
        path: '/word-match',
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const WordMatchScreen()),
      ),
      GoRoute(
        path: '/phrasebook',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const PhrasebookScreen()),
      ),
      GoRoute(
        path: '/reading',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const ReadingListScreen()),
      ),
      GoRoute(
        path: '/reading/:id',
        pageBuilder: (context, state) => _slideUpPage(
          state,
          _ReadingStoryRoute(
            storyId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: '/chat',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const ChatScreen()),
      ),
      GoRoute(
        path: '/typing-speed',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const TypingSpeedScreen()),
      ),
      GoRoute(
        path: '/listening',
        pageBuilder: (context, state) =>
            _fadePage(state, const ListeningDictationScreen()),
      ),
      GoRoute(
        path: '/word-scramble',
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const WordScrambleScreen()),
      ),
      GoRoute(
        path: '/weak-words',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const LessonScreen(mode: LessonMode.weak)),
      ),
      GoRoute(
        path: '/smart-review',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const LessonScreen(mode: LessonMode.smart)),
      ),
      GoRoute(
        path: '/error-hunter',
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const ErrorHunterScreen()),
      ),
      GoRoute(
        path: '/cloze-test',
        pageBuilder: (context, state) =>
            _fadePage(state, const ClozeTestScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/achievements',
        pageBuilder: (context, state) =>
            _fadePage(state, const AchievementsScreen()),
      ),
      GoRoute(
        path: '/dictionary',
        pageBuilder: (context, state) =>
            _fadePage(state, const DictionaryScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _fadePage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _fadePage(state, const ProfileScreen()),
      ),
    ],
  ),
);

/// Только плавное появление: переключение вкладок без слайда.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// Выезд снизу с затуханием: вход в урок.
CustomTransitionPage<void> _slideUpPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );

/// Fade + scale 0.9 → 1.0: игра и онбординг.
CustomTransitionPage<void> _fadeScalePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

/// Резолвит рассказ по id из маршрута: список может ещё грузиться,
/// а deep-link обязан работать без `extra`.
class _ReadingStoryRoute extends ConsumerWidget {
  const _ReadingStoryRoute({required this.storyId});

  final int? storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(storiesProvider)
      .when(
        data: (stories) {
          Story? found;
          for (final story in stories) {
            if (story.id == storyId) {
              found = story;
              break;
            }
          }
          if (found == null) {
            return const Scaffold(
              body: Center(child: Text('Рассказ не найден')),
            );
          }
          return ReadingScreen(story: found);
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => const Scaffold(
          body: Center(child: Text('Не удалось загрузить рассказы')),
        ),
      );
}
