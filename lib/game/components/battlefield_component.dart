import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/game_enums.dart';
import '../../models/game_map.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';

/// 战场地形层：空地、砖墙、钢墙、水域与基地。
///
/// 地形只在换关或砖墙被击毁时变化，因此录制为 [ui.Picture] 缓存，
/// 逐帧只回放绘制指令，不再遍历 26×26 个格子。
class BattlefieldComponent extends PositionComponent {
  BattlefieldComponent({required this.provider, int? priority})
      : super(
          priority: priority,
          size: Vector2(
            AppConstants.mapCols * AppConstants.tileSize,
            AppConstants.mapRows * AppConstants.tileSize,
          ),
        );

  final GameProvider provider;

  final Paint _fill = Paint();
  final Paint _line = Paint()
    ..color = const Color(0xFF5D4037)
    ..strokeWidth = 0.5;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  GameMap? _cachedMap;
  int _cachedRevision = -1;
  ui.Picture? _picture;

  double get _tile => AppConstants.tileSize;

  @override
  void render(Canvas canvas) {
    final map = provider.state.map;
    if (!identical(map, _cachedMap) || map.revision != _cachedRevision) {
      _cachedMap = map;
      _cachedRevision = map.revision;
      _picture?.dispose();
      _picture = _buildPicture(map);
    }
    canvas.drawPicture(_picture!);
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }

  ui.Picture _buildPicture(GameMap map) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintMap(canvas, map);
    return recorder.endRecording();
  }

  void _paintMap(Canvas canvas, GameMap map) {
    _fill.color = const Color(0xFF1A1A1A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _fill);

    for (var row = 0; row < map.rows; row++) {
      for (var col = 0; col < map.cols; col++) {
        final tile = map.tileAt(col, row);
        final rect = Rect.fromLTWH(col * _tile, row * _tile, _tile, _tile);
        switch (tile) {
          case TileType.empty:
            continue;
          case TileType.brick:
            _drawBrick(canvas, rect);
          case TileType.steel:
            _drawSteel(canvas, rect);
          case TileType.water:
            _fill.color = const Color(0xFF1565C0);
            canvas.drawRect(rect, _fill);
          case TileType.base:
            _drawBase(canvas, rect);
        }
      }
    }
  }

  void _drawBrick(Canvas canvas, Rect rect) {
    _fill.color = const Color(0xFF8D6E63);
    canvas.drawRect(rect, _fill);
    canvas.drawLine(
      Offset(rect.left, rect.top + _tile / 2),
      Offset(rect.right, rect.top + _tile / 2),
      _line,
    );
    canvas.drawLine(
      Offset(rect.left + _tile / 2, rect.top),
      Offset(rect.left + _tile / 2, rect.bottom),
      _line,
    );
  }

  void _drawSteel(Canvas canvas, Rect rect) {
    _fill.color = const Color(0xFF9E9E9E);
    canvas.drawRect(rect, _fill);
    _stroke.color = const Color(0xFF616161);
    canvas.drawRect(rect, _stroke);
  }

  void _drawBase(Canvas canvas, Rect rect) {
    _fill.color = const Color(0xFFFFC107);
    canvas.drawRect(rect, _fill);
    _fill.color = const Color(0xFF212121);
    canvas.drawCircle(rect.center, _tile * 0.25, _fill);
  }
}
