import 'dart:async';
import 'dart:convert';

import 'package:english_edu/domain/services/chat_generator.dart';
import 'package:english_edu/domain/services/cloze_generator.dart';
import 'package:english_edu/domain/services/error_explainer.dart';
import 'package:english_edu/domain/services/error_task_generator.dart';
import 'package:english_edu/domain/services/hint_generator.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';
import 'package:http/http.dart' as http;

/// Адрес прокси AI-подсказок (ADR-019).
///
/// Прямой доступ к провайдеру модели запрещён: ключ живёт на прокси, клиент его
/// не знает.
const _proxyUrl = 'https://english-edu-ai.forses17.workers.dev/';

/// Таймаут запроса: подсказка не должна держать кадр дольше этого времени.
const _requestTimeout = Duration(seconds: 10);

/// Таймаут задания мини-игры: генерация длиннее, чем подсказка.
const _taskTimeout = Duration(seconds: 15);

/// Значение поля `type`, которое просит прокси вернуть задание игры.
const _errorHunterType = 'error_hunter';

/// Значение поля `type` для задания «Заполни пропуск» (ADR-025).
const _clozeType = 'cloze_test';

/// Значение поля `type` для чата с помощником (ADR-041).
const _chatType = 'chat';

/// Таймаут чата: ответ по контексту длиннее, чем подсказка к одному слову.
const _chatTimeout = Duration(seconds: 30);

/// Значение поля `type` для объяснения ошибки в игре (ADR-042).
const _explainType = 'explain_error';

/// Таймаут объяснения: модель разбирает контекст ошибки, ответ не мгновенный.
const _explainTimeout = Duration(seconds: 30);

/// Ошибка AI-подсказки: сеть, статус ответа или неожиданный формат.
///
/// Отдельный тип нужен, чтобы UI отличал «нет подсказки» от прочих сбоев и не
/// показывал пользователю текст исключения.
final class AiException implements Exception {
  /// Создаёт ошибку с [message]; [statusCode] заполняется для ответов прокси.
  const AiException(this.message, {this.statusCode});

  /// Человекочитаемая причина для логов.
  final String message;

  /// HTTP-статус ответа, если запрос дошёл до прокси.
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'AiException($message)'
      : 'AiException($message, status: $statusCode)';
}

