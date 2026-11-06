import 'package:meta/meta.dart';

/// Состояние карточки в игре «Memory» (ADR-036).
///
/// Имя отличается от `CardState` (SM-2): там расписание повторений, здесь —
/// визуальное состояние карточки. Одноимённые типы в одном слое путали бы
/// импорты.
enum MemoryCardState {
  /// Закрыта: виден только «?».
  hidden,

  /// Открыта, но пара ещё не найдена.
  flipped,

  /// Пара найдена.
  matched,
}

/// Карточка памяти: английское слово или его перевод (ADR-036).
@immutable
final class MemoryCard {
  /// Создаёт карточку.
  const MemoryCard({
    required this.id,
    required this.pairId,
    required this.text,
    required this.isEnglish,
    this.state = MemoryCardState.hidden,
  });

  /// Уникальный идентификатор карточки в наборе.
  final int id;

  /// Пара: у английского слова и перевода одинаковый `pairId`.
  final int pairId;

  /// Текст на карточке.
  final String text;

  /// true — английская сторона пары (для цвета в UI).
  final bool isEnglish;

  /// Текущее состояние.
  final MemoryCardState state;

  /// Returns a copy with the given fields replaced.
  MemoryCard copyWith({MemoryCardState? state}) => MemoryCard(
    id: id,
    pairId: pairId,
    text: text,
    isEnglish: isEnglish,
    state: state ?? this.state,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryCard &&
          id == other.id &&
          pairId == other.pairId &&
          text == other.text &&
          isEnglish == other.isEnglish &&
          state == other.state;

  @override
  int get hashCode => Object.hash(id, pairId, text, isEnglish, state);

  @override
  String toString() => 'MemoryCard($id, pair $pairId, "$text", $state)';
}
