import 'game_enums.dart';

class Tank {
  double x;
  double y;
  Direction direction;
  final TankType type;
  int lives;
  double speed;
  bool shielded;
  int firepower;
  double shootTimer;

  Tank({
    required this.x,
    required this.y,
    this.direction = Direction.up,
    required this.type,
    this.lives = 1,
    this.speed = 120.0,
    this.shielded = false,
    this.firepower = 1,
    this.shootTimer = 0.0,
  });

  double get centerX => x + 12;
  double get centerY => y + 12;

  void move(double dt) {
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

  void moveBack(double dt) {
    final dist = speed * dt;
    switch (direction) {
      case Direction.up:
        y += dist;
      case Direction.down:
        y -= dist;
      case Direction.left:
        x += dist;
      case Direction.right:
        x -= dist;
    }
  }
}
