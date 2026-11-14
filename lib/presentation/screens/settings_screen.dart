import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
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
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    try {
      await ref.read(settingsRepositoryProvider).save(settings);
      ref
        ..invalidate(settingsProvider)
        ..invalidate(dailyGoalProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = ref.read(settingsRepositoryProvider).get();
      });
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Settings save failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.saveFailed(lang))));
      }
    }
  }

  Future<void> _testSpeak(UserSettings settings) async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
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
            .showSnackBar(SnackBar(content: Text(S.ttsFailed(lang))));
      }
    }
  }

  /// Обновляет всё, что зависит от прогресса: после сброса и импорта.
  void _invalidateDerived() {
    ref
      ..invalidate(settingsProvider)
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
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.reminderFailed(lang))));
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
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(S.reminderFailed(lang))));
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
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    final imported = await showDialog<bool>(
      context: context,
      builder: (context) => const ImportDialog(),
    );
    if (imported ?? false) {
      _invalidateDerived();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.importDone(lang))));
      }
    }
  }

  /// Сбрасывает прогресс (ADR-013): словарь и настройки остаются.
  Future<void> _reset() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.resetConfirmTitle(lang)),
        content: Text(S.resetConfirmBody(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.cancel(lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.resetConfirm(lang)),
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
            .showSnackBar(SnackBar(content: Text(S.resetDone(lang))));
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Reset progress failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.resetFailed(lang))));
      }
    }
  }

  /// Открывает диалог создания категории (ADR-034).
  ///
  /// После создания список фильтров словаря перечитывается, иначе новая
  /// категория не появилась бы до перезапуска.
  Future<void> _createCategory() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    final created = await showDialog<UserCategory>(
      context: context,
      builder: (context) => const CreateCategoryDialog(),
    );
    if (created == null || !mounted) {
      return;
    }
    ref.invalidate(userCategoriesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.categoryCreated(created.name, lang))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.settings(lang)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: S.back(lang),
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
            return Center(child: Text(S.settingsLoadFailed(lang)));
          }
          final settings = snapshot.data ?? UserSettings.defaults();
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _SectionHeader(S.dailyLimits(lang), icon: Icons.tune),
              _SettingsCard(
                children: [
                  ListTile(
                    title: Text(S.newPerDay(lang)),
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
                      onChangeEnd: (value) => _save(
                        settings.copyWith(dailyNewLimit: value.round()),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(S.reviewsPerDay(lang)),
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
                      onChangeEnd: (value) => _save(
                        settings.copyWith(dailyReviewLimit: value.round()),
                      ),
                    ),
                  ),
                ],
              ),
              _SectionHeader(S.ttsSection(lang), icon: Icons.volume_up),
              _SettingsCard(
                children: [
                  ListTile(
                    title: Text(S.voice(lang)),
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
                    title: Text(S.speechRate(lang)),
                    subtitle: Slider(
                      min: 0.1,
                      divisions: 18,
                      value: settings.ttsSpeed.clamp(0.1, 1),
                      label: settings.ttsSpeed.toStringAsFixed(2),
                      onChanged: (value) => setState(() {
                        _settings = Future.value(
                          settings.copyWith(ttsSpeed: value),
                        );
                      }),
                      onChangeEnd: (value) =>
                          _save(settings.copyWith(ttsSpeed: value)),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: Text(S.check(lang)),
                    onTap: () => unawaited(_testSpeak(settings)),
                  ),
                ],
              ),
              _SectionHeader(S.backupSection(lang), icon: Icons.backup),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(S.achievementsTile(lang)),
                    subtitle: Text(S.achievementsSubtitle(lang)),
                    onTap: () => context.push('/achievements'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(S.categoriesTile(lang)),
                    subtitle: Text(S.categoriesSubtitle(lang)),
                    onTap: () => unawaited(_createCategory()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload),
                    title: Text(S.exportTile(lang)),
                    subtitle: Text(S.exportSubtitle(lang)),
                    onTap: () => unawaited(_export()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: Text(S.importTile(lang)),
                    subtitle: Text(S.importSubtitle(lang)),
                    onTap: () => unawaited(_import()),
                  ),
                ],
              ),
              _SectionHeader(S.cloudSection(lang), icon: Icons.cloud_sync),
              const _SettingsCard(children: [_CloudSyncSection()]),
              _SectionHeader(S.dangerZone(lang), icon: Icons.warning_amber),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.restart_alt,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      S.resetTile(lang),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: Text(S.resetSubtitle(lang)),
                    onTap: () => unawaited(_reset()),
                  ),
                ],
              ),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(S.howItWorks(lang)),
                    subtitle: Text(S.onboardingTile(lang)),
                    onTap: () => context.push('/onboarding?manual=1'),
                  ),
                ],
              ),
              _SectionHeader(S.analyticsSection(lang), icon: Icons.analytics),
              const _SettingsCard(children: [AnalyticsSection()]),
              _SectionHeader(
                S.remindersSection(lang),
                icon: Icons.notifications,
              ),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: Text(S.remindersToggle(lang)),
                    subtitle: Text(
                      settings.remindersEnabled
                          ? S.remindersDaily(_formatTime(settings), lang)
                          : S.remindersOff(lang),
                    ),
                    value: settings.remindersEnabled,
                    onChanged: (value) =>
                        unawaited(_toggleReminders(settings, value)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(S.reminderTime(lang)),
                    subtitle: Text(_formatTime(settings)),
                    onTap: () => unawaited(_pickReminderTime(settings)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Карточка секции настроек: фон и скругление вместо голого списка
/// (Phase 27c). Логика тайлов не меняется — только визуальная группировка.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    clipBehavior: Clip.antiAlias,
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
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
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    final email = await showDialog<String>(
      context: context,
      builder: (context) => _EmailDialog(lang: lang),
    );
    if (email == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cloudAuthServiceProvider).signInWithMagicLink(email);
      if (mounted) {
        _showMessage(S.linkSent(email, lang));
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Magic link failed', error, stack);
      if (mounted) {
        _showMessage(S.linkFailed(lang));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Тянет и отправляет прогресс, затем обновляет зависимые экраны.
  Future<void> _sync() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _busy = true);
    try {
      final report = await ref.read(cloudSyncServiceProvider).sync();
      ref
        ..invalidate(computeStreakProvider)
        ..invalidate(getTodayQueueProvider)
        ..invalidate(dailyGoalProvider)
        ..invalidate(dictionaryEntriesProvider);
      if (mounted) {
        _showMessage(S.syncResult(report.pushed, report.pulled, lang));
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).warn('Cloud sync failed', error, stack);
      if (mounted) {
        _showMessage(S.syncFailed(lang));
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
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final available = ref.watch(cloudAuthServiceProvider).isAvailable;
    final email = ref.watch(cloudEmailProvider).value;

    if (!available) {
      return ListTile(
        leading: const Icon(Icons.cloud_off),
        title: Text(S.cloudUnavailable(lang)),
        subtitle: Text(S.cloudNoKeys(lang)),
      );
    }
    if (email == null) {
      return ListTile(
        leading: const Icon(Icons.login),
        title: Text(S.signIn(lang)),
        subtitle: Text(S.signInSubtitle(lang)),
        enabled: !_busy,
        onTap: () => unawaited(_signIn()),
      );
    }
    return ListTile(
      leading: const Icon(Icons.cloud_sync),
      title: Text(S.syncNow(lang)),
      subtitle: Text(email),
      enabled: !_busy,
      onTap: () => unawaited(_sync()),
      trailing: IconButton(
        icon: const Icon(Icons.logout),
        tooltip: S.signOut(lang),
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
  const _EmailDialog({required this.lang});

  final AppLanguage lang;

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
      setState(() => _error = S.emailCheck(widget.lang));
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(S.emailTitle(widget.lang)),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: S.emailLabel(widget.lang),
        errorText: _error,
      ),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(S.cancel(widget.lang)),
      ),
      FilledButton(onPressed: _submit, child: Text(S.emailSend(widget.lang))),
    ],
  );
}
