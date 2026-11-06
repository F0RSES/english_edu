import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/presentation/widgets/analytics_section.dart';
import 'package:english_edu/presentation/widgets/export_dialog.dart';
import 'package:english_edu/presentation/widgets/import_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Голоса, доступные в MVP.
const _voices = <String>['en-US', 'en-GB'];

/// Время напоминания как `HH:MM` (24-часовой формат).
String _formatTime(UserSettings settings) {
  final hour = settings.reminderHour.toString().padLeft(2, '0');
  final minute = settings.reminderMinute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Профиль: настройки озвучки, напоминания, резервная копия.
class ProfileScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Профиль')),
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
            const _SectionHeader('Дневные лимиты'),
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
            const _SectionHeader('Озвучка'),
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
            const _SectionHeader('Резервная копия'),
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
            const _SectionHeader('Опасная зона'),
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
            const _SectionHeader('Аналитика'),
            const AnalyticsSection(),
            const Divider(),
            const _SectionHeader('Напоминания'),
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
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}
