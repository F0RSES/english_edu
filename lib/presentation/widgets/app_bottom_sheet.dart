import 'package:flutter/material.dart';

/// Радиус скругления верхних углов листа.
const _cornerRadius = 24.0;

/// Ширина «ручки» свайпа.
const _handleWidth = 40.0;

/// Высота «ручки» свайпа.
const _handleHeight = 4.0;

/// Радиус скругления «ручки».
const _handleRadius = 2.0;

/// Отступы «ручки»: сверху и снизу.
const _handleMargin = EdgeInsets.only(top: 12, bottom: 8);

/// Отступы контента; верхний отступ уже даёт «ручка».
const _contentPadding = EdgeInsets.fromLTRB(24, 0, 24, 24);

/// Единое оформление нижних листов (Phase 53a).
///
/// Скруглённые верхние углы, «ручка» для свайпа и фон
/// `surfaceContainerLow`; контент защищён `SafeArea` от нижней системной
/// панели. Вызов в одну строку — [AppBottomSheet.show].
///
/// Длинный контент должен скроллиться сам (например,
/// `SingleChildScrollView`): лист подстраивается под высоту контента.
class AppBottomSheet extends StatelessWidget {
  /// Создаёт лист с контентом [child].
  const AppBottomSheet({required this.child, super.key});

  /// Содержимое листа.
  final Widget child;

  /// Открывает модальный лист с единым оформлением.
  ///
  /// `isScrollControlled` — лист может быть выше половины экрана; фон
  /// прозрачный, чтобы скругления рисовал сам контейнер. Возвращает
  /// результат `Navigator.pop`, как [showModalBottomSheet].
  static Future<T?> show<T>(BuildContext context, Widget child) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AppBottomSheet(child: child),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const Key('app-bottom-sheet'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_cornerRadius),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: _contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const Key('app-bottom-sheet-handle'),
                width: _handleWidth,
                height: _handleHeight,
                margin: _handleMargin,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(_handleRadius),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
