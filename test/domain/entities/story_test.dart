import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:test/test.dart';

Story story({String? text, String? translation}) => Story(
  id: 1,
  title: 'My Morning',
  text: text ?? 'I wake up at seven. I eat breakfast.',
  translation: translation ?? 'Я просыпаюсь в семь. Я завтракаю.',
  level: CefrLevel.a1,
);

void main() {
  test('should_count_words_when_text_has_single_spaces', () {
    expect(story().wordCount, 8);
  });

  test('should_count_words_when_whitespace_repeats', () {
    expect(story(text: 'Hello   world').wordCount, 2);
  });

  test('should_copy_with_replaced_fields', () {
    final copy = story().copyWith(title: 'Other', level: CefrLevel.b1);

    expect(copy.title, 'Other');
    expect(copy.level, CefrLevel.b1);
    expect(copy.text, story().text);
    expect(copy.id, 1);
  });

  test('should_be_equal_when_all_fields_match', () {
    expect(story(), story());
    expect(story().hashCode, story().hashCode);
    expect(story(), isNot(story(translation: 'другой')));
  });
}
