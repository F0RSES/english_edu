import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/usecases/explain_error.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:test/test.dart';

import 'fakes/fake_error_explainer.dart';
import 'fakes/fake_settings_repository.dart';

void main() {
  test('passes level from settings', () async {
    final explainer = FakeErrorExplainer();
    final useCase = ExplainError(
      explainer: explainer,
      settings: FakeSettingsRepository(
        UserSettings.defaults().copyWith(preferredLevel: CefrLevel.b2),
      ),
    );

    await useCase(gameType: 'cloze_test', context: 'ошибка');

    expect(explainer.lastContext, contains('Уровень пользователя: B2.'));
  });

  test('passes game type and context', () async {
    final explainer = FakeErrorExplainer();
    final useCase = ExplainError(
      explainer: explainer,
      settings: FakeSettingsRepository(),
    );

    final result = await useCase(
      gameType: 'word_scramble',
      context: 'Нужно было собрать: "apple".',
    );

    expect(result, 'Объяснение');
    expect(explainer.lastGameType, 'word_scramble');
    expect(explainer.lastContext, contains('Игра: word_scramble.'));
    expect(
      explainer.lastContext,
      contains('Контекст ошибки: Нужно было собрать: "apple".'),
    );
  });

  test('propagates AiException', () async {
    final explainer = FakeErrorExplainer()..throwOnExplain = true;
    final useCase = ExplainError(
      explainer: explainer,
      settings: FakeSettingsRepository(),
    );

    await expectLater(
      useCase(gameType: 'typing', context: 'ошибка'),
      throwsA(isA<AiException>()),
    );
  });
}
