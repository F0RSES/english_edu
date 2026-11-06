/// Авторизация в облаке (ADR-022).
///
/// Контракт в domain, чтобы экраны не зависели от Supabase. Реализация без
/// настроенных ключей — заглушка: приложение работает офлайн как обычно.
abstract interface class CloudAuthService {
  /// Настроено ли облако (есть URL и anon key, SDK инициализирован).
  bool get isAvailable;

  /// Email текущего пользователя; null — не авторизован.
  String? get email;

  /// Поток изменения авторизации: null — вышел, строка — вошёл.
  Stream<String?> get authChanges;

  /// Отправляет magic link на [email]; вход завершается по ссылке из письма.
  Future<void> signInWithMagicLink(String email);

  /// Выходит из аккаунта.
  Future<void> signOut();
}
