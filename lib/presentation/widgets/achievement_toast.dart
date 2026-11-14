import 'dart:async';

import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Тост о новом достижении поверх экрана (ADR-035).
///
/// Overlay, а не SnackBar: SnackBar занимает низ экрана и перекрывает кнопки
/// ответа, а тост должен только сообщить и уйти.
final class AchievementToast {
  const AchievementToast._();

  /// Показывает тост и сразу возвращает управление.
  static void show(
    BuildContext context,
    Achievement achievement, {
    AppLanguage lang = AppLanguage.ru,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AchievementToastWidget(
        achievement: achievement,
        lang: lang,
        onDismissed: () {
          // Запись могли уже снять (например, экран закрыли) — повторное
          // удаление бросило бы исключение.
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );
    overlay.insert(entry);
    unawaited(HapticFeedback.heavyImpact());
  }
}

class _AchievementToastWidget extends StatefulWidget {
  const _AchievementToastWidget({
    required this.achievement,
    required this.lang,
    required this.onDismissed,
  });

  final Achievement achievement;
  final AppLanguage lang;
  final VoidCallback onDismissed;

  @override
  State<_AchievementToastWidget> createState() =>
      _AchievementToastWidgetState();
}

class _AchievementToastWidgetState extends State<_AchievementToastWidget> {
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.mediumImpact());
    _timer = Timer(const Duration(seconds: 3), _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Уводит тост и сообщает владельцу, что запись можно снимать.
  Future<void> _close() async {
    if (_closing) {
      return;
    }
    setState(() => _closing = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(20);

    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: false,
        child: GestureDetector(
          onTap: _close,
          child:
              AnimatedOpacity(
                    opacity: _closing ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: AnimatedSlide(
                      offset: _closing ? const Offset(0, -0.4) : Offset.zero,
                      duration: const Duration(milliseconds: 250),
                      child: Material(
                        elevation: 8,
                        borderRadius: radius,
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [scheme.primary, scheme.primaryContainer],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: radius,
                          ),
                          child: Row(
                            children: [
                              Text(
                                widget.achievement.type.icon,
                                style: const TextStyle(fontSize: 44),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      S.achievementToast(widget.lang),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                    Text(
                                      S.achievementTitle(
                                        widget.achievement.type,
                                        widget.lang,
                                      ),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                    Text(
                                      S.achievementDescription(
                                        widget.achievement.type,
                                        widget.lang,
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .slideY(
                    begin: -1,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
