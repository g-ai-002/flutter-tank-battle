import 'game_enums.dart';

class GameMap {
  final int cols;
  final int rows;
  final List<List<TileType>> tiles;

  GameMap({required this.cols, required this.rows})
      : tiles = List.generate(rows, (_) => List.filled(cols, TileType.empty));

  TileType tileAt(int col, int row) {
    if (col < 0 || col >= cols || row < 0 || row >= rows) return TileType.steel;
    return tiles[row][col];
  }

  void setTile(int col, int row, TileType type) {
    if (col >= 0 && col < cols && row >= 0 && row < rows) {
      tiles[row][col] = type;
    }
  }

  static GameMap createLevel(int level) {
    final map = GameMap(cols: 26, rows: 26);

    // 边界
    for (int c = 0; c < 26; c++) {
      map.setTile(c, 0, TileType.steel);
      map.setTile(c, 25, TileType.steel);
    }
    for (int r = 0; r < 26; r++) {
      map.setTile(0, r, TileType.steel);
      map.setTile(25, r, TileType.steel);
    }

    // 基地（底部中央）
    map.setTile(12, 24, TileType.base);
    map.setTile(13, 24, TileType.base);
    map.setTile(12, 25, TileType.base);
    map.setTile(13, 25, TileType.base);
    // 基地围墙
    map.setTile(11, 23, TileType.brick);
    map.setTile(14, 23, TileType.brick);
    map.setTile(11, 24, TileType.brick);
    map.setTile(14, 24, TileType.brick);
    map.setTile(11, 25, TileType.brick);
    map.setTile(14, 25, TileType.brick);

    // 根据关卡生成不同布局
    _addBrickWall(map, 2, 2, 4, level);
    _addBrickWall(map, 20, 2, 4, level);
    _addBrickWall(map, 10, 4, 6, level);
    _addBrickWall(map, 2, 8, 3, level);
    _addBrickWall(map, 21, 8, 3, level);
    _addBrickWall(map, 8, 10, 10, level);
    _addBrickWall(map, 2, 14, 4, level);
    _addBrickWall(map, 20, 14, 4, level);
    _addBrickWall(map, 10, 16, 6, level);
    _addBrickWall(map, 4, 20, 3, level);
    _addBrickWall(map, 19, 20, 3, level);

    // 钢铁障碍物
    if (level >= 2) {
      map.setTile(6, 6, TileType.steel);
      map.setTile(19, 6, TileType.steel);
      map.setTile(12, 12, TileType.steel);
      map.setTile(13, 12, TileType.steel);
    }
    if (level >= 3) {
      map.setTile(6, 18, TileType.steel);
      map.setTile(19, 18, TileType.steel);
    }

    // 水域
    if (level >= 2) {
      _addWater(map, 10, 8, 6);
    }
    if (level >= 4) {
      _addWater(map, 2, 12, 4);
      _addWater(map, 20, 12, 4);
    }

    return map;
  }

  static void _addBrickWall(GameMap map, int col, int row, int len, int level) {
    final count = (len * 0.6).ceil() + level;
    for (int i = 0; i < count && i < len; i++) {
      map.setTile(col + i, row, TileType.brick);
    }
  }

  static void _addWater(GameMap map, int col, int row, int len) {
    for (int i = 0; i < len; i++) {
      map.setTile(col + i, row, TileType.water);
    }
  }
}
