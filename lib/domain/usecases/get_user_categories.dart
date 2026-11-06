import 'package:english_edu/domain/repositories/user_category_repository.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';

/// Отдаёт список категорий для фильтра и диалогов (ADR-034).
final class GetUserCategories {
  /// Создаёт use case.
  const GetUserCategories({required UserCategoryRepository repo})
    : _repo = repo;

  final UserCategoryRepository _repo;

  /// Все категории, базовые и пользовательские.
  Future<List<UserCategory>> call() => _repo.getAll();
}
