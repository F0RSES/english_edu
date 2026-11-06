import 'package:english_edu/presentation/screens/dictionary_screen.dart';
import 'package:english_edu/presentation/screens/error_hunter_screen.dart';
import 'package:english_edu/presentation/screens/home_screen.dart';
import 'package:english_edu/presentation/screens/lesson_screen.dart';
import 'package:english_edu/presentation/screens/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Маршруты приложения.
final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/lesson',
        builder: (context, state) => const LessonScreen(),
      ),
      GoRoute(
        path: '/error-hunter',
        builder: (context, state) => const ErrorHunterScreen(),
      ),
      GoRoute(
        path: '/dictionary',
        builder: (context, state) => const DictionaryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  ),
);
