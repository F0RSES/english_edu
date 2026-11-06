import 'package:english_edu/domain/repositories/user_category_repository.dart';
import 'package:english_edu/domain/usecases/create_user_category.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';
import 'package:test/test.dart';

/// In-memory репозиторий категорий: use case проверяется без БД.
final class FakeUserCategoryRepository implements UserCategoryRepository {
  FakeUserCategoryRepository([Iterable<UserCategory> seed = const []])
    : _items = {for (final item in seed) item.id: item};

  final Map<int, UserCategory> _items;
  var _nextId = 1;

  @override
  Future<List<UserCategory>> getAll() async => _items.values.toList();

  @override
  Future<UserCategory?> findByName(String name) async {
    final needle = name.trim().toLowerCase();
    for (final item in _items.values) {
      if (item.name.trim().toLowerCase() == needle) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<UserCategory> create(String name, {String? colorHex}) async {
    final created = UserCategory(
      id: _nextId++,
      name: name,
      colorHex: colorHex,
      createdAtUtc: DateTime.utc(2024, 5, 15, 12),
    );
    _items[created.id] = created;
    return created;
  }

  @override
  Future<void> delete(int id) async => _items.remove(id);
}

UserCategory category(int id, String name) => UserCategory(
  id: id,
  name: name,
  createdAtUtc: DateTime.utc(2024, 5, 15, 12),
);

void main() {
  test('should_create_a_new_category', () async {
    final repo = FakeUserCategoryRepository();
    final useCase = CreateUserCategory(repo: repo);

    final created = await useCase('Спорт', colorHex: '#4CAF50');

    expect(created.name, 'Спорт');
    expect(created.colorHex, '#4CAF50');
    expect(await repo.getAll(), hasLength(1));
  });

  test('should_reject_an_empty_name', () async {
    final useCase = CreateUserCategory(repo: FakeUserCategoryRepository());

    expect(() => useCase('   '), throwsArgumentError);
  });

  test('should_reject_a_duplicate_case_insensitively', () async {
    final useCase = CreateUserCategory(
      repo: FakeUserCategoryRepository([category(1, 'Бизнес')]),
    );

    expect(() => useCase('бизнес'), throwsStateError);
  });

  test('should_trim_whitespace_before_saving', () async {
    final repo = FakeUserCategoryRepository();
    final useCase = CreateUserCategory(repo: repo);

    final created = await useCase('  Спорт  ');

    expect(created.name, 'Спорт');
  });
}
