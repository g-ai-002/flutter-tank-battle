import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_enums.dart';
import '../providers/game_provider.dart';
import '../widgets/game_renderer.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_overlay.dart';
import '../widgets/virtual_joystick.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startGame();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final game = context.read<GameProvider>();
    final s = game.state;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        game.movePlayer(Direction.up);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        game.movePlayer(Direction.down);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        game.movePlayer(Direction.left);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        game.movePlayer(Direction.right);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        game.playerShoot();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyP:
        if (s.status == GameStatus.playing) {
          game.pauseGame();
        } else if (s.status == GameStatus.paused) {
          game.resumeGame();
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final s = game.state;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('坦克大战', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              game.pauseGame();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出游戏'),
                  content: const Text('确定要退出当前游戏吗？'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        game.resumeGame();
                      },
                      child: const Text('继续游戏'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('退出'),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(s.status == GameStatus.paused ? Icons.play_arrow : Icons.pause),
              onPressed: () {
                if (s.status == GameStatus.playing) {
                  game.pauseGame();
                } else if (s.status == GameStatus.paused) {
                  game.resumeGame();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            GameHUD(state: s, highScore: game.highScore),
            Expanded(
              child: Stack(
                children: [
                  GameRenderer(state: s),
                  if (s.status == GameStatus.paused)
                    GameOverlay(title: '游戏暂停', subtitle: '按 P 键或点击继续', onTap: () => game.resumeGame()),
                  if (s.status == GameStatus.gameOver)
                    GameOverlay(title: '游戏结束', subtitle: '得分: ${s.score}', onTap: () => Navigator.pop(context)),
                  if (s.status == GameStatus.levelComplete)
                    GameOverlay(title: '第 ${s.level} 关通过!', subtitle: '得分: ${s.score}', onTap: () => game.nextLevel()),
                  if (s.status == GameStatus.victory)
                    GameOverlay(title: '恭喜通关!', subtitle: '最终得分: ${s.score}', onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)
              VirtualJoystick(
                onMove: (dir) => game.movePlayer(dir),
                onShoot: () => game.playerShoot(),
              ),
          ],
        ),
      ),
    );
  }
}