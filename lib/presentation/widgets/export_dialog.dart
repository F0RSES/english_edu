import 'package:english_edu/core/di/providers.dart';
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
    try {
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Скопировано в буфер обмена')),
        );
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Clipboard write failed', error, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Не удалось скопировать')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _json,
    builder: (context, snapshot) {
      final json = snapshot.data;
      return AlertDialog(
        title: const Text('Экспорт'),
        content: SizedBox(
          width: 480,
          height: 320,
          child: _body(snapshot, json),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Закрыть'),
          ),
          FilledButton(
            onPressed: json == null ? null : () => _copy(json),
            child: const Text('Скопировать'),
          ),
        ],
      );
    },
  );

  Widget _body(AsyncSnapshot<String> snapshot, String? json) {
    if (snapshot.hasError) {
      return const Center(child: Text('Не удалось собрать данные'));
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
