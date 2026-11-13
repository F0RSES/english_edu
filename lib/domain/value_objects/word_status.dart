/// Learning status of a word in the user's collection.
///
/// Serialisation of these values belongs to the data layer.
enum WordStatus {
  /// Added to the collection, but never answered yet.
  newWord,

  /// Has at least one successful answer; the mastery threshold belongs to SRS.
  learning,

  /// Considered learned.
  mastered,
}
