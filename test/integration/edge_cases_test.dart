import 'package:drift/native.dart';
import 'package:english_edu/core/crash_reporter.dart';
import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/notifications/notification_service.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/export_payload_codec.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Крайние случаи на реальной БД: пустой словарь, одно слово и битые
/// резервные копии.
///
/// Импорт с дублями и снимок v3 уже покрыты `export_payload_codec_test` и
/// `import_dialog_test` (ADR-024, ADR-023), поэтому здесь только то, чего там
/// нет.

final now = DateTime.utc(2024, 5, 15, 12);
var _logId = 1;

domain.Word word(int id) => domain.Word(
  id: WordId(id),
  term: 'term$id',
  translation: 'перевод$id',
);

Widget app(AppDatabase db, {bool onboardingSeen = true}) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(() => now),
    nextReviewLogIdProvider.overrideWithValue(() => ReviewLogId(_logId++)),
    crashReporterProvider.overrideWithValue(const NoOpCrashReporter()),
    notificationServiceProvider.overrideWithValue(
      const NoOpNotificationService(),
    ),
    onboardingSeenProvider.overrideWith(
      () => OnboardingSeen(seeded: onboardingSeen),
    ),
  ],
  child: const EnglishEduApp(),
);

void main() {
  testWidgets('empty dictionary shows the finished state', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();

    expect(find.text('Все слова изучены'), findsOneWidget);
  });

  testWidgets('single word gives a lesson of one card', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await DriftWordRepository(db).insertMany([word(1)]);

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Начать урок (1 слово)'));
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
  });

  test('broken backup fails with a readable error', () {
    const codec = ExportPayloadCodec();
    FormatException? failure;
    try {
      codec.decode('{oops');
    } on FormatException catch (error) {
      failure = error;
    }

    expect(failure?.message, contains('Некорректный JSON'));
  });

  test('backup from the future is rejected', () {
    const codec = ExportPayloadCodec();
    FormatException? failure;
    try {
      codec.decode('{"schemaVersion": 99}');
    } on FormatException catch (error) {
      failure = error;
    }

    expect(failure?.message, contains('неподдерживаемая версия'));
  });

}
