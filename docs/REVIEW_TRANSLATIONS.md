# Как ревьюить переводы (BL-21)

2031 слово из 2071 помечены `autoTranslated: true` — это машинный перевод,
который не проходил ревью (`docs/LICENSE_CONTENT.md`). Скрипт
`tools/review_seed.dart` не переводит слова заново, а **проверяет** уже
существующие: перевод, часть речи и уровень. Итог — список подозрительных слов
для ручной правки.

Автоматически файл не правится: `autoTranslated` снимается только после
человеческой проверки.

## Стратегия

1. Начать с A1+A2 (~1000 слов) — их пользователи видят чаще всего.
2. Если доля проблем меньше 5% — остальные уровни можно оставить как есть.
3. Если больше 10% — ревьюить весь словарь.

Порог в 5% — не догма: смотреть на характер проблем. Если это сплошь
`partOfSpeech`, правка механическая; если смысловые ошибки в переводе — уровень
надо чистить целиком.

## Команды

```bash
# A1 + A2 (~1000 слов, ~$2)
DEEPSEEK_API_KEY=sk-... \
  dart run tools/review_seed.dart assets/seed/words_v2.json \
    --levels=A1,A2 \
    --output=review_a1a2.json

# B1 + B2 (~1200 слов, ~$2.5)
DEEPSEEK_API_KEY=sk-... \
  dart run tools/review_seed.dart assets/seed/words_v2.json \
    --levels=B1,B2 \
    --output=review_b1b2.json

# C1 (~500 слов, ~$1)
DEEPSEEK_API_KEY=sk-... \
  dart run tools/review_seed.dart assets/seed/words_v2.json \
    --levels=C1 \
    --output=review_c1.json

# Случайная выборка 200 слов — дешёвый аудит (~$0.4)
DEEPSEEK_API_KEY=sk-... \
  dart run tools/review_seed.dart assets/seed/words_v2.json \
    --sample=200 \
    --output=review_sample.json
```

Ключ живёт только в переменной окружения: в коде, `.env`, ассетах и git его
быть не может (`40-forbidden.md` п.1). Скрипт — dev-инструмент и ходит в API
напрямую; приложение по-прежнему использует прокси (ADR-019).

## Что на выходе

```json
{
  "reviewedAt": "2026-11-07T10:30:00.000Z",
  "totalWords": 2071,
  "checkedCount": 1000,
  "problemsFound": 87,
  "problems": [
    {
      "id": 42,
      "term": "ephemeral",
      "level": "C1",
      "translation": "эфемерный",
      "partOfSpeech": "noun",
      "issues": ["partOfSpeech should be 'adjective'"],
      "suggestedTranslation": null,
      "suggestedPartOfSpeech": "adjective"
    }
  ]
}
```

`issues` — это текст модели, а не приговор: она ошибается так же, как и в
первом проходе. `suggestedTranslation`/`suggestedPartOfSpeech` — подсказка для
правки, применять её без чтения нельзя.

## Как читать результат

- **`parse error` в `issues`** — модель ответила не JSON или запрос упал дважды
  подряд. Слово не проверено: прогнать его повторно.
- **Проблемы только в `partOfSpeech`** — самая частая и самая безопасная
  категория: правится механически (`tools/validate_seed_lib.dart` →
  `sanitizePartOfSpeech`).
- **Проблемы в переводе** — требуют ручного решения: машинная альтернатива
  может быть не лучше текущей.

## После правки

1. Внести исправления в `assets/seed/words_<level>.json` (не в `words_v2.json`:
   он собирается `tools/merge_seeds.dart`).
2. Пересобрать словарь: `dart run tools/merge_seeds.dart`.
3. Проверить: `dart run tools/validate_seed.dart assets/seed/words_v2.json` —
   ожидается `OK: … words, 2 sources`.
4. Для исправленных слов снять `autoTranslated` (или сменить `sourceId` на
   верифицированный) и обновить `docs/LICENSE_CONTENT.md`.
5. `flutter test` — словарь участвует в тестах seed-загрузчика.

## Ручные правки (overrides)

После LLM-ревью ручные фиксы вносятся в
`tools/manual_review_overrides.json`. При следующем `merge_seeds` они
применяются автоматически. Так правки не теряются при пересборке seed.

```json
{
  "_comment": "Ручные правки после LLM-ревью. Применяются merge_seeds в конце.",
  "overrides": [
    {
      "term": "accord",
      "translation": "соглашение",
      "partOfSpeech": "noun",
      "autoTranslated": false
    }
  ]
}
```

Правила:

- Меняются только те поля, которые есть в правке; остальные остаются как были.
- Совпадение по `term` без учёта регистра и пробелов по краям.
- Термин, которого нет в словаре, печатается как
  `WARNING: override term '…' not found in seed` — правка не применяется, но и
  не теряется молча: словарь мог измениться, перенесите её руками.
- `autoTranslated: false` снимайте только после того, как реально прочитали
  перевод. Это и есть смысл поля.

Порядок: `dart run tools/merge_seeds.dart` → `Applied N manual overrides` →
`dart run tools/validate_seed.dart assets/seed/words_v2.json`.

## Пройденный MVP-проход (BL-21)

Проверено 200 слов выборкой (`--sample=200`), найдено 6 проблем, все
исправлены через overrides: `accord`, `articulate`, `boycott`, `assault`,
`block`, `bludgeon`. Точность выборки — около 97%.

Предупреждений валидатора: **2065** (было 2071). Остальные слова по-прежнему
`autoTranslated: true` и ждут полного ревью.

## Ограничения

- Скрипт не проверяет дубликаты и формат — это делает `validate_seed.dart`.
- Он не знает о гомонимах (ADR-031): два слова с одним `term` проверяются
  независимо.
- Скорость: ~200 мс на слово, то есть 1000 слов ≈ 4 минуты.
- Стоимость указана грубо, по тарифам DeepSeek на момент написания; перед
  большим прогоном проверить на `--sample=20`.
