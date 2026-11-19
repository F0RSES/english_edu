import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/repositories/chat_repository.dart';

/// In-memory chat repository for use-case and widget tests.
final class FakeChatRepository implements ChatRepository {
  /// Creates a fake, optionally pre-filled with [initial].
  FakeChatRepository([List<ChatMessage> initial = const []])
    : _messages = List.of(initial),
      _nextId = initial.length + 1;

  final List<ChatMessage> _messages;
  int _nextId;

  /// All appended messages, in insertion order.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  @override
  Future<List<ChatMessage>> getAll() async => List.of(_messages);

  @override
  Future<List<ChatMessage>> getBySession(int sessionId) async =>
      _messages.where((m) => m.sessionId == sessionId).toList();

  @override
  Future<List<ChatMessage>> getLastN(int n, {required int sessionId}) async {
    if (n <= 0) {
      throw ArgumentError.value(n, 'n', 'must be positive');
    }
    final sessionMessages = _messages
        .where((m) => m.sessionId == sessionId)
        .toList();
    final start = sessionMessages.length > n ? sessionMessages.length - n : 0;
    return sessionMessages.sublist(start);
  }

  @override
  Future<void> append(ChatMessage message) async {
    // Имитация autoIncrement: id назначает «БД», переданный игнорируется.
    _messages.add(
      ChatMessage(
        id: _nextId++,
        sessionId: message.sessionId,
        role: message.role,
        content: message.content,
        createdAtUtc: message.createdAtUtc,
      ),
    );
  }

  @override
  Future<void> clear(int sessionId) async {
    _messages.removeWhere((m) => m.sessionId == sessionId);
  }
}
