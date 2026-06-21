import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import 'game_painter.dart';

class GameRenderer extends StatelessWidget {
  final GameState state;

  const GameRenderer({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final mapWidth = state.map.cols * AppConstants.tileSize;
    final mapHeight = state.map.rows * AppConstants.tileSize;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: mapWidth,
          height: mapHeight,
          child: CustomPaint(
            painter: GamePainter(state: state),
          ),
        ),
      ),
    );
  }
}
