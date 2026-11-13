import 'package:english_edu/domain/entities/word.dart';
import 'package:meta/meta.dart';

/// Words selected for today's session.
///
/// Order-sensitive: [due] and [newWords] are compared element by element,
/// and [all] lists due words before new ones.
@immutable
final class TodayQueue {
  /// Creates a queue holding unmodifiable copies of both lists.
  ///
  /// Not `const`: the constructor takes a defensive copy of each argument.
  TodayQueue({required List<Word> due, required List<Word> newWords})
      : due = List.unmodifiable(due),
        newWords = List.unmodifiable(newWords);

  /// Words scheduled for review today, in session order.
  final List<Word> due;

  /// New words to introduce today, in session order.
  final List<Word> newWords;

  /// All words of the queue: due first, then new ones.
  ///
  /// Returns a fresh unmodifiable list on every call.
  List<Word> get all => List.unmodifiable([...due, ...newWords]);

  /// Total number of words: due plus new.
  int get length => due.length + newWords.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodayQueue &&
          _sameWords(due, other.due) &&
          _sameWords(newWords, other.newWords);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(due), Object.hashAll(newWords));

  @override
  String toString() => 'TodayQueue(due: ${due.length}, '
      'new: ${newWords.length})';
}

bool _sameWords(List<Word> left, List<Word> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
