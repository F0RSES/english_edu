import 'dart:async';
import 'dart:io';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/analytics.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/daily_goal.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Профиль — витрина успехов: кто я, сколько сделал, что открыл (Phase 20).
class ProfileScreen extends ConsumerWidget {
  /// Создаёт экран.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.profile(lang)),
        // Явная кнопка: профиль открывается вкладкой снизу, и системного
        // «назад» у него нет — без этого из экрана не выбраться.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: S.back(lang),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Identity(lang: lang),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.smart_toy),
                title: Text(S.assistant(lang)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/chat'),
              ),
            ),
            const SizedBox(height: 16),
            _Stats(
              streak: ref.watch(computeStreakProvider),
              analytics: ref.watch(analyticsProvider),
              xp: ref.watch(dailyGoalProvider),
              lang: lang,
            ),
            const SizedBox(height: 16),
            _Achievements(
              achievements: ref.watch(achievementsProvider),
              lang: lang,
            ),
            const SizedBox(height: 16),
            const _WeekChartCard(),
          ],
        ),
      ),
    );
  }
}

/// Аватар, никнейм и уровень на градиентной подложке (Phase 28c, ADR-044).
///
/// Аватар и никнейм редактируются по явному тапу на карандаш; файл аватара
/// живёт локально, в настройках хранится только путь.
class _Identity extends ConsumerWidget {
  const _Identity({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider).value;
    final nickname = settings?.nickname;
    final avatarPath = settings?.avatarPath;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              _avatar(context, ref, avatarPath),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton(
                  tooltip: S.personalization(lang),
                  style: IconButton.styleFrom(
                    // Контрастная подложка: на аватаре цвета primary карандаш
                    // сливался с фоном (Phase 30a).
                    backgroundColor: scheme.surface,
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () => unawaited(
                    _openAvatarSheet(context, ref, avatarPath, nickname),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  nickname ?? S.learner(lang),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            S.levelLabel(settings?.preferredLevel.label ?? 'A1', lang),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Аватар из файла; отсутствующий файл (например, после импорта снимка)
  /// даёт fallback-иконку, а не ошибку загрузки изображения.
  Widget _avatar(BuildContext context, WidgetRef ref, String? avatarPath) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = CircleAvatar(
      radius: 50,
      backgroundColor: scheme.primary,
      child: Icon(Icons.person, size: 54, color: scheme.onPrimary),
    );
    if (avatarPath == null) {
      return fallback;
    }
    return FutureBuilder<File?>(
      future: ref.read(avatarStorageProvider).getAvatarFile(avatarPath),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return fallback;
        }
        return CircleAvatar(radius: 50, backgroundImage: FileImage(file));
      },
    );
  }

  /// Лист персонализации: аватар и никнейм из одной кнопки (Phase 29b).
  Future<void> _openAvatarSheet(
    BuildContext context,
    WidgetRef ref,
    String? currentPath,
    String? nickname,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                S.personalization(lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(S.gallery(lang)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_pickAvatar(context, ref, currentPath));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(S.changeNickname(lang)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_editNickname(context, ref, nickname));
              },
            ),
            if (currentPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(S.removeAvatar(lang)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_removeAvatar(context, ref, currentPath));
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(S.cancel(lang)),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Выбор фото из галереи: файл копируется в avatars, путь — в настройки.
  ///
  /// Старый файл удаляется после успешного сохранения нового, чтобы не
  /// копить сироты; отмена picker'а ничего не меняет.
  Future<void> _pickAvatar(
    BuildContext context,
    WidgetRef ref,
    String? oldPath,
  ) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      final storage = ref.read(avatarStorageProvider);
      final path = await storage.saveAvatar(File(picked.path));
      final repo = ref.read(settingsRepositoryProvider);
      final settings = await repo.get();
      await repo.save(settings.copyWith(avatarPath: path));
      if (oldPath != null && oldPath != path) {
        await storage.deleteAvatar(oldPath);
      }
      ref.invalidate(settingsProvider);
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Avatar pick failed', error, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.saveFailed(lang))));
      }
    }
  }

  /// Удаление аватара: путь обнуляется в настройках, файл удаляется.
  Future<void> _removeAvatar(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final settings = await repo.get();
      await repo.save(settings.copyWith(avatarPath: null));
      await ref.read(avatarStorageProvider).deleteAvatar(path);
      ref.invalidate(settingsProvider);
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Avatar remove failed', error, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.saveFailed(lang))));
      }
    }
  }

  /// Диалог никнейма: до 30 символов, пустая строка очищает ник.
  Future<void> _editNickname(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _NicknameDialog(lang: lang, initial: current ?? ''),
    );
    if (result == null || !context.mounted) {
      return;
    }
    final trimmed = result.trim();
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final settings = await repo.get();
      await repo.save(
        settings.copyWith(nickname: trimmed.isEmpty ? null : trimmed),
      );
      ref.invalidate(settingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.nicknameSaved(lang))));
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Nickname save failed', error, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.saveFailed(lang))));
      }
    }
  }
}

