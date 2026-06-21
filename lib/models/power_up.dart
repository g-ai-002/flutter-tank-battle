import 'game_enums.dart';

class PowerUp {
  double x;
  double y;
  final PowerUpType type;
  bool active;

  PowerUp({
    required this.x,
    required this.y,
    required this.type,
    this.active = true,
  });
}
