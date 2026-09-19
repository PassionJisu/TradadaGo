import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodridge/data/sangju_indoor_map.dart';
import 'package:foodridge/map/indoor_camera.dart';
import 'package:foodridge/models/indoor_stall.dart';
import 'package:foodridge/screens/sangju_indoor_map_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('IndoorCamera keeps zoom inside the market bounds', () {
    final camera = IndoorCamera(
      mapSize: const Size(2800, 1400),
      pad: 1200,
      focus: const Offset(2600, 1900),
    );
    const view = Size(400, 800);
    camera.scale = 0.01;
    camera.clampScale(view);
    expect(camera.scale, camera.minScale(view));
    expect(camera.scale, closeTo(400 / 2800, 0.0001));

    camera.scale = 99;
    camera.clampScale(view);
    expect(camera.scale, IndoorCamera.maxScale);

    camera.focus = const Offset(0, 0);
    camera.clampFocus();
    expect(camera.focus.dx, greaterThan(1200));
    expect(camera.focus.dy, greaterThan(1200));
  });

  test('IndoorCamera hit-tests a stall under the character', () {
    final path = Path()..addRect(const Rect.fromLTWH(10, 10, 40, 40));
    final stall = IndoorStall(
      id: 'sj-test',
      name: '테스트점포',
      floor: 1,
      path: path,
      bounds: path.getBounds(),
    );
    final camera = IndoorCamera(
      mapSize: const Size(100, 100),
      pad: 0,
      focus: const Offset(20, 20),
    );
    expect(camera.hit(const Offset(20, 20), [stall])?.id, 'sj-test');
    expect(camera.hit(const Offset(90, 90), [stall]), isNull);
  });

  testWidgets('Sangju indoor map shows every published stall on a fixed camera', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late SangjuIndoorMap data;
    await tester.runAsync(() async {
      data = await SangjuIndoorMap.load();
    });
    expect(data.stalls, hasLength(186));
    expect(data.mapSize, const Size(2800, 1400));
    expect(data.stalls.any((s) => s.name == '동성신발 백화점'), isTrue);
    expect(data.stalls.any((s) => s.name == '새마을종묘사'), isTrue);
    expect(data.stalls.where((s) => s.floor == 2), hasLength(2));

    await tester.pumpWidget(const MaterialApp(home: SangjuIndoorMapScreen()));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('상주종합시장'), findsOneWidget);
    expect(find.textContaining('점포 186곳'), findsOneWidget);
    expect(find.textContaining('캐릭터 고정'), findsOneWidget);
  });
}
