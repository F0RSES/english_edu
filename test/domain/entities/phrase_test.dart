import 'package:english_edu/domain/entities/phrase.dart';
import 'package:test/test.dart';

Phrase phrase({String? translation}) => Phrase(
  id: 1,
  phrase: 'How are you?',
  translation: translation ?? 'Как дела?',
  category: 'Приветствия',
  level: 'a1',
);

void main() {
  test('should_copy_with_replaced_fields', () {
    final copy = phrase().copyWith(translation: 'Как поживаешь?');

    expect(copy.translation, 'Как поживаешь?');
    expect(copy.phrase, 'How are you?');
    expect(copy.category, 'Приветствия');
  });

  test('should_be_equal_when_all_fields_match', () {
    expect(phrase(), phrase());
    expect(phrase().hashCode, phrase().hashCode);
    expect(phrase(), isNot(phrase(translation: 'другой')));
  });

  test('should_reject_empty_fields', () {
    expect(
      () => Phrase(
        id: 1,
        phrase: '',
        translation: 'перевод',
        category: 'Тема',
        level: 'a1',
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('should_describe_itself', () {
    expect(phrase().toString(), contains('How are you?'));
  });
}
