import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Локальное хранилище аватаров (ADR-044).
///
/// Файлы живут в `appDocuments/avatars`, в БД хранится только путь:
/// изображения не раздувают базу и не попадают в export-снимок.
final class AvatarStorage {
  /// Создаёт хранилище; каталог и часы внедряются для тестов.
  AvatarStorage({
    Future<Directory> Function()? documentsDirectory,
    DateTime Function()? clock,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _clock = clock ?? DateTime.now;

  final Future<Directory> Function() _documentsDirectory;
  final DateTime Function() _clock;

  /// Копирует [image] в `avatars/{timestamp}.jpg` и возвращает новый путь.
  ///
  /// Имя по времени, а не по исходному имени: picker отдаёт временные файлы
  /// с непредсказуемыми именами, а повторный выбор не должен затирать старый
  /// аватар до успешного сохранения нового.
  Future<String> saveAvatar(File image) async {
    final documents = await _documentsDirectory();
    final avatars = Directory('${documents.path}/avatars');
    if (!avatars.existsSync()) {
      await avatars.create(recursive: true);
    }
    final path = '${avatars.path}/${_clock().millisecondsSinceEpoch}.jpg';
    await image.copy(path);
    return path;
  }

  /// Удаляет файл аватара; отсутствующий файл — не ошибка.
  Future<void> deleteAvatar(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Файл по [path] или null, если файла нет.
  ///
  /// После импорта снимка путь может указывать на файл чужого устройства:
  /// файлы не переносятся (ADR-044), UI показывает fallback-иконку.
  Future<File?> getAvatarFile(String path) async {
    final file = File(path);
    return file.existsSync() ? file : null;
  }
}
