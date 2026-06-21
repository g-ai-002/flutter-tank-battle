# 坦克大战 — 项目规划

## 长期目标
- 跨 Android + Windows 双平台的经典坦克大战游戏
- 精美克制的界面，操作与主流游戏一致
- 持续可演进：每个版本可独立交付，可观测、可回滚

## 中期目标
- [x] 经典坦克大战核心玩法（移动、射击、碰撞、AI 敌人）
- [x] 多关卡地图系统
- [x] 道具系统（加速、护盾、火力增强）
- [ ] 音效与背景音乐
- [ ] 排行榜与成就系统
- [ ] 自适应布局（折叠屏/平板/桌面）

## 短期目标
- 持续按 prompt.md 的版本节奏：新功能 → patch 修复 → patch 重构

---

## 版本历史

### v0.1.1 (PATCH)
- **状态**: 开发中 🚧
- **目标**: 修复 GitHub Actions CI 类型检查报错
- **任务**:
  - [x] 修复 `game_engine.dart` 中 `enemySpawnTimer` 类型不匹配（int → double）
  - [x] 修复 `game_engine.dart` 中 `clamp` 返回值类型转换
  - [x] 版本号更新至 0.1.1

### v0.1.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 首个版本：坦克大战最小可用集
- **任务**:
  - [x] 项目脚手架（pubspec/analysis_options/.gitignore）
  - [x] Android 平台文件（manifest、build.gradle、签名、minSdk=34/targetSdk=36/compileSdk=36）
  - [x] 主题（Material 3 浅/深色、Windows YaHei UI、克制扁平风）
  - [x] 数据模型（Tank、Bullet、Map、GameState）
  - [x] 服务层：日志、文件系统、存储
  - [x] 游戏引擎（移动、射击、碰撞检测、AI 敌人）
  - [x] 状态层：GameProvider
  - [x] 界面：主页 / 游戏页 / 设置页 + 虚拟手柄
  - [x] Canvas 渲染（坦克、子弹、地图、爆炸效果）
  - [x] 单元测试
  - [x] GitHub Actions：lint + 单测 + Android APK + Windows ZIP + tag 自动 release
  - [x] README/plan

---

## 设计原则
- **离线优先**：所有数据来自本地，不联网。
- **可观测**：所有关键操作都写入日志文件，方便排障。
- **包体克制**：当前依赖均为成熟稳定的纯 Dart / Flutter 插件，避免引入大型原生 SDK。

## 依赖与版本基线
- Flutter: 3.44.1
- provider: 6.1.5+1
- window_manager: 0.5.1
- shared_preferences: 2.5.5
- path_provider: 2.1.5
- path: 1.9.1
