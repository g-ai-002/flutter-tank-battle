import 'package:flutter/material.dart';
import '../models/game_enums.dart';

class VirtualJoystick extends StatefulWidget {
  final void Function(Direction dir) onMove;
  final VoidCallback onShoot;

  const VirtualJoystick({
    super.key,
    required this.onMove,
    required this.onShoot,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Direction? _currentDir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 方向键
          _buildDPad(),
          // 射击按钮
          _buildShootButton(),
        ],
      ),
    );
  }

  Widget _buildDPad() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 上
          Positioned(
            top: 0,
            child: _dPadButton(Direction.up, Icons.keyboard_arrow_up),
          ),
          // 下
          Positioned(
            bottom: 0,
            child: _dPadButton(Direction.down, Icons.keyboard_arrow_down),
          ),
          // 左
          Positioned(
            left: 0,
            child: _dPadButton(Direction.left, Icons.keyboard_arrow_left),
          ),
          // 右
          Positioned(
            right: 0,
            child: _dPadButton(Direction.right, Icons.keyboard_arrow_right),
          ),
        ],
      ),
    );
  }

  Widget _dPadButton(Direction dir, IconData icon) {
    final isActive = _currentDir == dir;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _currentDir = dir);
        widget.onMove(dir);
      },
      onTapUp: (_) {
        setState(() => _currentDir = null);
      },
      onTapCancel: () {
        setState(() => _currentDir = null);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildShootButton() {
    return GestureDetector(
      onTap: widget.onShoot,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE53935),
        ),
        child: const Center(
          child: Text(
            '射击',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
