import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:test/test.dart';

void main() {
  group('AppLanguage', () {
    test('codes and labels are stable', () {
      expect(AppLanguage.ru.code, 'ru');
      expect(AppLanguage.en.code, 'en');
      expect(AppLanguage.ru.label, 'Русский');
      expect(AppLanguage.en.label, 'English');
    });

    test('fromCode restores known languages', () {
      expect(AppLanguage.fromCode('ru'), AppLanguage.ru);
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
    });

    test('fromCode falls back to ru for unknown codes', () {
      expect(AppLanguage.fromCode('de'), AppLanguage.ru);
      expect(AppLanguage.fromCode(''), AppLanguage.ru);
      expect(AppLanguage.fromCode('RU'), AppLanguage.ru);
    });
  });
}
