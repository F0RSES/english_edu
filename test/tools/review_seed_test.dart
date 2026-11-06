import 'dart:math';

import 'package:test/test.dart';

import '../../tools/review_seed_lib.dart';

Map<String, Object?> seedWord({
  int id = 1,
  String term = 'apple',
  String translation = 'яблоко',
  String? level = 'A1',
  String? partOfSpeech = 'noun',
}) => {
  'id': id,
  'term': term,
  'translation': translation,
  'level': level,
  'partOfSpeech': partOfSpeech,
};

void main() {
  group('parseReviewVerdict', () {
    test('should_accept_a_correct_verdict', () {
      final verdict = parseReviewVerdict(
        '{"isCorrect": true, "issues": [], '
        '"suggestedTranslation": null, "suggestedPartOfSpeech": null}',
      );

      expect(verdict.isCorrect, isTrue);
      expect(verdict.issues, isEmpty);
      expect(verdict.suggestedTranslation, isNull);
      expect(verdict.suggestedPartOfSpeech, isNull);
    });

    test('should_read_suggested_fixes', () {
      final verdict = parseReviewVerdict(
        '{"isCorrect": false, "issues": ["partOfSpeech should be '
        '\'adjective\'"], "suggestedTranslation": null, '
        '"suggestedPartOfSpeech": "adjective"}',
      );

      expect(verdict.isCorrect, isFalse);
      expect(verdict.issues.single, contains('adjective'));
      expect(verdict.suggestedPartOfSpeech, 'adjective');
    });

    test('should_treat_malformed_json_as_a_problem', () {
      final verdict = parseReviewVerdict('not json at all');

      expect(verdict.isCorrect, isFalse);
      expect(verdict.issues.single, contains('parse error'));
    });

    test('should_strip_code_fences_around_json', () {
      final verdict = parseReviewVerdict(
        'Вот результат:\n```json\n{"isCorrect": true}\n```\n',
      );

      expect(verdict.isCorrect, isTrue);
    });

    test('should_treat_missing_isCorrect_as_a_problem', () {
      final verdict = parseReviewVerdict('{"issues": []}');

      expect(verdict.isCorrect, isFalse);
      expect(verdict.issues.single, contains('isCorrect'));
    });
  });

  group('selectWords', () {
    List<Map<String, Object?>> sample() => [
      seedWord(),
      seedWord(id: 2, level: 'A2'),
      seedWord(id: 3, level: 'B1'),
      seedWord(id: 4, level: 'B1'),
      seedWord(id: 5, level: 'C1'),
    ];

    test('should_filter_by_levels_case_insensitively', () {
      final selected = selectWords(sample(), levels: {'b1'});

      expect(selected.map((word) => word['id']), [3, 4]);
    });

    test('should_return_everything_without_levels', () {
      expect(selectWords(sample()), hasLength(5));
    });

    test('should_respect_the_sample_limit', () {
      final selected = selectWords(sample(), sample: 2, random: Random(7));

      expect(selected, hasLength(2));
      // Выборка берётся из отфильтрованного набора, а не из всего файла.
      expect(
        selectWords(sample(), levels: {'B1'}, sample: 5),
        hasLength(2),
      );
    });
  });

  group('buildReviewReport', () {
    test('should_write_the_documented_schema', () {
      final report = buildReviewReport(
        reviewedAt: DateTime.utc(2026, 11, 7, 10, 30),
        totalWords: 2071,
        checkedCount: 1000,
        problems: const [
          ReviewProblem(
            id: 42,
            term: 'ephemeral',
            level: 'C1',
            translation: 'эфемерный',
            partOfSpeech: 'noun',
            issues: ['partOfSpeech should be adjective'],
            suggestedTranslation: null,
            suggestedPartOfSpeech: 'adjective',
          ),
        ],
      );

      expect(report['reviewedAt'], '2026-11-07T10:30:00.000Z');
      expect(report['totalWords'], 2071);
      expect(report['checkedCount'], 1000);
      expect(report['problemsFound'], 1);

      final problems = report['problems']! as List<Object?>;
      final first = problems.single! as Map<String, Object?>;
      expect(first['id'], 42);
      expect(first['term'], 'ephemeral');
      expect(first['partOfSpeech'], 'noun');
      expect(first['suggestedPartOfSpeech'], 'adjective');
      expect(first['suggestedTranslation'], isNull);
    });

    test('should_format_the_summary_line', () {
      expect(
        formatSummary(checkedCount: 1000, problemsFound: 87),
        'Checked 1000 words, found 87 problems (8.7%)',
      );
      expect(problemRate(checkedCount: 0, problemsFound: 0), 0);
    });
  });

  group('applyManualOverrides', () {
    List<Map<String, Object?>> words() => [
      seedWord(term: 'accord', translation: 'аккорд'),
      seedWord(id: 2, term: 'block', translation: 'блокировать'),
    ];

    test('should_apply_overrides_case_insensitively', () {
      final items = words();
      final result = applyManualOverrides(items, [
        {
          'term': ' ACCORD ',
          'translation': 'соглашение',
          'partOfSpeech': 'noun',
          'autoTranslated': false,
        },
      ]);

      expect(result.applied, 1);
      expect(result.missingTerms, isEmpty);
      expect(items.first['translation'], 'соглашение');
      expect(items.first['autoTranslated'], isFalse);
      // Второе слово не тронуто.
      expect(items.last['translation'], 'блокировать');
    });

    test('should_change_only_the_fields_present_in_the_override', () {
      final items = words();
      applyManualOverrides(items, [
        {'term': 'block', 'translation': 'блок'},
      ]);

      expect(items.last['translation'], 'блок');
      // partOfSpeech остался исходным: в правке его не было.
      expect(items.last['partOfSpeech'], 'noun');
      expect(items.last.containsKey('autoTranslated'), isFalse);
    });

    test('should_report_terms_that_are_missing_from_the_seed', () {
      final result = applyManualOverrides(words(), [
        {'term': 'nonexistent', 'translation': 'нет такого'},
      ]);

      expect(result.applied, 0);
      expect(result.missingTerms, ['nonexistent']);
    });

    test('should_ignore_overrides_without_a_term', () {
      final result = applyManualOverrides(words(), [
        {'translation': 'без термина'},
      ]);

      expect(result.applied, 0);
      expect(result.missingTerms, isEmpty);
    });
  });
}
