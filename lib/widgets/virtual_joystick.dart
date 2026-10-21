import 'package:flutter/material.dart';
import '../models/game_enums.dart';

/// 虚拟摇杆 + 射击按钮。
///
/// 摇杆把手相对底座中心的偏移量化为上下左右四个方向，
/// 拖动过程中不松手即可切换方向；通过 [onMoveStart]/[onMoveEnd]
/// 与键盘共用同一套移动状态机。
class VirtualJoystick extends StatefulWidget {
  final void Function(Direction dir) onMoveStart;
  final void Function(Direction dir) onMoveEnd;
  final VoidCallback onShoot;

  const VirtualJoystick({
    super.key,
    required this.onMoveStart,
    required this.onMoveEnd,
    required this.onShoot,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  static const double _baseSize = 150;
  static const double _knobSize = 56;
  static const double _shootButtonSize = 96;
  // 摇杆头中心到底座中心的最大距离（贴边时）
  static const double _maxOffset = (_baseSize - _knobSize) / 2;
  // 偏移小于死区视为回中，避免误触发
  static const double _deadZone = _maxOffset * 0.3;

  static const Key _baseKey = Key('joystick_base');
  static const Key _shootKey = Key('shoot_button');

  Offset _stickOffset = Offset.zero;
  Direction? _currentDir;
  int? _activePointer;
  bool _shootPressed = false;

  @override
  void dispose() {
    final dir = _currentDir;
    if (dir != null) widget.onMoveEnd(dir);
    super.dispose();
  }

  void _applyDirection(Direction? newDir) {
    if (newDir == _currentDir) return;
    final old = _currentDir;
    setState(() => _currentDir = newDir);
    if (old != null) widget.onMoveEnd(old);
    if (newDir != null) widget.onMoveStart(newDir);
  }

  void _updateStick(Offset localPosition) {
    // up/move/cancel 事件沿指针按下时缓存的命中链派发，组件在按住
    // 期间被销毁后事件仍会送达，此时不得再 setState 或触发回调
    if (!mounted) return;
    var delta = localPosition - Offset(_baseSize / 2, _baseSize / 2);
    if (delta.distance > _maxOffset) {
      delta = Offset.fromDirection(delta.direction, _maxOffset);
    }
    setState(() => _stickOffset = delta);
    _applyDirection(_directionFor(delta));
  }

  Direction? _directionFor(Offset delta) {
    if (delta.distance < _deadZone) return null;
    return delta.dx.abs() > delta.dy.abs()
        ? (delta.dx > 0 ? Direction.right : Direction.left)
        : (delta.dy > 0 ? Direction.down : Direction.up);
  }

  void _release() {
    // 同 _updateStick：销毁后迟到的抬起/取消事件直接忽略
    if (!mounted) return;
    _activePointer = null;
    setState(() => _stickOffset = Offset.zero);
    _applyDirection(null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // 射击按钮圆心与摇杆底座圆心同高
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildJoystick(),
          _buildShootButton(),
        ],
      ),
    );
  }

  Widget _buildJoystick() {
    return SizedBox(
      width: _baseSize,
      height: _baseSize,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (_activePointer != null) return;
          _activePointer = event.pointer;
          _updateStick(event.localPosition);
        },
        onPointerMove: (event) {
          if (event.pointer == _activePointer) _updateStick(event.localPosition);
        },
        onPointerUp: (event) {
          if (event.pointer == _activePointer) _release();
        },
        onPointerCancel: (event) {
          if (event.pointer == _activePointer) _release();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildBase(),
            AnimatedAlign(
              duration: const Duration(milliseconds: 120),
              alignment: Alignment(
                _stickOffset.dx / _maxOffset,
                _stickOffset.dy / _maxOffset,
              ),
              child: _buildKnob(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBase() {
    return Container(
      key: _baseKey,
      width: _baseSize,
      height: _baseSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 10, child: _arrow(Direction.up)),
          Positioned(bottom: 10, child: _arrow(Direction.down)),
          Positioned(left: 10, child: _arrow(Direction.left)),
          Positioned(right: 10, child: _arrow(Direction.right)),
        ],
      ),
    );
  }

  Widget _arrow(Direction dir) {
    final active = _currentDir == dir;
    final icon = switch (dir) {
      Direction.up => Icons.keyboard_arrow_up,
      Direction.down => Icons.keyboard_arrow_down,
      Direction.left => Icons.keyboard_arrow_left,
      Direction.right => Icons.keyboard_arrow_right,
    };
    return Icon(
      icon,
      size: 18,
      color: Colors.white.withValues(alpha: active ? 0.9 : 0.35),
    );
  }

  Widget _buildKnob() {
    final active = _currentDir != null;
    return Container(
      width: _knobSize,
      height: _knobSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: active ? 0.35 : 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildShootButton() {
    return GestureDetector(
      key: _shootKey,
      // 按压动效：按下时按钮缩小并变亮，让点击反馈可见
      onTapDown: (_) => setState(() => _shootPressed = true),
      onTapUp: (_) => setState(() => _shootPressed = false),
      onTapCancel: () => setState(() => _shootPressed = false),
      onTap: widget.onShoot,
      child: AnimatedScale(
        scale: _shootPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: _shootButtonSize,
          height: _shootButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _shootPressed ? const Color(0xFFFF6E40) : const Color(0xFFE53935),
          ),
          child: const Center(
            child: Text(
              '射击',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
