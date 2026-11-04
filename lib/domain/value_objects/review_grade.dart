/// SM-2 answer quality reported by the learner.
///
/// The integer [quality] is the SM-2 score used by the scheduling algorithm.
enum ReviewGrade {
  /// Answer failed; the card comes back in the same session.
  again(0),

  /// Recalled with serious difficulty.
  hard(3),

  /// Recalled with some effort.
  good(4),

  /// Recalled instantly.
  easy(5);

  const ReviewGrade(this.quality);

  /// SM-2 quality score in the 0..5 range.
  final int quality;

  /// Whether this grade counts as a failed recall.
  bool get isFailure => quality < 3;
}
