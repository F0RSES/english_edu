import 'package:english_edu/domain/services/cloud_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Адрес возврата из письма; схема объявлена в `AndroidManifest.xml`.
const _redirectTo = 'io.supabase.englishedu://login-callback/';

/// Авторизация Supabase по magic link (ADR-022).
///
/// Токен сессии живёт в хранилище SDK; после перезапуска пользователь остаётся
/// в системе, поэтому экран получает email из [email] без сетевого запроса.
final class SupabaseCloudAuthService implements CloudAuthService {
  /// Создаёт сервис поверх инициализированного клиента.
  const SupabaseCloudAuthService(this._client);

  final SupabaseClient _client;

  @override
  bool get isAvailable => true;

  @override
  String? get email => _client.auth.currentUser?.email;

  @override
  Stream<String?> get authChanges =>
      _client.auth.onAuthStateChange.map((state) => state.session?.user.email);

  @override
  Future<void> signInWithMagicLink(String email) =>
      _client.auth.signInWithOtp(email: email, emailRedirectTo: _redirectTo);

  @override
  Future<void> signOut() => _client.auth.signOut();
}

/// Заглушка, когда облако не настроено.
///
/// Приложение остаётся офлайн-first: экран показывает «недоступно» вместо
/// ошибки, а вход завершается явным исключением, если его всё же нажали.
final class UnavailableCloudAuthService implements CloudAuthService {
  /// Создаёт заглушку.
  const UnavailableCloudAuthService();

  @override
  bool get isAvailable => false;

  @override
  String? get email => null;

  @override
  Stream<String?> get authChanges => const Stream.empty();

  @override
  Future<void> signInWithMagicLink(String email) async =>
      throw StateError('cloud is not configured');

  @override
  Future<void> signOut() async {}
}
