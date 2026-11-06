import 'dart:async';
import 'dart:convert';

import 'package:english_edu/domain/services/error_task_generator.dart';
import 'package:english_edu/domain/services/hint_generator.dart';
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
final class AiClient implements HintGenerator, ErrorTaskGenerator {
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

  /// Запрашивает задание «Охота на ошибки» для [word] (Phase 8).
  ///
  /// Бросает [AiException] на неуспешный статус, неверный JSON или задание,
  /// не прошедшее валидацию схемы.
  @override
  Future<ErrorHunterTask> generateErrorTask(String word) async {
    final response = await _client
        .post(
          Uri.parse(_proxyUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'type': _errorHunterType, 'word': word}),
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
}
