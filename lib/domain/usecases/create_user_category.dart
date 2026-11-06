import 'package:english_edu/domain/repositories/user_category_repository.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';

/// Создаёт пользовательскую категорию (ADR-034).
///
/// Проверки живут здесь, а не в диалоге: дубль по имени ломает фильтр словаря,
/// и правило должно быть одинаковым для любого вызывающего.
final class CreateUserCategory {
  /// Создаёт use case.
  const CreateUserCategory({required UserCategoryRepository repo})
    : _repo = repo;

  final UserCategoryRepository _repo;

  /// Создаёт категорию с именем [name].
  ///
  /// Бросает [ArgumentError] на пустое имя и [StateError], если категория с
  /// таким именем уже есть (без учёта регистра).
  Future<UserCategory> call(String name, {String? colorHex}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name is empty');
    }

    final existing = await _repo.findByName(trimmed);
    if (existing != null) {
      throw StateError('Category "$trimmed" already exists');
    }

    return await _repo.create(trimmed, colorHex: colorHex);
  }
}
