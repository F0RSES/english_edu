import 'dart:async';

import 'package:english_edu/presentation/widgets/ai_avatar.dart';
import 'package:flutter/material.dart';

/// Интервал моргания (Phase 41): каждые 3.5 с.
const _blinkInterval = Duration(milliseconds: 3500);

/// Длительность моргания: 150 мс закрытие + 150 мс открытие.
const _blinkDuration = Duration(milliseconds: 300);

/// Длительность подмигивания при открытии чата.
const _winkDuration = Duration(milliseconds: 400);

/// Цикл рта во время talking.
const _mouthDuration = Duration(milliseconds: 250);

/// Цвет тёмного экрана маскота (веки и заплатка рта) — семпл из ассета.
const _screenColor = Color(0xFF041711);

/// Цвет светлых глаз/рта маскота — семпл из ассета.
const _faceLightColor = Color(0xFF94FA7E);

/// Координаты мимики в долях стороны аватара (измерено по ассету 1254×1254).
const _eyeLeftX = 0.345;
const _eyeRightX = 0.55;
const _eyeTopY = 0.535;
const _eyeWidth = 0.105;
const _eyeHeight = 0.065;
const _mouthPatchLeftX = 0.44;
const _mouthPatchTopY = 0.60;
const _mouthPatchWidth = 0.12;
const _mouthPatchHeight = 0.06;
const _mouthWidth = 0.09;
const _mouthMinHeight = 0.015;
const _mouthMaxHeight = 0.055;

/// Мимика маскота поверх плоской картинки (Phase 41).
///
/// Глаза-дуги уже нарисованы в ассете: моргание перекрывает их тёмными
/// «веками» (высота 0 → полная), рот — светлый овал поверх статичной улыбки,
/// появляется только при [isTalking]. [winkOnStart] — одноразовое
/// подмигивание левым глазом при появлении (открытие чата).
///
/// Уважает системный запрет анимаций: таймер моргания и контроллеры стоят.
/// Все контроллеры и таймер освобождаются в dispose.
class AnimatedAiFace extends StatefulWidget {
  /// Создаёт лицо; [size] — сторона квадратной картинки.
  const AnimatedAiFace({
    required this.size,
    this.isTalking = false,
    this.winkOnStart = false,
    super.key,
  });

  /// Сторона аватара в логических пикселях.
  final double size;

  /// true — рот анимированно открывается/закрывается.
  final bool isTalking;

  /// true — одноразовое подмигивание левым глазом при появлении.
  final bool winkOnStart;

  @override
  State<AnimatedAiFace> createState() => _AnimatedAiFaceState();
}

class _AnimatedAiFaceState extends State<AnimatedAiFace>
    with TickerProviderStateMixin {
  late final AnimationController _blink;
  late final AnimationController _wink;
  late final AnimationController _mouth;
  late final Animation<double> _blinkValue;
  late final Animation<double> _winkValue;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: _blinkDuration);
    _wink = AnimationController(vsync: this, duration: _winkDuration);
    _mouth = AnimationController(vsync: this, duration: _mouthDuration);
    // Веки закрываются за первую половину цикла и открываются за вторую.
    _blinkValue = _closedOpen(_blink);
    _winkValue = _closedOpen(_wink);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(AnimatedAiFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTalking != widget.isTalking) {
      _syncAnimations();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blink.dispose();
    _wink.dispose();
    _mouth.dispose();
    super.dispose();
  }

  /// 0 → 1 → 0: закрытие и открытие века за один прогон контроллера.
  Animation<double> _closedOpen(AnimationController controller) =>
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
      ]).animate(controller);

  /// Старт/остановка анимаций с учётом accessibility-запрета.
  void _syncAnimations() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _blink.stop();
      _wink.stop();
      _mouth.stop();
      return;
    }
    _blinkTimer ??= Timer.periodic(_blinkInterval, (_) {
      _blink.forward(from: 0);
    });
    if (widget.winkOnStart && !_wink.isCompleted) {
      _wink.forward(from: 0);
    }
    if (widget.isTalking) {
      if (!_mouth.isAnimating) {
        _mouth.repeat(reverse: true);
      }
    } else {
      _mouth
        ..stop()
        ..value = 0;
    }
  }

  /// Левый глаз закрывается и морганием, и подмигиванием.
  double get _leftEyeClosed => _blinkValue.value > _winkValue.value
      ? _blinkValue.value
      : _winkValue.value;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        children: [
          Image.asset(aiAvatarAsset, width: s, height: s),
          Positioned(
            left: s * _eyeLeftX,
            top: s * _eyeTopY,
            child: AnimatedBuilder(
              animation: Listenable.merge([_blink, _wink]),
              builder: (context, _) => SizedBox(
                key: const Key('ai-face-left-eyelid'),
                width: s * _eyeWidth,
                height: s * _eyeHeight * _leftEyeClosed,
                child: const ColoredBox(color: _screenColor),
              ),
            ),
          ),
          Positioned(
            left: s * _eyeRightX,
            top: s * _eyeTopY,
            child: AnimatedBuilder(
              animation: _blink,
              builder: (context, _) => SizedBox(
                key: const Key('ai-face-right-eyelid'),
                width: s * _eyeWidth,
                height: s * _eyeHeight * _blinkValue.value,
                child: const ColoredBox(color: _screenColor),
              ),
            ),
          ),
          if (widget.isTalking)
            Positioned(
              left: s * _mouthPatchLeftX,
              top: s * _mouthPatchTopY,
              child: SizedBox(
                width: s * _mouthPatchWidth,
                height: s * _mouthPatchHeight,
                child: ColoredBox(
                  color: _screenColor,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _mouth,
                      builder: (context, _) => Container(
                        key: const Key('ai-face-mouth'),
                        width: s * _mouthWidth,
                        height:
                            s *
                            (_mouthMinHeight +
                                (_mouthMaxHeight - _mouthMinHeight) *
                                    _mouth.value),
                        decoration: BoxDecoration(
                          color: _faceLightColor,
                          borderRadius: BorderRadius.circular(s * _mouthWidth),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
