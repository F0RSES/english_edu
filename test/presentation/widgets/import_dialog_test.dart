import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/export_payload_codec.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/usecases/import_progress.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/import_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fakes/fake_crash_reporter.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_review_log_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_stats_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

ExportPayload payload({int schemaVersion = 1}) => ExportPayload(
  schemaVersion: schemaVersion,
  exportedAt: now,
  settings: UserSettings.defaults(),
  words: const [Word(id: WordId(1), term: 'hello', translation: 'привет')],
  progress: const [],
  logs: const [],
  stats: const [],
);

/// Бросает при сохранении настроек: проверяет обработку сбоя импорта.
final class _ThrowingSettings implements SettingsRepository {
  @override
  Future<UserSettings> get() async => UserSettings.defaults();

  @override
  Future<void> save(UserSettings settings) async => throw StateError('boom');
}

final class Harness {
  Harness({SettingsRepository? settings})
    : words = FakeWordRepository([word(9)]),
      settings = settings ?? FakeSettingsRepository();

  final FakeWordRepository words;
  final FakeProgressRepository progress = FakeProgressRepository();
  final FakeReviewLogRepository logs = FakeReviewLogRepository();
  final FakeStatsRepository stats = FakeStatsRepository();
  final SettingsRepository settings;

  final FakeCrashReporter crashReporter = FakeCrashReporter();

  Widget app() => ProviderScope(
    overrides: [
      importProgressProvider.overrideWithValue(
        ImportProgress(
          words: words,
          progress: progress,
          reviewLog: logs,
          settings: settings,
          stats: stats,
        ),
      ),
      crashReporterProvider.overrideWithValue(crashReporter),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (context) => const ImportDialog(),
            ),
            child: const Text('открыть'),
          ),
        ),
      ),
    ),
  );
}

Word word(int id) =>
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id');

Future<void> _open(WidgetTester tester, Harness harness) async {
  await tester.pumpWidget(harness.app());
  await tester.pumpAndSettle();
  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();
}

Future<void> _paste(WidgetTester tester, String json) async {
  await tester.enterText(find.byType(TextField), json);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Импортировать'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('invalid JSON shows an error', (tester) async {
    final harness = Harness();
    await _open(tester, harness);

    await _paste(tester, 'не json');

    expect(find.textContaining('Невалидный JSON'), findsOneWidget);
    expect(await harness.words.getAll(), hasLength(1));
  });

  testWidgets('unsupported schema version shows an error', (tester) async {
    final harness = Harness();
    await _open(tester, harness);

    await _paste(
      tester,
      const ExportPayloadCodec().encode(payload(schemaVersion: 2)),
    );

    expect(
      find.textContaining('Неподдерживаемая версия схемы'),
      findsOneWidget,
    );
  });

  testWidgets('valid JSON asks for confirmation', (tester) async {
    final harness = Harness();
    await _open(tester, harness);

    await _paste(tester, const ExportPayloadCodec().encode(payload()));

    expect(find.text('Все данные будут заменены. Продолжить?'), findsOneWidget);
  });

  testWidgets('confirm replaces the stored data', (tester) async {
    final harness = Harness();
    await _open(tester, harness);

    await _paste(tester, const ExportPayloadCodec().encode(payload()));
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('Импорт'), findsNothing);
    expect(await harness.words.getById(const WordId(1)), isNotNull);
    expect(await harness.words.getById(const WordId(9)), isNull);
  });

  testWidgets('cancel keeps the stored data', (tester) async {
    final harness = Harness();
    await _open(tester, harness);

    await _paste(tester, const ExportPayloadCodec().encode(payload()));
    // «Отмена» есть и в диалоге импорта, и в подтверждении: берём верхнюю.
    await tester.tap(find.text('Отмена').last);
    await tester.pumpAndSettle();

    expect(find.text('Импорт'), findsOneWidget);
    expect(await harness.words.getById(const WordId(9)), isNotNull);
    expect(await harness.words.getById(const WordId(1)), isNull);
  });

  testWidgets('a failed import calls the crash reporter', (tester) async {
    final harness = Harness(settings: _ThrowingSettings());
    await _open(tester, harness);

    await _paste(tester, const ExportPayloadCodec().encode(payload()));
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(harness.crashReporter.captured, hasLength(1));
    expect(harness.crashReporter.captured.single.context, 'import');
    expect(find.text('Не удалось импортировать данные'), findsOneWidget);
  });
}
