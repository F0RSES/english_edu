import 'package:flutter/material.dart';

/// Пастельная тема приложения.
ThemeData buildAppTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF2F7F6),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
