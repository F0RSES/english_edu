import 'package:english_edu/data/sync/remote_progress_row.dart';
import 'package:english_edu/domain/services/cloud_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Таблица прогресса в Supabase (ADR-022).
const _table = 'user_progress';

/// Хранилище прогресса поверх Supabase.
///
/// Пользователь берётся из текущей сессии: `user_id` подставляет клиент, а RLS
/// на стороне БД не даёт прочитать чужие строки. Без сессии операции падают
/// [CloudSyncException], а не идут анонимно.
final class SupabaseRemoteProgressStore implements RemoteProgressStore {
  /// Создаёт хранилище поверх клиента Supabase.
  const SupabaseRemoteProgressStore(this._client);

  final SupabaseClient _client;

  /// Идентификатор текущего пользователя или ошибка.
  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const CloudSyncException('not authenticated');
    }
    return user.id;
  }

  @override
  Future<List<RemoteProgressRow>> fetchAll() async {
    final userId = _userId;
    try {
      final rows = await _client.from(_table).select().eq('user_id', userId);
      return [
        for (final row in rows)
          RemoteProgressRow.fromJson(Map<String, Object?>.from(row as Map)),
      ];
    } on FormatException catch (error) {
      throw CloudSyncException('unexpected row shape: ${error.message}');
    } on Object catch (error) {
      throw CloudSyncException('fetch failed: $error');
    }
  }

  @override
  Future<void> upsertAll(List<RemoteProgressRow> rows) async {
    if (rows.isEmpty) {
      return;
    }
    final userId = _userId;
    try {
      await _client.from(_table).upsert([
        for (final row in rows) row.toJson(userId),
      ], onConflict: 'user_id,word_id');
    } on Object catch (error) {
      throw CloudSyncException('push failed: $error');
    }
  }
}
