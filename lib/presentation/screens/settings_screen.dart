import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';
import 'package:english_edu/presentation/widgets/analytics_section.dart';
import 'package:english_edu/presentation/widgets/create_category_dialog.dart';
import 'package:english_edu/presentation/widgets/export_dialog.dart';
import 'package:english_edu/presentation/widgets/import_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Голоса, доступные в MVP.
const _voices = <String>['en-US', 'en-GB'];

/// Время напоминания как `HH:MM` (24-часовой формат).
String _formatTime(UserSettings settings) {
  final hour = settings.reminderHour.toString().padLeft(2, '0');
  final minute = settings.reminderMinute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Настройки: лимиты, звук, напоминания, данные (Phase 20).
class SettingsScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<UserSettings> _settings;

  @override
  void initState() {
    super.initState();
    _settings = ref.read(settingsRepositoryProvider).get();
  }

  /// Сохраняет настройки и перечитывает их из репозитория.
  ///
  /// `dailyGoalProvider` держит план дня, посчитанный из лимитов: после
  /// сохранения его кэш устарел, иначе главный экран показывал бы старый план.
  Future<void> _save(UserSettings settings) async {
    try {
      await ref.read(settingsRepositoryProvider).save(settings);
      ref.invalidate(dailyGoalProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = ref.read(settingsRepositoryProvider).get();
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Settings save failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить настройки')),
        );
      }
    }
  }

  Future<void> _testSpeak(UserSettings settings) async {
    try {
      await ref
          .read(ttsProvider)
          .speak(
            'Hello world',
            voice: settings.ttsVoice,
            speed: settings.ttsSpeed,
          );
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('TTS failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Озвучка недоступна')));
      }
    }
  }

  /// Обновляет всё, что зависит от прогресса: после сброса и импорта.
  void _invalidateDerived() {
    ref
      ..invalidate(computeStreakProvider)
      ..invalidate(getTodayQueueProvider)
      ..invalidate(dailyGoalProvider)
      ..invalidate(dictionaryEntriesProvider);
  }

  /// Меняет уровень пользователя (ADR-023).
  ///
  /// Очередь дня зависит от уровня (`newWords` не выше preferredLevel),
  /// поэтому её кэш сбрасывается вместе с целью дня.
  Future<void> _pickLevel(UserSettings settings) async {
    final level = await showDialog<CefrLevel>(
      context: context,
      builder: (context) => _LevelDialog(current: settings.preferredLevel),
    );
    if (level == null || level == settings.preferredLevel) {
      return;
    }
    await _save(settings.copyWith(preferredLevel: level));
    ref
      ..invalidate(getTodayQueueProvider)
      ..invalidate(dailyGoalProvider);
  }

  /// Включает/выключает ежедневное напоминание (ADR-017).
  ///
  /// Побочный эффект выполняется до сохранения: если ОС отказала в разрешении
  /// или планирование упало, настройка не должна выглядеть включённой.
  Future<void> _toggleReminders(UserSettings settings, bool enabled) async {
    try {
      final notifications = ref.read(notificationServiceProvider);
      if (enabled) {
        await notifications.requestPermission();
        await notifications.scheduleDailyReminder(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        );
      } else {
        await notifications.cancelAll();
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Reminder update failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось обновить напоминание')),
        );
      }
      return;
    }
    await _save(settings.copyWith(remindersEnabled: enabled));
  }

  /// Выбирает время напоминания; при включённых напоминаниях перепланирует.
  ///
  /// Ввод с клавиатуры, а не циферблат: время задаётся точно (9:05), и это
  /// поведение детерминированно проверяется в тестах.
  Future<void> _pickReminderTime(UserSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked == null || !mounted) {
      return;
    }
    if (settings.remindersEnabled) {
      try {
        await ref
            .read(notificationServiceProvider)
            .scheduleDailyReminder(hour: picked.hour, minute: picked.minute);
      } on Object catch (error, stack) {
        ref
            .read(loggerProvider)
            .error('Reminder reschedule failed', error, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось обновить напоминание')),
          );
        }
        return;
      }
    }
    await _save(
      settings.copyWith(
        reminderHour: picked.hour,
        reminderMinute: picked.minute,
      ),
    );
  }

  Future<void> _export() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  Future<void> _import() async {
    final imported = await showDialog<bool>(
      context: context,
      builder: (context) => const ImportDialog(),
    );
    if (imported ?? false) {
      _invalidateDerived();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Данные импортированы')));
      }
    }
  }

  /// Сбрасывает прогресс (ADR-013): словарь и настройки остаются.
  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить прогресс?'),
        content: const Text(
          'Словарь останется, прогресс, логи и статистика будут удалены. '
          'Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(resetProgressProvider).call();
      _invalidateDerived();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Прогресс сброшен')));
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Reset progress failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сбросить прогресс')),
        );
      }
    }
  }

  /// Открывает диалог создания категории (ADR-034).
  ///
  /// После создания список фильтров словаря перечитывается, иначе новая
  /// категория не появилась бы до перезапуска.
  Future<void> _createCategory() async {
    final created = await showDialog<UserCategory>(
      context: context,
      builder: (context) => const CreateCategoryDialog(),
    );
    if (created == null || !mounted) {
      return;
    }
    ref.invalidate(userCategoriesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Категория «${created.name}» создана')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Настройки'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Назад',
        onPressed: () => context.pop(),
      ),
    ),
    body: FutureBuilder<UserSettings>(
      future: _settings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Не удалось загрузить настройки'));
        }
        final settings = snapshot.data ?? UserSettings.defaults();
        return ListView(
          children: [
            const _SectionHeader('Уровень английского', icon: Icons.school),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(settings.preferredLevel.label),
              subtitle: Text(settings.preferredLevel.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => unawaited(_pickLevel(settings)),
            ),
            const Divider(),
            const _SectionHeader('Дневные лимиты', icon: Icons.tune),
            ListTile(
              title: const Text('Новых слов в день'),
              subtitle: Slider(
                max: 50,
                divisions: 10,
                value: settings.dailyNewLimit.clamp(0, 50).toDouble(),
                label: '${settings.dailyNewLimit}',
                onChanged: (value) => setState(() {
                  _settings = Future.value(
                    settings.copyWith(dailyNewLimit: value.round()),
                  );
                }),
                onChangeEnd: (value) =>
                    _save(settings.copyWith(dailyNewLimit: value.round())),
              ),
            ),
            ListTile(
              title: const Text('Повторений в день'),
              subtitle: Slider(
                max: 200,
                divisions: 20,
                value: settings.dailyReviewLimit.clamp(0, 200).toDouble(),
                label: '${settings.dailyReviewLimit}',
                onChanged: (value) => setState(() {
                  _settings = Future.value(
                    settings.copyWith(dailyReviewLimit: value.round()),
                  );
                }),
                onChangeEnd: (value) =>
                    _save(settings.copyWith(dailyReviewLimit: value.round())),
              ),
            ),
            const Divider(),
            const _SectionHeader('Озвучка', icon: Icons.volume_up),
            ListTile(
              title: const Text('Голос'),
              trailing: DropdownButton<String>(
                value: _voices.contains(settings.ttsVoice)
                    ? settings.ttsVoice
                    : _voices.first,
                items: [
                  for (final voice in _voices)
                    DropdownMenuItem(value: voice, child: Text(voice)),
                ],
                onChanged: (voice) {
                  if (voice != null) {
                    unawaited(_save(settings.copyWith(ttsVoice: voice)));
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Скорость речи'),
              subtitle: Slider(
                min: 0.1,
                divisions: 18,
                value: settings.ttsSpeed.clamp(0.1, 1),
                label: settings.ttsSpeed.toStringAsFixed(2),
                onChanged: (value) => setState(() {
                  _settings = Future.value(settings.copyWith(ttsSpeed: value));
                }),
                onChangeEnd: (value) =>
                    _save(settings.copyWith(ttsSpeed: value)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Проверить'),
              onTap: () => unawaited(_testSpeak(settings)),
            ),
            const Divider(),
            const _SectionHeader('Резервная копия', icon: Icons.backup),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Достижения'),
              subtitle: const Text('Серии, слова, идеальные ответы'),
              onTap: () => context.push('/achievements'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Управление категориями'),
              subtitle: const Text('Создать свою категорию'),
              onTap: () => unawaited(_createCategory()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Экспорт'),
              subtitle: const Text('JSON в буфер обмена'),
              onTap: () => unawaited(_export()),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Импорт'),
              subtitle: const Text('Вставить JSON из буфера'),
              onTap: () => unawaited(_import()),
            ),
            const Divider(),
            const _SectionHeader('Синхронизация', icon: Icons.cloud_sync),
            const _CloudSyncSection(),
            const Divider(),
            const _SectionHeader('Опасная зона', icon: Icons.warning_amber),
            ListTile(
              leading: Icon(
                Icons.restart_alt,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Сбросить прогресс',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('Словарь и настройки останутся'),
              onTap: () => unawaited(_reset()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Как это работает'),
              subtitle: const Text('Короткий онбординг'),
              onTap: () => context.push('/onboarding?manual=1'),
            ),
            const Divider(),
            const _SectionHeader('Аналитика', icon: Icons.analytics),
            const AnalyticsSection(),
            const Divider(),
            const _SectionHeader('Напоминания', icon: Icons.notifications),
            SwitchListTile(
              title: const Text('Включить напоминания'),
              subtitle: Text(
                settings.remindersEnabled
                    ? 'Ежедневно в ${_formatTime(settings)}'
                    : 'Выключены',
              ),
              value: settings.remindersEnabled,
              onChanged: (value) =>
                  unawaited(_toggleReminders(settings, value)),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Время напоминания'),
              subtitle: Text(_formatTime(settings)),
              onTap: () => unawaited(_pickReminderTime(settings)),
            ),
          ],
        );
      },
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}

/// Вход в облако и ручная синхронизация прогресса (ADR-022).
///
/// Секция живёт в профиле целиком: настройка нужна редко, а отдельный экран
/// ради двух кнопок усложнил бы навигацию.
class _CloudSyncSection extends ConsumerStatefulWidget {
  const _CloudSyncSection();

  @override
  ConsumerState<_CloudSyncSection> createState() => _CloudSyncSectionState();
}

class _CloudSyncSectionState extends ConsumerState<_CloudSyncSection> {
  bool _busy = false;

  /// Спрашивает email и отправляет magic link.
  Future<void> _signIn() async {
    final email = await showDialog<String>(
      context: context,
      builder: (context) => const _EmailDialog(),
    );
    if (email == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cloudAuthServiceProvider).signInWithMagicLink(email);
      if (mounted) {
        _showMessage('Ссылка отправлена на $email');
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Magic link failed', error, stack);
      if (mounted) {
        _showMessage('Не удалось отправить ссылку');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Тянет и отправляет прогресс, затем обновляет зависимые экраны.
  Future<void> _sync() async {
    setState(() => _busy = true);
    try {
      final report = await ref.read(cloudSyncServiceProvider).sync();
      ref
        ..invalidate(computeStreakProvider)
        ..invalidate(getTodayQueueProvider)
        ..invalidate(dailyGoalProvider)
        ..invalidate(dictionaryEntriesProvider);
      if (mounted) {
        _showMessage('Отправлено ${report.pushed}, получено ${report.pulled}');
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Cloud sync failed', error, stack);
      if (mounted) {
        _showMessage('Не удалось синхронизироваться');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(cloudAuthServiceProvider).signOut();
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Sign out failed', error, stack);
    }
  }

  void _showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(cloudAuthServiceProvider).isAvailable;
    final email = ref.watch(cloudEmailProvider).value;

    if (!available) {
      return const ListTile(
        leading: Icon(Icons.cloud_off),
        title: Text('Синхронизация недоступна'),
        subtitle: Text('Ключи Supabase не переданы при сборке'),
      );
    }
    if (email == null) {
      return ListTile(
        leading: const Icon(Icons.login),
        title: const Text('Войти через Email'),
        subtitle: const Text('Пришлём ссылку для входа'),
        enabled: !_busy,
        onTap: () => unawaited(_signIn()),
      );
    }
    return ListTile(
      leading: const Icon(Icons.cloud_sync),
      title: const Text('Синхронизировать сейчас'),
      subtitle: Text(email),
      enabled: !_busy,
      onTap: () => unawaited(_sync()),
      trailing: IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Выйти',
        onPressed: _busy ? null : () => unawaited(_signOut()),
      ),
    );
  }
}

/// Диалог ввода email для magic link.
///
/// Возвращает введённый адрес или null при отмене; формат проверяется здесь,
/// чтобы письмо не уходило на заведомо неверный адрес.
class _EmailDialog extends StatefulWidget {
  const _EmailDialog();

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (!value.contains('@')) {
      setState(() => _error = 'Проверьте адрес');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Вход по email'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(labelText: 'Email', errorText: _error),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Отправить')),
    ],
  );
}

/// Диалог выбора уровня CEFR (ADR-023).
///
/// Возвращает выбранный уровень или null при отмене: вызывающий сохраняет
/// настройку только по явному выбору.
class _LevelDialog extends StatefulWidget {
  const _LevelDialog({required this.current});

  final CefrLevel current;

  @override
  State<_LevelDialog> createState() => _LevelDialogState();
}

class _LevelDialogState extends State<_LevelDialog> {
  late CefrLevel _selected = widget.current;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Уровень английского'),
    content: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final level in CefrLevel.values)
          ChoiceChip(
            label: Text(level.label),
            tooltip: level.description,
            selected: _selected == level,
            onSelected: (_) => setState(() => _selected = level),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_selected),
        child: const Text('Сохранить'),
      ),
    ],
  );
}
