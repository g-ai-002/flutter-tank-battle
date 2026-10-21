import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tank_battle/models/game_enums.dart';
import 'package:flutter_tank_battle/widgets/virtual_joystick.dart';

VirtualJoystick _buildJoystick({
  void Function(Direction dir)? onMoveStart,
  void Function(Direction dir)? onMoveEnd,
}) {
  return VirtualJoystick(
    onMoveStart: onMoveStart ?? (_) {},
    onMoveEnd: onMoveEnd ?? (_) {},
  );
}

// 触控区铺满 body：测试视口默认 800x600，空闲锚点在左下角 (91, 509)
Widget _wrapJoystick(VirtualJoystick joystick) {
  return MaterialApp(home: Scaffold(body: joystick));
}

Widget _wrapShootButton(VoidCallback onShoot) {
  return MaterialApp(
    home: Scaffold(body: Center(child: ShootButton(onShoot: onShoot))),
  );
}

void main() {
  testWidgets('死区内拖动不触发移动', (tester) async {
    final started = <Direction>[];
    final ended = <Direction>[];
    await tester.pumpWidget(
      _wrapJoystick(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
    );

    final base = tester.getCenter(find.byKey(const Key('joystick_base')));
    final gesture = await tester.startGesture(base);
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();

    expect(started, isEmpty);
    expect(ended, isEmpty);

    await gesture.up();
  });

  testWidgets('拖动触发方向,不松手可切换,拖回死区回中', (tester) async {
    final started = <Direction>[];
    final ended = <Direction>[];
    await tester.pumpWidget(
      _wrapJoystick(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
    );

    final base = tester.getCenter(find.byKey(const Key('joystick_base')));
    final gesture = await tester.startGesture(base);
    await tester.pump();
    expect(started, isEmpty);

    // 向右拖过死区
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(started, [Direction.right]);
    expect(ended, isEmpty);

    // 不松手滑向下方:先停右再按下
    await gesture.moveBy(const Offset(-30, 38));
    await tester.pump();
    expect(started, [Direction.right, Direction.down]);
    expect(ended, [Direction.right]);

    // 拖回死区视为回中
    await gesture.moveBy(const Offset(0, -38));
    await tester.pump();
    expect(started, [Direction.right, Direction.down]);
    expect(ended, [Direction.right, Direction.down]);

    await gesture.up();
    await tester.pump();
    expect(started, [Direction.right, Direction.down]);
    expect(ended, [Direction.right, Direction.down]);
  });

  testWidgets('手指按下处成为底座中心,抬起后回到左下角锚点', (tester) async {
    await tester.pumpWidget(_wrapJoystick(_buildJoystick()));

    const press = Offset(200, 150);
    final gesture = await tester.startGesture(press);
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(const Key('joystick_base'))), press);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.byKey(const Key('joystick_base'))),
      const Offset(91, 509),
    );
  });

  testWidgets('按在触控区边缘,底座钳制在区域内且立即触发方向', (tester) async {
    final started = <Direction>[];
    final ended = <Direction>[];
    await tester.pumpWidget(
      _wrapJoystick(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
    );

    // 按在左下角:底座中心钳制到 (75, 525),把手朝手指方向贴边 → 向左
    final gesture = await tester.startGesture(const Offset(10, 560));
    await tester.pumpAndSettle();
    expect(started, [Direction.left]);
    expect(
      tester.getCenter(find.byKey(const Key('joystick_base'))),
      const Offset(75, 525),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(ended, [Direction.left]);
  });

  testWidgets('组件销毁时释放按住的方向', (tester) async {
    final started = <Direction>[];
    final ended = <Direction>[];
    await tester.pumpWidget(
      _wrapJoystick(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
    );

    final anchor = tester.getCenter(find.byKey(const Key('joystick_base')));
    final gesture = await tester.startGesture(anchor);
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(started, [Direction.up]);

    // 换成不同类型 widget 迫使摇杆 State 销毁
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(ended, [Direction.up]);

    await gesture.up();
  });

  testWidgets('组件销毁后迟到的移动/抬起事件不触发回调', (tester) async {
    final started = <Direction>[];
    final ended = <Direction>[];
    await tester.pumpWidget(
      _wrapJoystick(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
    );

    final anchor = tester.getCenter(find.byKey(const Key('joystick_base')));
    final gesture = await tester.startGesture(anchor);
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(started, [Direction.up]);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(ended, [Direction.up]);

    // 销毁后到达的移动/抬起事件沿旧命中链派发，应被静默忽略
    await gesture.moveBy(const Offset(0, -60));
    await gesture.up();
    expect(started, [Direction.up]);
    expect(ended, [Direction.up]);
  });

  testWidgets('点击射击按钮触发射击回调', (tester) async {
    var shots = 0;
    await tester.pumpWidget(_wrapShootButton(() => shots++));

    await tester.tap(find.byKey(const Key('shoot_button')));
    await tester.pump();
    expect(shots, 1);
  });

  testWidgets('射击按钮为 96x96', (tester) async {
    await tester.pumpWidget(_wrapShootButton(() {}));

    final button = tester.getSize(find.byKey(const Key('shoot_button')));
    expect(button.width, 96);
    expect(button.height, 96);
  });

  testWidgets('按下射击按钮缩放反馈,抬起恢复并触发射击', (tester) async {
    var shots = 0;
    await tester.pumpWidget(_wrapShootButton(() => shots++));

    double scaleOf() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    expect(scaleOf(), 1.0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('shoot_button'))),
    );
    await tester.pump();
    expect(scaleOf(), 0.85);

    await gesture.up();
    await tester.pump();
    expect(scaleOf(), 1.0);
    expect(shots, 1);
  });
}
