# 坦克大战

经典坦克大战 Flutter 复刻版，支持 Android 和 Windows 双平台。

## 功能特性

- 🎮 经典坦克大战核心玩法：移动、射击、碰撞检测
- 🤖 AI 敌人：自动寻路与射击
- 🗺️ 多关卡地图：砖墙、钢铁、水域、基地
- 💎 道具系统：护盾、加速、火力增强
- 🎨 Material 3 设计：浅色/深色主题
- 📱 跨平台：Android + Windows
- 🕹️ 虚拟手柄：移动端触屏操作
- ⌨️ 键盘操作：桌面端 WASD + 空格

## 操作说明

| 操作 | 桌面端 | 移动端 |
|------|--------|--------|
| 移动 | 方向键 / WASD | 虚拟方向键 |
| 射击 | 空格键 | 射击按钮 |
| 暂停 | P 键 | 顶部暂停按钮 |

## 游戏规则

- 消灭所有敌方坦克即可过关
- 保护基地（底部中央黄色区域）不被摧毁
- 拾取道具获得临时增益效果
- 共 5 关，全部通过即为胜利

## 下载

- [GitHub Releases](https://github.com/g-ai-002/flutter-tank-battle/releases)

## 开发

```bash
# 安装依赖
flutter pub get

# 运行测试
flutter test

# 运行应用
flutter run
```

## 技术栈

- Flutter 3.44.1
- Provider 状态管理
- Material 3 设计系统
- CustomPainter 游戏渲染
