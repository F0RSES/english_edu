import 'dart:io';

import 'package:english_edu/core/avatar/avatar_storage.dart';
import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/presentation/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

Widget host(UserSettings? settings, {AvatarStorage? storage}) => ProviderScope(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(settings),
    ),
    if (storage != null) avatarStorageProvider.overrideWithValue(storage),
  ],
  child: const MaterialApp(home: Scaffold(body: UserAvatar(size: 32))),
);

void main() {
  testWidgets('should_show_two_initials_when_nickname_has_two_words', (
    tester,
  ) async {
    await tester.pumpWidget(host(const UserSettings(nickname: 'Norman Smith')));
    await tester.pumpAndSettle();

    expect(find.text('NS'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets('should_show_single_initial_when_nickname_has_one_word', (
    tester,
  ) async {
    await tester.pumpWidget(host(const UserSettings(nickname: 'norman')));
    await tester.pumpAndSettle();

    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('should_take_first_two_words_when_nickname_has_many_words', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const UserSettings(nickname: 'anna maria smith')),
    );
    await tester.pumpAndSettle();

    expect(find.text('AM'), findsOneWidget);
  });

  testWidgets('should_show_person_icon_when_nickname_absent', (tester) async {
    await tester.pumpWidget(host(null));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('should_show_person_icon_when_nickname_blank', (tester) async {
    await tester.pumpWidget(host(const UserSettings(nickname: '   ')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('should_fallback_to_initials_when_avatar_file_missing', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('user_avatar_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final storage = AvatarStorage(documentsDirectory: () async => dir);

    await tester.pumpWidget(
      host(
        UserSettings(
          nickname: 'Norman Smith',
          avatarPath: '${dir.path}/missing.jpg',
        ),
        storage: storage,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NS'), findsOneWidget);
  });
}
