import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tank_battle/models/game_enums.dart';
import 'package:flutter_tank_battle/widgets/virtual_joystick.dart';

VirtualJoystick _buildJoystick({
  void Function(Direction dir)? onMoveStart,
  void Function(Direction dir)? onMoveEnd,
  VoidCallback? onShoot,
}) {
  return VirtualJoystick(
    onMoveStart: onMoveStart ?? (_) {},
    onMoveEnd: onMoveEnd ?? (_) {},
    onShoot: onShoot ?? () {},
  );
}

Widget _wrap(VirtualJoystick joystick) {
  return MaterialApp(home: Scaffold(body: joystick));
}

void main() {
  testWidgets('死区内拖动不触发移动', (tester) async {
    final started = <Direction>[];
    final ended = <Direction>[];
    await tester.pumpWidget(
      _wrap(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
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
      _wrap(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
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

  testWidgets('按在底座边缘立即触发方向,抬起后停止', (tester) async {
    final started = <Direction>[];
    final ended = <Direction>[];
    await tester.pumpWidget(
      _wrap(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
    );

    final base = tester.getCenter(find.byKey(const Key('joystick_base')));
    final gesture = await tester.startGesture(base.translate(60, 0));
    await tester.pump();
    expect(started, [Direction.right]);

    await gesture.up();
    await tester.pump();
    expect(ended, [Direction.right]);
  });

  testWidgets('组件销毁时释放按住的方向', (tester) async {
    final started = <Direction>[];
    final ended = <Direction>[];
    await tester.pumpWidget(
      _wrap(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
    );

    final base = tester.getCenter(find.byKey(const Key('joystick_base')));
    final gesture = await tester.startGesture(base.translate(0, -60));
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
      _wrap(_buildJoystick(onMoveStart: started.add, onMoveEnd: ended.add)),
    );

    final base = tester.getCenter(find.byKey(const Key('joystick_base')));
    final gesture = await tester.startGesture(base.translate(0, -60));
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
    await tester.pumpWidget(
      _wrap(_buildJoystick(onShoot: () => shots++)),
    );

    await tester.tap(find.byKey(const Key('shoot_button')));
    await tester.pump();
    expect(shots, 1);
  });

  testWidgets('射击按钮为 96x96,圆心与摇杆底座圆心同高', (tester) async {
    await tester.pumpWidget(_wrap(_buildJoystick()));

    final button = tester.getSize(find.byKey(const Key('shoot_button')));
    expect(button.width, 96);
    expect(button.height, 96);

    final baseCenter = tester.getCenter(find.byKey(const Key('joystick_base')));
    final shootCenter = tester.getCenter(find.byKey(const Key('shoot_button')));
    expect(shootCenter.dy, moreOrLessEquals(baseCenter.dy, epsilon: 0.01));
  });

  testWidgets('按下射击按钮缩放反馈,抬起恢复并触发射击', (tester) async {
    var shots = 0;
    await tester.pumpWidget(_wrap(_buildJoystick(onShoot: () => shots++)));

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
