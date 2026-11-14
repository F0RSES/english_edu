import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Кнопка «Спросить у помощника» рядом с сообщением об ошибке (ADR-042).
///
/// Появляется только после неверного ответа и не блокирует игру: объяснение
/// открывается в нижнем листе по явному тапу. В build провайдеры не читаются —
/// экраны игр могут показывать кнопку без AI-overrides в тестах.
class ErrorHelperButton extends ConsumerStatefulWidget {
  /// Создаёт кнопку для игры [gameType] с контекстом ошибки [context].
  const ErrorHelperButton({
    required this.gameType,
    required this.context,
    this.compact = false,
    super.key,
  });

  /// Идентификатор игры для контекста объяснения.
  final String gameType;

  /// Что было и что ответил пользователь.
  final String context;

  /// Compact-режим для встраивания рядом с текстом.
  final bool compact;

  @override
  ConsumerState<ErrorHelperButton> createState() => _ErrorHelperButtonState();
}

class _ErrorHelperButtonState extends ConsumerState<ErrorHelperButton> {
  bool _loading = false;

  Future<void> _ask() async {
    if (_loading) {
      return;
    }
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    setState(() => _loading = true);
    try {
      final explanation = await ref.read(explainErrorProvider)(
        gameType: widget.gameType,
        context: widget.context,
      );
      if (!mounted) {
        return;
      }
      // Loading снимается до открытия листа: иначе спиннер под модалкой
      // анимируется бесконечно и pumpAndSettle в тестах не завершается.
      setState(() => _loading = false);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        S.explain(lang),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    explanation,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(S.gotIt(lang)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.explainFailed(lang))));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return IconButton(
      tooltip: S.askAssistant(lang),
      color: scheme.primary,
      visualDensity: widget.compact ? VisualDensity.compact : null,
      iconSize: widget.compact ? 20 : 24,
      onPressed: _loading ? null : _ask,
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.smart_toy),
    );
  }
}
