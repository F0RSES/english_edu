import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Импорт через буфер обмена (ADR-014): JSON схемы v1 заменяет всё состояние.
///
/// REPLACE, не merge — см. `ImportProgress` (ADR-005). Сначала проверяются
/// JSON и версия схемы, потом запрашивается подтверждение: испорченный снимок
/// не должен дойти до записи в базу.
///
/// Ошибка показывается внутри диалога, а не в `SnackBar`: модальное окно
/// перекрывает нижнюю полосу, и сообщение было бы не видно.
class ImportDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог.
  const ImportDialog({super.key});

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  final _input = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _input.text.trim();
    final ExportPayload payload;
    try {
      payload = ref.read(payloadCodecProvider).decode(raw);
    } on FormatException catch (error) {
      setState(() => _error = 'Невалидный JSON: ${error.message}');
      return;
    } on Object catch (error) {
      setState(() => _error = 'Невалидный JSON: $error');
      return;
    }
    final isSupported =
        payload.schemaVersion >= 1 &&
        payload.schemaVersion <= ExportPayload.currentSchemaVersion;
    if (!isSupported) {
      setState(
        () =>
            _error = 'Неподдерживаемая версия схемы: ${payload.schemaVersion}',
      );
      return;
    }
    if (!await _confirm()) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(importProgressProvider).call(payload);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object catch (error, stack) {
      ref.read(loggerProvider).error('Import failed', error, stack);
      await ref
          .read(crashReporterProvider)
          .captureException(error, stackTrace: stack, context: 'import');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Не удалось импортировать данные';
        });
      }
    }
  }

  Future<bool> _confirm() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт'),
        content: const Text('Все данные будут заменены. Продолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Импорт'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Вставьте JSON резервной копии:'),
          const SizedBox(height: 8),
          TextField(
            controller: _input,
            maxLines: 10,
            minLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '{"schemaVersion": 2, ...}',
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(false),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: const Text('Импортировать'),
      ),
    ],
  );
}
