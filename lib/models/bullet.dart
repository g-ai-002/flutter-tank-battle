import 'game_enums.dart';

class Bullet {
  double x;
  double y;
  final Direction direction;
  final double speed;
  bool active;
  final bool fromPlayer;

  Bullet({
    required this.x,
    required this.y,
    required this.direction,
    this.speed = 300.0,
    this.active = true,
    required this.fromPlayer,
  });

  double get centerX => x + 2;
  double get centerY => y + 2;

  void update(double dt) {
    final dist = speed * dt;
    switch (direction) {
      case Direction.up:
        y -= dist;
      case Direction.down:
        y += dist;
      case Direction.left:
        x -= dist;
      case Direction.right:
        x += dist;
    }
  }
}