/// Диалог никнейма (Phase 28c): владеет контроллером и освобождает его в
/// dispose — иначе TextField использует контроллер после dispose во время
/// анимации закрытия диалога.
class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.lang, required this.initial});

  final AppLanguage lang;
  final String initial;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(S.enterNickname(widget.lang)),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 30,
      decoration: InputDecoration(hintText: S.enterNickname(widget.lang)),
      onSubmitted: (value) => Navigator.of(context).pop(value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(S.cancel(widget.lang)),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text),
        child: Text(S.saveNickname(widget.lang)),
      ),
    ],
  );
}

/// Три метрики в тонированных карточках.
class _Stats extends StatelessWidget {
  const _Stats({
    required this.streak,
    required this.analytics,
    required this.xp,
    required this.lang,
  });

  final AsyncValue<StreakInfo> streak;
  final AsyncValue<Analytics> analytics;
  final AsyncValue<DailyGoal> xp;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StatCard(
        label: S.statStreak(lang),
        value: '${streak.value?.count ?? 0}',
      ),
      const SizedBox(width: 12),
      // «Слов» — изученные (mastered), а не весь словарь (Phase 28a).
      _StatCard(
        label: S.statWords(lang),
        value: '${analytics.value?.masteredCount ?? 0}',
      ),
      const SizedBox(width: 12),
      _StatCard(
        label: S.statXp(lang),
        value: '${xp.value?.stats?.xpGained ?? 0}',
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Открытые достижения или аккуратная заглушка.
class _Achievements extends StatelessWidget {
  const _Achievements({required this.achievements, required this.lang});

  final AsyncValue<List<Achievement>> achievements;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = achievements.value ?? const <Achievement>[];
    final unlocked = [
      for (final item in items)
        if (item.isUnlocked) item,
    ];
    final total = items.isEmpty ? 0 : items.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.achievementsHeader(unlocked.length, total, lang),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: S.allAchievementsTooltip(lang),
                  onPressed: () => context.push('/achievements'),
                ),
              ],
            ),
            if (unlocked.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  S.noAchievements(lang),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: unlocked.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = unlocked[index];
                    return SizedBox(
                      width: 88,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.type.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            S.achievementTitle(item.type, lang),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Высота самого высокого столбца графика.
const _chartHeight = 72.0;

/// Минимальная видимая высота столбца: пустой день тоже должен читаться.
const _minBarHeight = 4.0;

/// Недельная статистика: карточка «За 7 дней» с 7 столбиками (Phase 29a).
///
/// Восстановлена после 28a, который удалил её вместе со всей
/// `AnalyticsSection`; метрики, трудные слова и прогноз mastery не
/// возвращены — они удалены намеренно. Дизайн столбцов — как в
/// `AnalyticsSection` до 28a (ADR-021).
class _WeekChartCard extends ConsumerWidget {
  const _WeekChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Card(
      key: const ValueKey('weekChart'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ref
            .watch(analyticsProvider)
            .when(
              data: (analytics) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.last7Days(lang),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _WeekChart(days: analytics.last7Days, lang: lang),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(S.analyticsFailed(lang)),
              ),
            ),
      ),
    );
  }
}

/// Столбцы по дням: высота пропорциональна числу ответов, под ними день недели.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days, required this.lang});

  final List<DailyStats> days;
  final AppLanguage lang;

  double _heightFor(DailyStats day, int maxAnswers) {
    if (maxAnswers == 0) {
      return _minBarHeight;
    }
    return _minBarHeight +
        (_chartHeight - _minBarHeight) * day.totalAnswers / maxAnswers;
  }

  String _labelFor(DailyStats day) {
    final date = DateTime.utc(1970)
        .add(Duration(days: day.date.daysSinceEpoch));
    return S.weekday(date.weekday, lang);
  }

  @override
  Widget build(BuildContext context) {
    var maxAnswers = 0;
    for (final day in days) {
      if (day.totalAnswers > maxAnswers) {
        maxAnswers = day.totalAnswers;
      }
    }
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      height: _chartHeight + 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (index, day) in days.indexed)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Bar(
                    key: ValueKey('bar-${day.date}'),
                    height: _heightFor(day, maxAnswers),
                    delayIndex: index,
                    isEmpty: day.totalAnswers == 0,
                  ),
                  const SizedBox(height: 4),
                  Text(_labelFor(day), style: labelStyle),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Один столбец: аккуратный цилиндр, растущий снизу вверх.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.delayIndex,
    required this.isEmpty,
    super.key,
  });

  final double height;
  final int delayIndex;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
          width: 12,
          height: height,
          decoration: BoxDecoration(
            // Пустой день виден, но не спорит с данными.
            color: isEmpty ? scheme.outlineVariant : scheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        )
        .animate(delay: (delayIndex * 40).ms)
        .scaleY(
          begin: 0,
          end: 1,
          alignment: Alignment.bottomCenter,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
