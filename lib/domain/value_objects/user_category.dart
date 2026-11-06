import 'package:meta/meta.dart';

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

/// Категория слова — базовая или созданная пользователем (ADR-034).
///
/// Не `const`: `createdAtUtc` проверяется на UTC в runtime, потому что `assert`
/// вырезается в release (как у `WordProgress` и `DailyChallenge`).
@immutable
final class UserCategory {
  /// Создаёт категорию; [createdAtUtc] должен быть в UTC.
  UserCategory({
    required this.id,
    required this.name,
    required DateTime createdAtUtc,
    this.colorHex,
  }) : createdAtUtc = _requireUtc(createdAtUtc, 'createdAtUtc'),
       assert(name.isNotEmpty, 'name must not be empty');

  /// Идентификатор в БД; у базовых категорий — 1..4.
  final int id;

  /// Название, как его видит пользователь.
  final String name;

  /// Цвет для чипа (`#FF5722`); null — цвет темы по умолчанию.
  final String? colorHex;

  /// Момент создания, UTC.
  final DateTime createdAtUtc;

  /// Базовая категория из миграции: её нельзя удалить.
  bool get isBuiltIn => id <= builtInCategoryCount;

  /// Returns a copy with the given fields replaced.
  UserCategory copyWith({
    int? id,
    String? name,
    Object? colorHex = _unset,
    DateTime? createdAtUtc,
  }) => UserCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: identical(colorHex, _unset)
        ? this.colorHex
        : colorHex as String?,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCategory &&
          id == other.id &&
          name == other.name &&
          colorHex == other.colorHex &&
          createdAtUtc == other.createdAtUtc;

  @override
  int get hashCode => Object.hash(id, name, colorHex, createdAtUtc);

  @override
  String toString() => 'UserCategory($id, "$name", $colorHex)';
}

/// Сколько базовых категорий вставляет миграция v10.
const int builtInCategoryCount = 4;

/// Marker telling "absent" apart from an explicit null in a copy.
const _unset = _Unset();

final class _Unset {
  const _Unset();
}
