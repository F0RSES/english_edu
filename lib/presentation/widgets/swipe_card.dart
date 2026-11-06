import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Доля ширины карточки, после которой свайп считается завершённым.
const _thresholdFraction = 0.3;

/// Длительность вылета карточки за экран.
const _flyOutDuration = Duration(milliseconds: 220);

/// Длительность пружинного возврата на место.
const _returnDuration = Duration(milliseconds: 420);

/// Максимальный угол поворота карточки, радианы (~20°).
const _maxRotation = 0.35;

/// Во сколько раз карточка увеличивается к моменту порога.
const _maxScale = 1.05;

/// Смещение за экран: гарантированно скрывает карточку при любом размере.
const _flyOutFactor = 1.4;

/// Карточка с физикой свайпа вместо `Dismissible`.
///
/// Смещение задаёт поворот, масштаб и цвет подложки; при отпускании меньше
/// порога карточка возвращается пружиной, больше — улетает за экран и только
/// после этого сообщает направление через [onSwiped].
///
/// `Dismissible` не используется: он не даёт поворота и масштаба и начинает
/// анимацию до того, как ответ записан.
class SwipeCard extends StatefulWidget {
  /// Создаёт карточку; [onSwiped] получает `1` (вправо) или `-1` (влево).
  const SwipeCard({
    required this.child,
    required this.onSwiped,
    this.enabled = true,
    super.key,
  });

  /// Содержимое карточки.
  final Widget child;

  /// Вызывается после вылета карточки.
  final void Function(int direction) onSwiped;

  /// Выключенный свайп оставляет только кнопки.
  final bool enabled;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Offset>? _animation;
  Offset _offset = Offset.zero;
  double _width = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(() {
        final animation = _animation;
        if (animation != null) {
          setState(() => _offset = animation.value);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Насколько свайп близок к порогу: 0 — покой, 1 — порог.
  double get _progress {
    final limit = _width * _thresholdFraction;
    if (limit == 0) {
      return 0;
    }
    return (_offset.dx.abs() / limit).clamp(0.0, 1.0);
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled || _busy) {
      return;
    }
    // Тактильная отдача в начале жеста: пользователь чувствует, что карточка
    // «взялась», ещё до решения.
    unawaited(HapticFeedback.lightImpact());
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _busy) {
      return;
    }
    setState(() => _offset += details.delta);
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (!widget.enabled || _busy) {
      return;
    }
    final width = _width == 0 ? 400.0 : _width;
    if (_offset.dx.abs() <= width * _thresholdFraction) {
      await _animateTo(Offset.zero, _returnDuration, Curves.elasticOut);
      return;
    }
    final direction = _offset.dx > 0 ? 1 : -1;
    _busy = true;
    await _animateTo(
      Offset(direction * width * _flyOutFactor, _offset.dy),
      _flyOutDuration,
      Curves.easeIn,
    );
    if (!mounted) {
      return;
    }
    widget.onSwiped(direction);
  }

  /// Проигрывает переход от текущего смещения к [target].
  Future<void> _animateTo(Offset target, Duration duration, Curve curve) async {
    _controller.duration = duration;
    _animation = Tween<Offset>(
      begin: _offset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));
    await _controller.forward(from: 0);
    _animation = null;
  }

  @override
  Widget build(BuildContext context) {
    _width = MediaQuery.sizeOf(context).width;
    final angle = _offset.dx / (_width == 0 ? 400.0 : _width) * _maxRotation;
    final scale = 1 + (_maxScale - 1) * _progress;
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _SwipeHint(progress: _progress, dx: _offset.dx),
            ),
          ),
          Transform.translate(
            offset: _offset,
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}

/// Цветная подложка: зелёная вправо («Знаю»), красная влево («Не знаю»).
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.progress, required this.dx});

  final double progress;
  final double dx;

  @override
  Widget build(BuildContext context) {
    if (progress == 0) {
      return const SizedBox.shrink();
    }
    final toRight = dx > 0;
    final color = (toRight ? Colors.green : Colors.red).withValues(
      alpha: 0.18 * progress,
    );
    return Container(
      alignment: toRight ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        toRight ? 'Знаю' : 'Не знаю',
        style: TextStyle(
          color: toRight ? Colors.green.shade800 : Colors.red.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 18 * progress.clamp(0.6, 1.0),
        ),
      ),
    );
  }
}
