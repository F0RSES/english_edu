import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экспорт через буфер обмена (ADR-014): JSON схемы v1, собранный
/// `ExportProgress`.
///
/// Файловый диалог не используется: `file_selector` — внешний пакет с
/// разрешениями платформ, а снимок словаря на сотни слов помещается в
/// clipboard.
class ExportDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог.
  const ExportDialog({super.key});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  late final Future<String> _json = _buildJson();

  Future<String> _buildJson() async {
    final payload = await ref.read(exportProgressProvider).call();
    return ref.read(payloadCodecProvider).encode(payload);
  }

  Future<void> _copy(String json) async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    try {
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.copiedToClipboard(lang))));
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Clipboard write failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.copyFailed(lang))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return FutureBuilder<String>(
      future: _json,
      builder: (context, snapshot) {
        final json = snapshot.data;
        return AlertDialog(
          title: Text(S.exportTile(lang)),
          content: SizedBox(
            width: 480,
            height: 320,
            child: _body(snapshot, json, lang),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.close(lang)),
            ),
            FilledButton(
              onPressed: json == null ? null : () => _copy(json),
              child: Text(S.copy(lang)),
            ),
          ],
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<String> snapshot, String? json, AppLanguage lang) {
    if (snapshot.hasError) {
      return Center(child: Text(S.exportBuildFailed(lang)));
    }
    if (json == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: SelectableText(
        json,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
