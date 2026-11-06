import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:meta/meta.dart';

/// Строка прогресса в облаке (`user_progress`, ADR-022).
///
/// Хранит те же поля, что локальный `WordProgress`, плюс штамп изменения:
/// по нему разрешаются конфликты между устройствами.
@immutable
final class RemoteProgressRow {
  /// Создаёт строку; обе метки времени должны быть в UTC.
  RemoteProgressRow({
    required this.wordId,
    required this.cardState,
    required this.status,
    required DateTime firstSeenAtUtc,
    required DateTime? lastReviewedAtUtc,
  }) : firstSeenAtUtc = _requireUtc(firstSeenAtUtc, 'firstSeenAtUtc'),
       lastReviewedAtUtc = _requireUtcOrNull(
         lastReviewedAtUtc,
         'lastReviewedAtUtc',
       );

  /// Собирает строку из локального прогресса.
  factory RemoteProgressRow.fromDomain(WordProgress progress) =>
      RemoteProgressRow(
        wordId: progress.wordId,
        cardState: progress.cardState,
        status: progress.status,
        firstSeenAtUtc: progress.firstSeenAt,
        lastReviewedAtUtc: progress.lastReviewedAt,
      );

  /// Разбирает строку ответа Supabase.
  ///
  /// Бросает [FormatException] на расхождении схемы: вызывающий
  /// (`SupabaseRemoteProgressStore`) превращает её в `CloudSyncException`.
  factory RemoteProgressRow.fromJson(Map<String, Object?> json) {
    final statusName = json['status'];
    if (statusName is! String) {
      throw const FormatException('status: ожидалась строка');
    }
    final status = WordStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => throw FormatException('status: неизвестное $statusName'),
    );
    final lastReviewed = json['last_reviewed_at_utc'];
    return RemoteProgressRow(
      wordId: WordId(_requiredInt(json, 'word_id')),
      cardState: CardState(
        easePermille: _requiredInt(json, 'ease_permille'),
        intervalDays: _requiredInt(json, 'interval_days'),
        repetitions: _requiredInt(json, 'repetitions'),
        lapses: _requiredInt(json, 'lapses'),
        dueAt: _dateFromMs(_requiredInt(json, 'due_at_utc')),
      ),
      status: status,
      firstSeenAtUtc: _dateFromMs(_requiredInt(json, 'first_seen_at_utc')),
      lastReviewedAtUtc: lastReviewed == null
          ? null
          : _dateFromMs(_requiredInt(json, 'last_reviewed_at_utc')),
    );
  }

  /// Слово, к которому относится прогресс.
  final WordId wordId;

  /// Расписание SM-2.
  final CardState cardState;

  /// Статус изучения.
  final WordStatus status;

  /// Первый показ, UTC.
  final DateTime firstSeenAtUtc;

  /// Последний ответ, UTC; null — ещё не отвечали.
  final DateTime? lastReviewedAtUtc;

  /// Штамп изменения строки — по нему разрешаются конфликты.
  ///
  /// Прогресс меняется только ответом на карточку, а ответ обновляет
  /// `lastReviewedAt`; для новой карточки штамп — момент первого показа.
  DateTime get updatedAtUtc => lastReviewedAtUtc ?? firstSeenAtUtc;

  /// Локальная сущность.
  WordProgress toDomain() => WordProgress(
    wordId: wordId,
    cardState: cardState,
    status: status,
    firstSeenAt: firstSeenAtUtc,
    lastReviewedAt: lastReviewedAtUtc,
  );

  /// JSON для Supabase; [userId] подставляет клиент — RLS требует владельца.
  Map<String, Object?> toJson(String userId) => {
    'user_id': userId,
    'word_id': wordId.value,
    'ease_permille': cardState.easePermille,
    'interval_days': cardState.intervalDays,
    'repetitions': cardState.repetitions,
    'lapses': cardState.lapses,
    'due_at_utc': cardState.dueAt.millisecondsSinceEpoch,
    'status': status.name,
    'first_seen_at_utc': firstSeenAtUtc.millisecondsSinceEpoch,
    'last_reviewed_at_utc': lastReviewedAtUtc?.millisecondsSinceEpoch,
    'updated_at_utc': updatedAtUtc.millisecondsSinceEpoch,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteProgressRow &&
          wordId == other.wordId &&
          cardState == other.cardState &&
          status == other.status &&
          firstSeenAtUtc == other.firstSeenAtUtc &&
          lastReviewedAtUtc == other.lastReviewedAtUtc;

  @override
  int get hashCode =>
      Object.hash(wordId, cardState, status, firstSeenAtUtc, lastReviewedAtUtc);

  @override
  String toString() =>
      'RemoteProgressRow(${wordId.value}, ${status.name}, '
      'updatedAt: $updatedAtUtc)';

  static DateTime _dateFromMs(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('$key: ожидалось целое число');
  }

  static DateTime _requireUtc(DateTime value, String name) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, name, 'must be UTC');
    }
    return value;
  }

  static DateTime? _requireUtcOrNull(DateTime? value, String name) =>
      value == null ? null : _requireUtc(value, name);
}

/// Транспорт до облачного хранилища прогресса.
///
/// Интерфейс отделён от Supabase, чтобы сервис слияния тестировался без сети.
abstract interface class RemoteProgressStore {
  /// Все строки текущего пользователя.
  Future<List<RemoteProgressRow>> fetchAll();

  /// Вставляет или обновляет строки текущего пользователя.
  Future<void> upsertAll(List<RemoteProgressRow> rows);
}
