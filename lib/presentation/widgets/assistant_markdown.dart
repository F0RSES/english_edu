import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Отступ текста списка от маркера (Phase 45).
const _listIndent = 24.0;

/// Радиус скругления блока кода (Phase 45).
const _codeBlockRadius = 12.0;

/// Внутренний отступ блока кода.
const _codeBlockPadding = EdgeInsets.all(12);

/// Вертикальный отступ между блоками Markdown.
const _blockSpacing = 8.0;

/// Markdown-рендер ответа ассистента (Phase 45, ADR-047).
///
/// Формат ответов модели — Markdown (жирный, списки, код, таблицы);
/// пользовательские сообщения остаются обычным Text. Стили наследуют
/// тему: текст onSurface, блоки кода — surfaceContainerHighest со
/// скруглением и тонкой рамкой (пузырь того же цвета — рамка отделяет
/// блок). Длинные строки кода скроллятся горизонтально внутри блока
/// (SingleChildScrollView пакета), без переполнения пузыря. Ссылки
/// инертны: onTapLink не задан, пакет не открывает URL сам.
class AssistantMarkdown extends StatelessWidget {
  /// Создаёт рендер для [data] — Markdown-текста ответа ассистента.
  const AssistantMarkdown({required this.data, super.key});

  /// Markdown-текст ответа.
  final String data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodyMedium;
    final textStyle = base?.copyWith(color: scheme.onSurface);
    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: textStyle,
        strong: textStyle?.copyWith(fontWeight: FontWeight.bold),
        em: textStyle?.copyWith(fontStyle: FontStyle.italic),
        a: textStyle?.copyWith(color: scheme.primary),
        code: textStyle?.copyWith(fontFamily: 'monospace'),
        codeblockPadding: _codeBlockPadding,
        codeblockDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(_codeBlockRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        listIndent: _listIndent,
        listBullet: textStyle,
        blockSpacing: _blockSpacing,
        tableHead: textStyle?.copyWith(fontWeight: FontWeight.bold),
        tableBody: textStyle,
        tableBorder: TableBorder.all(color: scheme.outlineVariant),
      ),
    );
  }
}
