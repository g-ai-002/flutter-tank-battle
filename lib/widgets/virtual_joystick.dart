import 'package:flutter/material.dart';
import '../models/game_enums.dart';

/// 动态虚拟摇杆。
///
/// 铺满父级给定的触控区（游戏页为左下区域），手指按下的位置
/// 即底座中心（钳制在触控区内），提升跟手体验；空闲时底座停在
/// 左下角锚点并变淡，松手后也滑回锚点。
///
/// 摇杆把手相对底座中心的偏移量化为上下左右四个方向，
/// 拖动过程中不松手即可切换方向；通过 [onMoveStart]/[onMoveEnd]
/// 与键盘共用同一套移动状态机。
class VirtualJoystick extends StatefulWidget {
  final void Function(Direction dir) onMoveStart;
  final void Function(Direction dir) onMoveEnd;

  const VirtualJoystick({
    super.key,
    required this.onMoveStart,
    required this.onMoveEnd,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  static const double _baseSize = 150;
  static const double _knobSize = 56;
  // 摇杆头中心到底座中心的最大距离（贴边时）
  static const double _maxOffset = (_baseSize - _knobSize) / 2;
  // 偏移小于死区视为回中，避免误触发
  static const double _deadZone = _maxOffset * 0.3;
  // 空闲时底座半透明提示触控区，按下后完全不透明
  static const double _idleOpacity = 0.4;
  // 松手后底座滑回锚点并变淡的时长；按下时零延迟瞬移跟手
  static const Duration _settleDuration = Duration(milliseconds: 150);
  // 空闲锚点距左、下边缘的边距，与右下射击按钮的边距一致
  static const double _anchorMargin = 16;

  static const Key _baseKey = Key('joystick_base');

  // 触控区尺寸，build 时写入，供按下时把底座中心钳制在区域内
  Size _zoneSize = Size.zero;
  // 底座中心（触控区坐标系）；null 表示空闲，底座停在左下角锚点
  Offset? _baseCenter;
  Offset _stickOffset = Offset.zero;
  Direction? _currentDir;
  int? _activePointer;

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

  /// 按下点即底座中心；按在触控区边缘时钳制，避免底座超出屏幕
  Offset _clampToZone(Offset position) {
    final size = _zoneSize;
    if (size.width < _baseSize || size.height < _baseSize) {
      return size.center(Offset.zero);
    }
    final radius = _baseSize / 2;
    return Offset(
      position.dx.clamp(radius, size.width - radius).toDouble(),
      position.dy.clamp(radius, size.height - radius).toDouble(),
    );
  }

  /// 空闲时底座停在左下角（内缩一圈边距），与右下射击按钮齐平
  Offset _anchorCenter() {
    return _clampToZone(
      Offset(
        _anchorMargin + _baseSize / 2,
        _zoneSize.height - _anchorMargin - _baseSize / 2,
      ),
    );
  }

  void _updateStick(Offset localPosition) {
    // up/move/cancel 事件沿指针按下时缓存的命中链派发，组件在按住
    // 期间被销毁后事件仍会送达，此时不得再 setState 或触发回调
    if (!mounted) return;
    final base = _baseCenter;
    if (base == null) return;
    var delta = localPosition - base;
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
    setState(() {
      _baseCenter = null;
      _stickOffset = Offset.zero;
    });
    _applyDirection(null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _zoneSize = constraints.biggest;
        final active = _baseCenter != null;
        final base = _baseCenter ?? _anchorCenter();
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (_activePointer != null) return;
            _activePointer = event.pointer;
            _baseCenter = _clampToZone(event.localPosition);
            _updateStick(event.localPosition);
          },
          onPointerMove: (event) {
            if (event.pointer == _activePointer) {
              _updateStick(event.localPosition);
            }
          },
          onPointerUp: (event) {
            if (event.pointer == _activePointer) _release();
          },
          onPointerCancel: (event) {
            if (event.pointer == _activePointer) _release();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 按下时底座零延迟瞬移到手指处（跟手），
              // 松手后按 _settleDuration 滑回锚点并变淡
              AnimatedPositioned(
                duration: active ? Duration.zero : _settleDuration,
                left: base.dx - _baseSize / 2,
                top: base.dy - _baseSize / 2,
                child: AnimatedOpacity(
                  duration: active ? Duration.zero : _settleDuration,
                  opacity: active ? 1 : _idleOpacity,
                  child: _buildStick(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 底座与把手的固定尺寸视觉，实际位置由外层 AnimatedPositioned 决定
  Widget _buildStick() {
    return SizedBox(
      width: _baseSize,
      height: _baseSize,
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
}

/// 射击按钮，与摇杆独立布置（游戏页固定在右下角）。
class ShootButton extends StatefulWidget {
  final VoidCallback onShoot;

  const ShootButton({super.key, required this.onShoot});

  @override
  State<ShootButton> createState() => _ShootButtonState();
}

class _ShootButtonState extends State<ShootButton> {
  static const double _shootButtonSize = 96;

  static const Key _shootKey = Key('shoot_button');

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _shootKey,
      // 按压动效：按下时按钮缩小并变亮，让点击反馈可见
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onShoot,
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: _shootButtonSize,
          height: _shootButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed ? const Color(0xFFFF6E40) : const Color(0xFFE53935),
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
