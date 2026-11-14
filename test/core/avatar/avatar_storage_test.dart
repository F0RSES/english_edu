import 'dart:io';

import 'package:english_edu/core/avatar/avatar_storage.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late AvatarStorage storage;
  final now = DateTime.utc(2024, 5, 15, 12);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('avatar_storage_test');
    storage = AvatarStorage(
      documentsDirectory: () async => dir,
      clock: () => now,
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'saveAvatar copies the file into avatars and returns the path',
    () async {
      final source = File('${dir.path}/source.png')
        ..writeAsBytesSync([1, 2, 3]);

      final path = await storage.saveAvatar(source);

      expect(path, '${dir.path}/avatars/${now.millisecondsSinceEpoch}.jpg');
      expect(File(path).readAsBytesSync(), [1, 2, 3]);
    },
  );

  test('getAvatarFile returns null for a missing file', () async {
    expect(await storage.getAvatarFile('${dir.path}/missing.jpg'), isNull);
  });

  test('deleteAvatar removes the file and tolerates absence', () async {
    final source = File('${dir.path}/source.png')..writeAsBytesSync([1]);
    final path = await storage.saveAvatar(source);

    await storage.deleteAvatar(path);
    expect(File(path).existsSync(), isFalse);

    // Повторное удаление не бросает: файл уже мог быть удалён вручную.
    await storage.deleteAvatar(path);
  });
}
