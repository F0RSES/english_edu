import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Палитра для чипа категории: восемь цветов, различимых в обеих темах.
const categoryColors = <String>[
  '#FF5722',
  '#2196F3',
  '#4CAF50',
  '#FFC107',
  '#9C27B0',
  '#00BCD4',
  '#795548',
  '#607D8B',
];

/// Диалог создания пользовательской категории (ADR-034).
///
/// Возвращает созданную [UserCategory] или null при отмене. Дубль по имени
/// ловится use case'ом и показывается сообщением: молча закрыть диалог нельзя,
/// пользователь не поймёт, почему категория не появилась.
class CreateCategoryDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог.
  const CreateCategoryDialog({super.key});

  @override
  ConsumerState<CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends ConsumerState<CreateCategoryDialog> {
  final _name = TextEditingController();
  String _colorHex = categoryColors.first;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSubmit => _name.text.trim().isNotEmpty && !_busy;

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _busy = true);

    try {
      final created = await ref.read(createUserCategoryProvider)(
        _name.text,
        colorHex: _colorHex,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(created);
    } on Object catch (error) {
      // `StateError` бросает use case при дубле; ловим через `is`, потому что
      // явный `on StateError` линтер запрещает (Error, а не Exception).
      _fail(
        error is StateError
            ? S.categoryExists(lang)
            : S.categoryCreateFailed(lang),
      );
    }
  }

  void _fail(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return AlertDialog(
      title: Text(S.newCategory(lang)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: S.categoryName(lang)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text(S.categoryColor(lang)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hex in categoryColors)
                GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          parseCategoryColor(hex) ?? theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hex == _colorHex
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(S.cancel(lang)),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(S.categoryCreate(lang)),
        ),
      ],
    );
  }
}

/// Разбирает `#RRGGBB` в цвет; null — строка не похожа на hex.
///
/// Ошибка разбора не должна ронять экран: категория могла прийти от старой
/// версии или из импорта, и тогда рисуется цвет темы по умолчанию.
Color? parseCategoryColor(String? hex) {
  if (hex == null) {
    return null;
  }
  final value = hex.replaceFirst('#', '');
  if (value.length != 6) {
    return null;
  }
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}
