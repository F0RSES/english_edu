import 'dart:async';

import 'package:english_edu/domain/services/cloud_auth_service.dart';

/// Управляемая авторизация для виджет-тестов (ADR-022).
///
/// `signInWithMagicLink` не меняет состояние: вход завершается по ссылке из
/// письма, поэтому тест эмулирует его через [emit].
final class FakeCloudAuthService implements CloudAuthService {
  /// Создаёт фейк; [available] = false имитирует ненастроенное облако.
  FakeCloudAuthService({this.available = true, String? email}) : _email = email;

  /// Доступно ли облако.
  final bool available;

  /// Последний запрошенный для входа адрес.
  String? requestedEmail;

  String? _email;
  final _controller = StreamController<String?>.broadcast();

  @override
  bool get isAvailable => available;

  @override
  String? get email => _email;

  @override
  Stream<String?> get authChanges => _controller.stream;

  @override
  Future<void> signInWithMagicLink(String email) async {
    requestedEmail = email;
  }

  @override
  Future<void> signOut() async => emit(null);

  /// Эмулирует завершение входа или выход.
  void emit(String? email) {
    _email = email;
    _controller.add(email);
  }

  /// Закрывает поток изменений.
  Future<void> dispose() => _controller.close();
}
