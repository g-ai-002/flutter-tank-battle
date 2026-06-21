import 'package:flutter/material.dart';
import '../models/game_enums.dart';
import '../models/game_state.dart';

class GameHUD extends StatelessWidget {
  final GameState state;
  final int highScore;

  const GameHUD({super.key, required this.state, required this.highScore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '第 ${state.level} 关',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            '分数: ${state.score}',
            style: const TextStyle(color: Color(0xFFFFC107), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            '最高: $highScore',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFE53935), size: 16),
              const SizedBox(width: 4),
              Text(
                '${state.lives}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            '剩余: ${state.enemiesRemaining}',
            style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
