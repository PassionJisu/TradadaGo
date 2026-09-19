import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodridge/data/sangju_floor2.dart';
import 'package:foodridge/data/sangju_indoor_map.dart';
import 'package:foodridge/map/indoor_camera.dart';
import 'package:foodridge/map/market_blueprint.dart';
import 'package:foodridge/map/sangju_indoor_painter.dart';
import 'package:foodridge/models/indoor_stall.dart';
import 'package:foodridge/screens/sangju_indoor_map_screen.dart';
import 'package:foodridge/state/app_session.dart';
import 'package:foodridge/widgets/completed_indoor_plan_view.dart';
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
    expect(camera.scale, IndoorCamera.labelMinScale);
    expect(camera.minScale(view), greaterThan(400 / 2800));

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

  test('indoor stall QR does not require a map pin', () {
    final path = Path()..addRect(const Rect.fromLTWH(10, 10, 40, 40));
    final stall = IndoorStall(
      id: 'sj-test',
      name: '테스트점포',
      floor: 1,
      path: path,
      bounds: path.getBounds(),
    );
    final store = stall.asStore();
    expect(store.requireGps, isFalse);
    expect(store.qrPayload, 'TRADADAGO:sj-test');
    expect(store.products, isNotEmpty);
    expect(store.products.first.name, contains('테스트점포'));
    expect(stall.hasDiscountProducts, isTrue);
  });

  test('discount stalls get map pins', () {
    final goodsPath = Path()..addRect(const Rect.fromLTWH(0, 0, 40, 40));
    final storagePath = Path()..addRect(const Rect.fromLTWH(50, 0, 40, 40));
    final goods = IndoorStall(
      id: 'sj-goods',
      name: '잡화점',
      floor: 1,
      path: goodsPath,
      bounds: goodsPath.getBounds(),
    );
    final storage = IndoorStall(
      id: 'sj-storage',
      name: '창고',
      floor: 1,
      path: storagePath,
      bounds: storagePath.getBounds(),
      use: StallUse.storage,
    );
    final pins = SangjuIndoorPainter.pickDiscountPins(
      [goods, storage],
      scale: 1.1,
    );
    expect(goods.hasDiscountProducts, isTrue);
    expect(storage.hasDiscountProducts, isFalse);
    expect(pins.map((s) => s.id), ['sj-goods']);
  });

  test('avatar screen size follows map zoom', () {
    final camera = IndoorCamera(
      mapSize: const Size(2800, 1400),
      pad: 1200,
      focus: const Offset(2600, 1900),
    );
    camera.scale = IndoorCamera.referenceScale;
    expect(camera.avatarScreenSize(), IndoorCamera.avatarBaseSize);

    camera.scale = IndoorCamera.referenceScale * 2;
    expect(camera.avatarScreenSize(), IndoorCamera.avatarBaseSize * 2);

    camera.scale = IndoorCamera.referenceScale / 2;
    expect(camera.avatarScreenSize(), IndoorCamera.avatarBaseSize * 0.5);
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
    expect(data.stalls.where((s) => s.floor == 1).length, 184);
    expect(data.stalls.where((s) => s.floor == 2).length, SangjuFloor2.cells().length);
    expect(data.stalls, hasLength(184 + SangjuFloor2.cells().length));
    expect(data.mapSize, const Size(2800, 1400));
    expect(data.startFocus.dx, closeTo(data.pad + data.mapSize.width / 2, 0.1));
    expect(data.startFocus.dy, closeTo(data.pad + data.mapSize.height - 70, 0.1));
    expect(data.stalls.any((s) => s.name == '동성신발 백화점'), isTrue);
    expect(data.stalls.any((s) => s.name == '새마을종묘사'), isTrue);
    expect(data.stalls.any((s) => s.name == '상인교육장' && s.floor == 2), isTrue);
    final floor2Bounds = data.stalls
        .where((s) => s.floor == 2)
        .map((s) => s.bounds)
        .reduce((a, b) => a.expandToInclude(b));
    expect(floor2Bounds.width, greaterThan(2400));
    expect(floor2Bounds.height, greaterThan(1000));

    final camera = IndoorCamera(
      mapSize: data.mapSize,
      pad: data.pad,
      focus: data.startFocus,
    );
    final firstFloor = data.stallsOnFloor(1).first;
    final at = firstFloor.bounds.center;
    expect(camera.hit(at, data.stallsOnFloor(1))?.floor, 1);
    expect(camera.hit(at, data.stallsOnFloor(1))?.id, isNot(startsWith('sj-2f-')));
    expect(
      data.uniqueNamed(data.stalls).length,
      lessThan(data.stalls.length),
    );

    final overlapA = Path()..addRect(const Rect.fromLTWH(0, 0, 80, 80));
    final overlapB = Path()..addRect(const Rect.fromLTWH(10, 10, 80, 80));
    final labels = SangjuIndoorPainter.pickLabels(
      [
        IndoorStall(
          id: 'a',
          name: '가게하나',
          floor: 1,
          path: overlapA,
          bounds: overlapA.getBounds(),
        ),
        IndoorStall(
          id: 'b',
          name: '가게둘',
          floor: 1,
          path: overlapB,
          bounds: overlapB.getBounds(),
        ),
      ],
      1.2,
    );
    expect(labels, hasLength(1));

    await tester.pumpWidget(const MaterialApp(home: SangjuIndoorMapScreen()));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('시장 데모'), findsOneWidget);
    expect(find.textContaining('점포 ${data.stalls.length}곳'), findsOneWidget);
    expect(find.textContaining('캐릭터 고정'), findsOneWidget);
    expect(find.text('카테고리 선택'), findsOneWidget);
    expect(find.text('1층 선택'), findsOneWidget);
    expect(find.text('가게 정보 보기'), findsOneWidget);

    final start = tester.widget<Image>(find.byKey(const Key('indoor-avatar')));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    final zoomedIn = tester.widget<Image>(find.byKey(const Key('indoor-avatar')));
    expect(zoomedIn.width!, greaterThan(start.width!));

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    final zoomedOut = tester.widget<Image>(find.byKey(const Key('indoor-avatar')));
    expect(zoomedOut.width!, lessThan(start.width!));
  });

  testWidgets('indoor stall sheet offers QR without a map pin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndoorStallSheet(
            stall: IndoorStall(
              id: 'sj-sheet',
              name: '동성신발 백화점',
              floor: 1,
              path: Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10)),
              bounds: const Rect.fromLTWH(0, 0, 10, 10),
            ),
            verified: false,
            onScanQr: () {},
            onOpenStore: () {},
          ),
        ),
      ),
    );
    expect(find.text('QR 인증하기'), findsOneWidget);
    expect(find.text('가게·상품 자세히 보기'), findsOneWidget);
    expect(find.textContaining('마감할인'), findsWidgets);
  });

  testWidgets('completed indoor plan fits the market floor', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              CompletedIndoorPlanView(session: AppSession.instance),
            ],
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.textContaining('0/${SangjuIndoorMap.publishedStallCount}곳'), findsOneWidget);
    expect(find.text('1층 선택'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
