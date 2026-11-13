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
  Future<List<ChatMessage>> getLastN(int n) async {
    if (n <= 0) {
      throw ArgumentError.value(n, 'n', 'must be positive');
    }
    final start = _messages.length > n ? _messages.length - n : 0;
    return _messages.sublist(start);
  }

  @override
  Future<void> append(ChatMessage message) async {
    // Имитация autoIncrement: id назначает «БД», переданный игнорируется.
    _messages.add(
      ChatMessage(
        id: _nextId++,
        role: message.role,
        content: message.content,
        createdAtUtc: message.createdAtUtc,
      ),
    );
  }

  @override
  Future<void> clear() async {
    _messages.clear();
  }
}