/// Клиент AI-ассоциаций через прокси (ADR-019).
///
/// Реализует доменный [HintGenerator]: домен не знает про HTTP.
/// Сеть используется только по явному действию пользователя (кнопка
/// «Подсказка»): учебный цикл остаётся офлайн.
final class AiClient
    implements
        HintGenerator,
        ErrorTaskGenerator,
        ClozeGenerator,
        ChatGenerator,
        ErrorExplainer {
  /// Создаёт клиент поверх переданного `http.Client`: тесты подставляют
  /// `MockClient`, приложение — реальный клиент.
  AiClient(this._client);

  final http.Client _client;

  /// Запрашивает ассоциацию для [word] (контракт [HintGenerator]).
  ///
  /// Бросает [AiException] на неуспешный статус, неверный JSON или пустой
  /// ответ; таймаут пробрасывается как [TimeoutException].
  @override
  Future<String> generate(String word) async {
    final response = await _client
        .post(
          Uri.parse(_proxyUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'word': word}),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw AiException(
        'AI proxy returned a non-200 status',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw AiException('AI proxy returned invalid JSON: ${error.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw const AiException('AI proxy returned a non-object payload');
    }
    final association = decoded['association'];
    if (association is! String || association.trim().isEmpty) {
      throw const AiException('AI proxy returned no association');
    }
    return association;
  }

  /// Запрашивает задание «Охота на ошибки» для [word] уровня [level] (Phase 8).
  ///
  /// Уровень уходит в поле `word` вместе со словом: прокси принимает только
  /// это поле (Phase 27a). Бросает [AiException] на неуспешный статус,
  /// неверный JSON или задание, не прошедшее валидацию схемы.
  @override
  Future<ErrorHunterTask> generateErrorTask(
    String word, {
    required String level,
  }) async {
    final response = await _client
        .post(
          Uri.parse(_proxyUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'type': _errorHunterType,
            'word': '$level - $word',
          }),
        )
        .timeout(_taskTimeout);

    if (response.statusCode != 200) {
      throw AiException(
        'AI proxy returned a non-200 status',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw AiException('AI proxy returned invalid JSON: ${error.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw const AiException('AI proxy returned a non-object payload');
    }
    try {
      return ErrorHunterTask.fromJson(decoded);
    } on FormatException catch (error) {
      throw AiException('AI proxy returned a malformed task: ${error.message}');
    }
  }

  /// Запрашивает задание «Заполни пропуск» для [word] уровня [level] (ADR-025).
  ///
  /// Уровень уходит в поле `word` вместе со словом: прокси принимает только
  /// это поле (Phase 27a). Бросает [AiException] на неуспешный статус,
  /// неверный JSON или задание, не прошедшее валидацию схемы.
  @override
  Future<ClozeTask> generateCloze(String word, {required String level}) async {
    final response = await _client
        .post(
          Uri.parse(_proxyUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'type': _clozeType, 'word': '$level - $word'}),
        )
        .timeout(_taskTimeout);

    if (response.statusCode != 200) {
      throw AiException(
        'AI proxy returned a non-200 status',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw AiException('AI proxy returned invalid JSON: ${error.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw const AiException('AI proxy returned a non-object payload');
    }
    try {
      return ClozeTask.fromJson(decoded);
    } on FormatException catch (error) {
      throw AiException('AI proxy returned a malformed task: ${error.message}');
    }
  }

  /// Отправляет контекст чата и уровень пользователя, возвращает ответ
  /// помощника (контракт [ChatGenerator], ADR-041).
  ///
  /// Бросает [AiException] на неуспешный статус, неверный JSON или пустой
  /// ответ; таймаут пробрасывается как [TimeoutException].
  @override
  Future<String> sendChat({
    required List<({String role, String content})> messages,
    required String level,
  }) async {
    final response = await _client
        .post(
          Uri.parse(_proxyUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'type': _chatType,
            'messages': [
              for (final message in messages)
                {'role': message.role, 'content': message.content},
            ],
            'word': level,
          }),
        )
        .timeout(_chatTimeout);

    if (response.statusCode != 200) {
      throw AiException(
        'AI proxy returned a non-200 status',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw AiException('AI proxy returned invalid JSON: ${error.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw const AiException('AI proxy returned a non-object payload');
    }
    final message = decoded['message'];
    if (message is! String || message.trim().isEmpty) {
      throw const AiException('AI proxy returned no chat message');
    }
    return message;
  }

  /// Объясняет ошибку в мини-игре (контракт [ErrorExplainer], ADR-042).
  ///
  /// [gameType] в payload отдельно не уходит: use case уже включает игру
  /// в [context], а прокси принимает только поле `word`. Уровень [level]
  /// добавляется к контексту префиксом (Phase 27a).
  ///
  /// Бросает [AiException] на неуспешный статус, неверный JSON или пустой
  /// ответ; таймаут пробрасывается как [TimeoutException].
  @override
  Future<String> explain({
    required String gameType,
    required String context,
    required String level,
  }) async {
    final response = await _client
        .post(
          Uri.parse(_proxyUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'type': _explainType, 'word': '$level - $context'}),
        )
        .timeout(_explainTimeout);

    if (response.statusCode != 200) {
      throw AiException(
        'AI proxy returned a non-200 status',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw AiException('AI proxy returned invalid JSON: ${error.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw const AiException('AI proxy returned a non-object payload');
    }
    final explanation = decoded['explanation'];
    if (explanation is! String || explanation.trim().isEmpty) {
      throw const AiException('AI proxy returned no explanation');
    }
    return explanation;
  }
}
