import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/export_progress.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_frozen_days_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_review_log_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_stats_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Widget app() => ProviderScope(
  overrides: [
    exportProgressProvider.overrideWithValue(
      ExportProgress(
        settings: FakeSettingsRepository(),
        progress: FakeProgressRepository(),
        reviewLog: FakeReviewLogRepository(),
        stats: FakeStatsRepository(),
        words: FakeWordRepository([
          const Word(id: WordId(1), term: 'hello', translation: 'привет'),
        ]),
        frozen: FakeFrozenDaysRepository(),
        clock: () => now,
      ),
    ),
  ],
  child: const MaterialApp(home: Scaffold(body: ExportDialog())),
);

void main() {
  testWidgets('shows the JSON snapshot of the current state', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final json = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .data;

    expect(json, isNotNull);
    expect(json, contains('"schemaVersion":5'));
    expect(json, contains('"term":"hello"'));
  });

  testWidgets('copy button writes the JSON to the clipboard', (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            calls.add(call);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Скопировать'));
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect((calls.single.arguments as Map)['text'], contains('schemaVersion'));
  });
}
