# Content Licenses

Статус лицензий на учебный контент. Файл ведётся вместе с `assets/seed/*.json`.

## Current sources

| sourceId | Что содержит | Лицензия | Статус |
|---|---|---|---|
| `manual-mvp` | 20 слов (PoC), ручная выборка | CC0 (manual selection, translations pending review) | placeholder, требует замены |

## Planned sources

### NGSL (New General Service List)

- Источник терминов: https://www.newgeneralservicelist.com/
- Лицензия списка: **CC BY-SA 4.0**.
- Attribution: «Terms from NGSL, © Browne, Culligan & Phillips, licensed under CC BY-SA 4.0.»
- **Share-alike:** распространяется на список terms, а не на приложение целиком. Terms выделены в отдельный файл `assets/seed/`, поэтому SA не «заражает» код приложения — но производный список terms обязан оставаться под CC BY-SA.

### Транскрипции

Сейчас `autoTranslated` (DeepSeek) — **pending review**.
План: заменить на Wiktionary (CC BY-SA) или ручную проверку.

### Переводы

Сейчас `autoTranslated` — **pending review**.
План: авторские переводы или Wiktionary.

### Примеры предложений

Сейчас `autoTranslated` — **pending review**.
План: Tatoeba (CC BY 2.0 FR) или авторские.

## Auto-translated content

`autoTranslated: true` означает «машинный перевод, не проходил ревью».

- Валидатор такие слова пропускает (только warning).
- В финальный продукт они не входят до ревью.
- UI может пометить их (Phase 4), но это не заменяет ревью.
- `sourceId: ngsl-auto` — маркер непроверенного контента.

## Review plan

Phase 2: заменить все `autoTranslated: true` на проверенные значения и обновить `sourceId` (`ngsl-auto` → `ngsl-verified`). Критерий закрытия — BL-21: в `assets/seed/` не остаётся `autoTranslated=true`, валидатор даёт 0 warnings.

## Attribution in app

Phase 7: экран «About» со списком лицензий контента и ссылками на источники. До этого атрибуция живёт только в репозитории.

## Правила

- Новый источник добавляется только с конкретной лицензией и ссылкой.
- Нельзя смешивать в одном `sourceId` контент с разными лицензиями.
- Машинный перевод всегда помечается `autoTranslated: true`.
