import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/repositories/user_category_repository.dart';
import 'package:english_edu/domain/usecases/create_user_category.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';
import 'package:english_edu/presentation/widgets/create_category_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

/// Минимальный репозиторий категорий для теста диалога.
final class _FakeRepo implements UserCategoryRepository {
  _FakeRepo([Iterable<UserCategory> seed = const []])
    : _items = {for (final item in seed) item.name.toLowerCase(): item};

  final Map<String, UserCategory> _items;

  @override
  Future<List<UserCategory>> getAll() => Future.value(_items.values.toList());

  @override
  Future<UserCategory?> findByName(String name) =>
      Future.value(_items[name.trim().toLowerCase()]);

  @override
  Future<UserCategory> create(String name, {String? colorHex}) async {
    final created = UserCategory(
      id: _items.length + 1,
      name: name,
      colorHex: colorHex,
      createdAtUtc: DateTime.utc(2024, 5, 15, 12),
    );
    _items[name.toLowerCase()] = created;
    return created;
  }

  @override
  Future<void> delete(int id) async {}
}

Widget host(UserCategoryRepository repo) => ProviderScope(
  overrides: [
    createUserCategoryProvider.overrideWithValue(
      CreateUserCategory(repo: repo),
    ),
    userCategoriesProvider.overrideWith((ref) => repo.getAll()),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<UserCategory>(
            context: context,
            builder: (_) => const CreateCategoryDialog(),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('creates a category with the typed name', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(host(repo));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Спорт');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    final created = await repo.getAll();
    expect(created, hasLength(1));
    expect(created.single.name, 'Спорт');
    expect(find.byType(CreateCategoryDialog), findsNothing);
  });

  testWidgets('shows an error for a duplicate name', (tester) async {
    final repo = _FakeRepo([
      UserCategory(
        id: 1,
        name: 'Бизнес',
        createdAtUtc: DateTime.utc(2024, 5, 15, 12),
      ),
    ]);
    await tester.pumpWidget(host(repo));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'бизнес');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать'));
    await tester.pump();

    expect(find.text('Категория уже существует'), findsOneWidget);
    expect(await repo.getAll(), hasLength(1));
  });
}
