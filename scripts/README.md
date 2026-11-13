# CI

Локальная проверка перед коммитом. GitHub Actions — Phase 7
(требует remote).

## Запуск

    bash scripts/ci.sh

## Что проверяется

- dart format (lib/, test/, tools/)
- flutter analyze (= 0)
- flutter test (355 passed)

## Переменные

- FLUTTER — путь к flutter (по умолчанию из PATH).

## Что НЕ проверяется

- APK build (нет Android SDK).
- iOS build (нужен macOS).
