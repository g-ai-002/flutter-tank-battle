import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_enums.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'components/battlefield_component.dart';
import 'components/effect_layer_component.dart';
import 'components/joystick_components.dart';
import 'components/unit_layer_component.dart';
import 'tank_world.dart';

/// 基于 Flame 的坦克大战。
///
/// 战场、单位、爆炸、键盘/摇杆输入与游戏内浮层都由 Flame 承担；
/// 规则仍由 [GameProvider] 持有。
class TankGame extends FlameGame<TankWorld> with KeyboardEvents {
  TankGame({
    required this.provider,
    required this.onCanvasTap,
    required this.isMobile,
    required this.onResume,
    required this.onExit,
    required this.onNextLevel,
  }) : super(
          world: TankWorld(),
          camera: CameraComponent.withFixedResolution(
            width: worldSize,
            height: worldSize,
          ),
        );

  static const double worldSize =
      AppConstants.mapCols * AppConstants.tileSize;

  static const String pauseOverlayId = 'tankPause';
  static const String gameOverOverlayId = 'tankGameOver';
  static const String levelCompleteOverlayId = 'tankLevelComplete';
  static const String victoryOverlayId = 'tankVictory';

  static final Map<LogicalKeyboardKey, Direction> _moveKeys = {
    LogicalKeyboardKey.arrowUp: Direction.up,
    LogicalKeyboardKey.keyW: Direction.up,
    LogicalKeyboardKey.arrowDown: Direction.down,
    LogicalKeyboardKey.keyS: Direction.down,
    LogicalKeyboardKey.arrowLeft: Direction.left,
    LogicalKeyboardKey.keyA: Direction.left,
    LogicalKeyboardKey.arrowRight: Direction.right,
    LogicalKeyboardKey.keyD: Direction.right,
  };

  final GameProvider provider;
  final VoidCallback onCanvasTap;
  final bool isMobile;
  final VoidCallback onResume;
  final VoidCallback onExit;
  final VoidCallback onNextLevel;

  final math.Random _random = math.Random();
  final Set<String> _activeOverlays = {};

  late final EffectLayerComponent _effects;
  late final Vector2 _cameraBase;

  double _shakeRemaining = 0;
  double _shakeDuration = 0;
  double _shakeStrength = 0;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    _cameraBase = Vector2(worldSize / 2, worldSize / 2);
    _effects = EffectLayerComponent(priority: 5);
    await world.addAll([
      BattlefieldComponent(provider: provider, priority: 0),
      UnitLayerComponent(provider: provider, priority: 1),
      _effects,
      _BattlefieldInputComponent(
        onTap: () {
          onCanvasTap();
          provider.playerShoot();
        },
        priority: 10,
      ),
    ]);
    if (isMobile) {
      await camera.viewport.add(
        JoystickInputComponent(provider: provider, priority: 20),
      );
      await camera.viewport.add(
        ShootButtonComponent(
          onShoot: () {
            onCanvasTap();
            provider.playerShoot();
          },
          priority: 21,
        ),
      );
    }
    camera.viewfinder.position = _cameraBase;
    camera.viewfinder.zoom = 1;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final direction = _moveKeys[event.logicalKey];

    if (event is KeyUpEvent) {
      if (direction == null) {
        return KeyEventResult.ignored;
      }
      provider.stopMoving(direction);
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) {
      return direction == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }

    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (direction != null) {
      provider.startMoving(direction);
      return KeyEventResult.handled;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        provider.playerShoot();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyP:
        if (provider.state.status == GameStatus.playing) {
          provider.pauseGame();
        } else if (provider.state.status == GameStatus.paused) {
          provider.resumeGame();
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  void update(double dt) {
    final before = _Snapshot.of(provider.state);
    provider.advance(dt);
    final after = provider.state;

    final restarted = before.level != after.level ||
        (!(before.status == GameStatus.playing) &&
            after.status == GameStatus.playing);

    if (!restarted) {
      before.tanks.forEach((id, center) {
        if (!after.tanks.any((tank) => identityHashCode(tank) == id)) {
          _effects.explode(center, large: true);
          _shake(0.32, 6);
        }
      });

      for (final bullet in after.bullets) {
        if (!before.bullets.contains(identityHashCode(bullet))) {
          _effects.muzzle(Offset(bullet.x + 2, bullet.y + 2));
        }
      }
    }

    if (before.status == GameStatus.playing &&
        after.status == GameStatus.gameOver) {
      _shake(0.5, 9);
    }

    _syncOverlays(after.status);
    _updateCamera(dt);
    super.update(dt);
  }

  void _syncOverlays(GameStatus status) {
    _sync(pauseOverlayId, status == GameStatus.paused, 100);
    _sync(gameOverOverlayId, status == GameStatus.gameOver, 90);
    _sync(levelCompleteOverlayId, status == GameStatus.levelComplete, 90);
    _sync(victoryOverlayId, status == GameStatus.victory, 90);
  }

  void _sync(String id, bool visible, int priority) {
    if (visible && !_activeOverlays.contains(id)) {
      overlays.add(id, priority: priority);
      _activeOverlays.add(id);
    } else if (!visible && _activeOverlays.contains(id)) {
      overlays.remove(id);
      _activeOverlays.remove(id);
    }
  }

  void _shake(double duration, double strength) {
    _shakeRemaining = duration;
    _shakeDuration = duration;
    _shakeStrength = strength;
  }

  void _updateCamera(double dt) {
    if (_shakeRemaining <= 0) {
      camera.viewfinder.position = _cameraBase;
      return;
    }
    _shakeRemaining = math.max(0.0, _shakeRemaining - dt);
    final strength = _shakeStrength * (_shakeRemaining / _shakeDuration);
    camera.viewfinder.position = Vector2(
      _cameraBase.x + (_random.nextDouble() * 2 - 1) * strength,
      _cameraBase.y + (_random.nextDouble() * 2 - 1) * strength,
    );
  }
}

class _BattlefieldInputComponent extends PositionComponent with TapCallbacks {
  _BattlefieldInputComponent({required this.onTap, int? priority})
      : super(priority: priority, size: Vector2.all(TankGame.worldSize));

  final VoidCallback onTap;

  @override
  void onTapUp(TapUpEvent event) => onTap();
}

/// 一帧的轻量快照：记录坦克样本与子弹集合，用于识别爆炸/开火。
class _Snapshot {
  _Snapshot({
    required this.tanks,
    required this.bullets,
    required this.level,
    required this.status,
  });

  factory _Snapshot.of(GameState state) {
    final tanks = <int, Offset>{};
    for (final tank in state.tanks) {
      tanks[identityHashCode(tank)] = Offset(tank.centerX, tank.centerY);
    }
    return _Snapshot(
      tanks: tanks,
      bullets: {
        for (final bullet in state.bullets) identityHashCode(bullet),
      },
      level: state.level,
      status: state.status,
    );
  }

  final Map<int, Offset> tanks;
  final Set<int> bullets;
  final int level;
  final GameStatus status;
}
