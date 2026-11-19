import 'dart:io';

import 'package:english_edu/core/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Максимум слов никнейма, из которых берутся инициалы.
const _maxInitialsWords = 2;

/// Доля размера аватара для fallback-иконки.
const _iconSizeFactor = 0.6;

/// Доля размера аватара для шрифта инициалов.
const _initialsFontSizeFactor = 0.4;

/// Аватар пользователя в пузырях чата (Phase 42).
///
/// Файл из профиля (ADR-044); если файла нет — инициалы никнейма,
/// если никнейма нет — иконка. Данные — из `settingsProvider`.
class UserAvatar extends ConsumerWidget {
  /// Создаёт аватар диаметром [size] логических пикселей.
  const UserAvatar({required this.size, super.key});

  /// Диаметр аватара.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider).value;
    final initials = _initialsOf(settings?.nickname);
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.secondaryContainer,
      child: initials == null
          ? Icon(
              Icons.person,
              size: size * _iconSizeFactor,
              color: scheme.onSecondaryContainer,
            )
          : Text(
              initials,
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                fontSize: size * _initialsFontSizeFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
    final avatarPath = settings?.avatarPath;
    if (avatarPath == null) {
      return fallback;
    }
    // Отсутствующий файл (например, после импорта снимка) даёт fallback,
    // а не ошибку загрузки изображения — паттерн ProfileScreen.
    return FutureBuilder<File?>(
      future: ref.read(avatarStorageProvider).getAvatarFile(avatarPath),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return fallback;
        }
        return CircleAvatar(radius: size / 2, backgroundImage: FileImage(file));
      },
    );
  }

  /// Первые буквы до двух слов никнейма; null — никнейма нет.
  String? _initialsOf(String? nickname) {
    final trimmed = nickname?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final words = trimmed.split(RegExp(r'\s+'));
    return words
        .take(_maxInitialsWords)
        .map((word) => word.substring(0, 1))
        .join()
        .toUpperCase();
  }
}
