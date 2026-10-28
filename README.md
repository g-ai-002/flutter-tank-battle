# 坦克大战

经典坦克大战 Flutter 复刻版，支持 Android、Windows 与 Web 三平台。

## 功能特性

- 🎮 经典坦克大战核心玩法：移动、射击、碰撞检测
- 🤖 AI 敌人：自动寻路与射击
- 🗺️ 多关卡地图：砖墙、钢铁、水域、基地
- 💎 道具系统：护盾、加速、火力增强
- 🎵 音效与背景音乐：射击/爆炸/道具/过关/失败音效 + 循环背景音乐
- 🎨 Material 3 设计：浅色/深色主题
- 📱 跨平台：Android + Windows + Web
- 🌐 Web 版：浏览器内直接试玩，桌面保留键盘、移动端自动切换摇杆
- 🕹️ 动态虚拟摇杆：移动端左下区域按下处即摇杆中心
- ⌨️ 键盘操作：桌面端 WASD + 空格
- 🔥 基于 Flame 引擎的战场渲染与主循环

## 在线试玩

浏览器打开即可开战，无需安装：

- 🎮 版本索引页（最新正式版本 + 全部历史版本）：
  <https://g-ai-002.github.io/flutter-tank-battle/>
- 🧪 调试预览：<https://g-ai-002.github.io/flutter-tank-battle/debug/>

> 桌面浏览器用方向键 / WASD 移动、空格射击、P 暂停；
> 触屏浏览器用左下摇杆移动、右下按钮射击。

## 操作说明

| 操作 | 桌面端        | 移动端 / Web                 |
| ---- | ------------- | ---------------------------- |
| 移动 | 方向键 / WASD | 动态摇杆（左下按下处即中心） |
| 射击 | 空格键        | 射击按钮                     |
| 暂停 | P 键          | 顶部暂停按钮                 |

## 游戏规则

- 消灭所有敌方坦克即可过关
- 保护基地（底部中央黄色区域）不被摧毁
- 拾取道具获得临时增益效果
- 共 5 关，全部通过即为胜利

## 版本历史

### v0.5.0 (2026-10-27)

- 支持 Web 平台与 GitHub Pages 多版本在线试玩
- 日志、文件系统、窗口初始化改为条件导入，Web 端保留内存日志
- 静态网格/地形烘焙为 `ui.Picture`，暂停/结算时停掉 Flame 主循环
- 操作提示按桌面、触屏与浏览器自适应
- 游戏页 HUD 独立订阅并加 `RepaintBoundary`，避免 GameWidget 随 HUD 重建
- 版本号 0.4.1 → 0.5.0

### v0.4.1 (2026-10-24)
- 战场地形录制为 `ui.Picture` 缓存，逐帧只回放绘制指令
- `GameMap` 增加 `revision`，砖墙被击毁等原地修改时重建缓存
- 补充地形 `revision` 回归测试

### v0.4.0 (2026-10-24)
- 战场渲染与主循环迁移到 Flame 1.38.2（固定分辨率 World + CameraComponent）
- 地形、单位、爆炸/炮口特效拆为独立组件，主循环改由 `FlameGame.update` 驱动
- 点击射击迁移到 Flame `TapCallbacks`，新增爆炸/炮口闪光与相机抖动
- 保留键盘、虚拟摇杆与射击按钮操控

### v0.2.0 (2026-06-21)
- 音效与背景音乐系统：射击/爆炸/道具/过关/失败音效 + 循环背景音乐
- 设置页音效开关接入实际功能
- 使用 audioplayers 播放 WAV 音效

### v0.1.2 (2026-06-21)
- 重构优化：拆分 GamePainter、简化 StorageService、提取 GameOverlay/PowerUpManager
- 增加 EnemyAI、GameEngine 单元测试

### v0.1.1 (2026-06-21)
- 修复 CI 类型检查报错（enemySpawnTimer 类型、clamp 返回值）
- 修复 StorageService 测试缺少 Flutter binding 初始化

### v0.1.0 (2026-06-21)
- 首个版本：坦克大战最小可用集
- 经典坦克大战核心玩法（移动、射击、碰撞检测）
- AI 敌人自动寻路与射击
- 多关卡地图系统（砖墙、钢铁、水域、基地）
- 道具系统（护盾、加速、火力增强）
- Material 3 浅色/深色主题
- 虚拟手柄 + 键盘操作
- Android + Windows 双平台

## 下载

- 在线试玩（Web）：<https://g-ai-002.github.io/flutter-tank-battle/>
- [GitHub Releases](https://github.com/g-ai-002/flutter-tank-battle/releases)
  （Android APK / Windows ZIP / Web ZIP）

## 开发

```bash
# 安装依赖
flutter pub get

# 运行测试
flutter test

# 运行应用
flutter run

# 生成 Web 平台文件（web/ 目录不入库，需先生成）
flutter create --platforms=web --project-name flutter_tank_battle .

# 运行 Web 版（浏览器打开）
flutter run -d chrome

# 构建 Web 产物（输出到 build/web）
flutter build web --release
```

Web 站点由 GitHub Actions 的 `build-web` job 发布到 `gh-pages` 分支：
tag 触发的构建发布到 `v<版本号>/`，其他触发发布到 `debug/`，
根目录会自动生成版本索引页与 `versions.json`。`web/` 目录不入库，
由流水线用 `flutter create --platforms=web` 生成后再构建。

## 技术栈

- Flutter 3.47.8
- Provider 状态管理
- Material 3 设计系统
- Flame 1.38.2 游戏引擎（组件化渲染 + 主循环）
- Flutter Web（CanvasKit）+ GitHub Pages 多版本部署
