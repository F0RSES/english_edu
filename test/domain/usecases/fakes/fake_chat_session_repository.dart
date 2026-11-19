import 'package:english_edu/domain/entities/chat_session.dart';
import 'package:english_edu/domain/repositories/chat_session_repository.dart';

/// In-memory chat session repository for use-case and widget tests.
final class FakeChatSessionRepository implements ChatSessionRepository {
  /// Creates a fake, optionally pre-filled with [initial].
  FakeChatSessionRepository([List<ChatSession> initial = const []])
    : _sessions = List.of(initial),
      _nextId = initial.length + 1;

  final List<ChatSession> _sessions;
  int _nextId;

  /// All sessions, in insertion order.
  List<ChatSession> get sessions => List.unmodifiable(_sessions);

  @override
  Future<List<ChatSession>> getAll() async {
    final sorted = List.of(_sessions)
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        final byUpdated = b.updatedAtUtc.compareTo(a.updatedAtUtc);
        return byUpdated != 0 ? byUpdated : b.id.compareTo(a.id);
      });
    return sorted;
  }

  @override
  Future<ChatSession?> getMostRecent() async {
    if (_sessions.isEmpty) {
      return null;
    }
    final sorted = List.of(_sessions)
      ..sort((a, b) {
        final byUpdated = b.updatedAtUtc.compareTo(a.updatedAtUtc);
        return byUpdated != 0 ? byUpdated : b.id.compareTo(a.id);
      });
    return sorted.first;
  }

  @override
  Future<ChatSession> create({
    required String title,
    required DateTime createdAtUtc,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    if (!createdAtUtc.isUtc) {
      throw ArgumentError.value(createdAtUtc, 'createdAtUtc', 'must be UTC');
    }
    final session = ChatSession(
      id: _nextId++,
      title: trimmed,
      isPinned: false,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: createdAtUtc,
    );
    _sessions.add(session);
    return session;
  }

  @override
  Future<void> delete(int id) async {
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> rename(int id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    _replace(
      id,
      (s) => ChatSession(
        id: s.id,
        title: trimmed,
        isPinned: s.isPinned,
        createdAtUtc: s.createdAtUtc,
        updatedAtUtc: s.updatedAtUtc,
      ),
    );
  }

  @override
  Future<void> togglePin(int id) async {
    _replace(
      id,
      (s) => ChatSession(
        id: s.id,
        title: s.title,
        isPinned: !s.isPinned,
        createdAtUtc: s.createdAtUtc,
        updatedAtUtc: s.updatedAtUtc,
      ),
    );
  }

  @override
  Future<void> touch(int id, DateTime atUtc) async {
    if (!atUtc.isUtc) {
      throw ArgumentError.value(atUtc, 'atUtc', 'must be UTC');
    }
    _replace(
      id,
      (s) => ChatSession(
        id: s.id,
        title: s.title,
        isPinned: s.isPinned,
        createdAtUtc: s.createdAtUtc,
        updatedAtUtc: atUtc,
      ),
    );
  }

  void _replace(int id, ChatSession Function(ChatSession) update) {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index >= 0) {
      _sessions[index] = update(_sessions[index]);
    }
  }
}
