import 'package:flutter/material.dart';

/// Длительность idle-цикла: плавное парение (Phase 40).
const _idleDuration = Duration(seconds: 2);

/// Длительность talking-цикла: быстрый bounce.
const _talkingDuration = Duration(milliseconds: 400);

/// Амплитуда парения по Y в логических пикселях.
const _idleFloatAmplitude = 4.0;
const _talkingFloatAmplitude = 2.0;

/// Границы «дыхания» (scale) по режимам.
const _idleScaleMin = 0.98;
const _idleScaleMax = 1.02;
const _talkingScaleMin = 0.95;
const _talkingScaleMax = 1.05;

/// Ассет маскота ИИ-помощника.
const _assetPath = 'assets/images/ai_avatar.png';

/// Маскот ИИ-помощника с анимацией (Phase 40).
///
/// Idle: плавное парение (±4 px по Y) и дыхание (scale 0.98–1.02), цикл 2 с.
/// [isTalking] (генерация ответа): быстрый bounce — цикл 0.4 с,
/// scale 0.95–1.05, ±2 px. Контроллер освобождается в dispose.
class AiAvatar extends StatefulWidget {
  /// Создаёт аватар; [size] — сторона квадратной картинки.
  const AiAvatar({this.size = 48, this.isTalking = false, super.key});

  /// Сторона аватара в логических пикселях.
  final double size;

  /// true — помощник «говорит/думает»: быстрый bounce вместо парения.
  final bool isTalking;

  @override
  State<AiAvatar> createState() => _AiAvatarState();
}

class _AiAvatarState extends State<AiAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _float;
  late Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _idleDuration);
    _configure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTicker();
  }

  @override
  void didUpdateWidget(AiAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTalking != widget.isTalking) {
      _configure();
      // Сброс фазы, чтобы новый режим стартовал с начала цикла.
      _controller.reset();
      _updateTicker();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Уважает системный запрет анимаций (accessibility): контроллер стоит.
  void _updateTicker() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  /// Амплитуды и duration зависят от режима; вызывается при смене isTalking.
  void _configure() {
    final talking = widget.isTalking;
    _controller.duration = talking ? _talkingDuration : _idleDuration;
    final floatAmplitude = talking
        ? _talkingFloatAmplitude
        : _idleFloatAmplitude;
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _float = Tween<double>(
      begin: -floatAmplitude,
      end: floatAmplitude,
    ).animate(curve);
    _breath = Tween<double>(
      begin: talking ? _talkingScaleMin : _idleScaleMin,
      end: talking ? _talkingScaleMax : _idleScaleMax,
    ).animate(curve);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        key: const Key('ai-avatar-float'),
        offset: Offset(0, _float.value),
        child: Transform.scale(
          key: const Key('ai-avatar-breath'),
          scale: _breath.value,
          child: child,
        ),
      ),
      child: Image.asset(_assetPath, width: widget.size, height: widget.size),
    );
  }
}
