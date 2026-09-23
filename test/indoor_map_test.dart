import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodridge/config/assets.dart';
import 'package:foodridge/map/alley_route.dart';
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
    expect(camera.minScale(view), closeTo(400 / 2800, 0.0001));
    expect(camera.scale, lessThan(IndoorCamera.labelMinScale));

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

  test('IndoorCamera nearest lights a stall from the alley', () {
    final path = Path()..addRect(const Rect.fromLTWH(10, 10, 40, 40));
    final stall = IndoorStall(
      id: 'sj-alley',
      name: '골목옆점포',
      floor: 1,
      path: path,
      bounds: path.getBounds(),
    );
    final camera = IndoorCamera(
      mapSize: const Size(100, 100),
      pad: 0,
      focus: const Offset(30, 62),
    );
    expect(camera.hit(camera.focus, [stall]), isNull);
    expect(camera.nearest(camera.focus, [stall])?.id, 'sj-alley');
    expect(camera.nearest(const Offset(200, 200), [stall]), isNull);
  });

  test('IndoorPathWalker follows a path then stops', () {
    const route = [Offset(0, 0), Offset(10, 0), Offset(10, 10)];
    final walker = IndoorPathWalker(route);
    walker.start();
    expect(walker.position, Offset.zero);
    Offset? last;
    var steps = 0;
    while (walker.running && steps < 1000) {
      last = walker.tick(pixels: 3);
      steps += 1;
    }
    expect(walker.running, isFalse);
    expect(last, route.last);
    expect(steps, lessThan(20));
  });

  test('IndoorPathWalker pause keeps progress until resume', () {
    const route = [Offset(0, 0), Offset(100, 0)];
    final walker = IndoorPathWalker(route);
    walker.start();
    walker.tick(pixels: 20);
    final pausedAt = walker.position;
    walker.pause();
    expect(walker.paused, isTrue);
    expect(walker.walking, isFalse);
    expect(walker.tick(pixels: 20), isNull);
    expect(walker.position, pausedAt);
    walker.resume();
    expect(walker.walking, isTrue);
    walker.tick(pixels: 20);
    expect(walker.position.dx, greaterThan(pausedAt.dx));
  });

  test('food photos follow the stall name and closed shops stay closed', () {
    IndoorStall stall(String id, String name, StallUse use, {int floor = 1}) {
      final path = Path()..addRect(const Rect.fromLTWH(10, 10, 40, 40));
      return IndoorStall(
        id: id,
        name: name,
        floor: floor,
        path: path,
        bounds: path.getBounds(),
        use: use,
      );
    }

    final chicken = stall('sj-chicken', '남성통닭', StallUse.food);
    final mandu = stall('sj-mandu', '정담만두', StallUse.food);
    final banchan = stall('sj-banchan', '대성반찬', StallUse.sidedish);
    final shoes = stall('sj-shoes', '동성신발 백화점', StallUse.clothes);
    final upstairs = stall('sj-up', '2층분식', StallUse.snack, floor: 2);

    expect(chicken.asStore().products.single.imageAsset, AppAssets.foodChicken);
    expect(mandu.asStore().products.single.imageAsset, AppAssets.foodMandu);
    expect(banchan.asStore().products.single.imageAsset, AppAssets.foodJeon);
    expect(chicken.asStore().qrPayload, 'TRADADAGO:sj-chicken');
    expect(chicken.asStore().requireGps, isTrue);
    expect(chicken.asStore(qrUnlocked: true).requireGps, isFalse);
    expect(shoes.hasMenu, isFalse);
    expect(upstairs.hasMenu, isFalse);
    expect(shoes.asStore().description, contains('아직 가게 정보가 구현되지 않았습니다'));
  });

  test('discount stalls get map pins', () {
    final foodPath = Path()..addRect(const Rect.fromLTWH(0, 0, 40, 40));
    final storagePath = Path()..addRect(const Rect.fromLTWH(50, 0, 40, 40));
    final chicken = IndoorStall(
      id: 'sj-chicken',
      name: '남성통닭',
      floor: 1,
      path: foodPath,
      bounds: foodPath.getBounds(),
      use: StallUse.food,
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
      [chicken, storage],
      scale: 1.1,
    );
    expect(chicken.hasDiscountProducts, isTrue);
    expect(storage.hasDiscountProducts, isFalse);
    expect(pins.map((s) => s.id), ['sj-chicken']);
  });

  test('alley route stays on the walkway instead of cutting across stalls', () {
    const path = [
      Offset(0, 0),
      Offset(100, 0),
      Offset(100, 100),
      Offset(0, 100),
      Offset(0, 0),
    ];
    final route = alleyRoute(
      path: path,
      from: const Offset(10, -20),
      to: const Offset(90, -20),
    );
    expect(route.first, const Offset(10, -20));
    expect(route.last, const Offset(90, -20));
    expect(route.length, lessThan(6));
    for (final point in route.skip(1).take(route.length - 2)) {
      final onBottom = point.dy.abs() < 1 && point.dx >= -1 && point.dx <= 101;
      expect(onBottom, isTrue, reason: '$point left the alley');
    }

    final around = alleyRoute(
      path: path,
      from: const Offset(0, 10),
      to: const Offset(100, 90),
    );
    expect(around.length, greaterThan(3));
    final cutsCorner = around.any((point) => point.dx > 20 && point.dx < 80 && point.dy > 20 && point.dy < 80);
    expect(cutsCorner, isFalse);
  });

  test('alley route takes the shorter corridor from the current position', () {
    const path = [
      Offset(0, 0),
      Offset(0, 10),
      Offset(300, 10),
      Offset(300, 0),
      Offset(100, 0),
      Offset(100, 10),
    ];
    final route = alleyRoute(
      path: path,
      from: const Offset(0, 0),
      to: const Offset(100, 5),
    );
    expect(route.first, const Offset(0, 0));
    expect(route.last, const Offset(100, 5));
    expect(route.any((point) => point.dx > 150), isFalse);
  });

  test('panning the indoor map keeps the avatar in place', () {
    final camera = IndoorCamera(
      mapSize: const Size(2800, 1400),
      pad: 1200,
      focus: const Offset(2600, 1900),
    );
    camera.scale = 1;
    final before = camera.focus;
    camera.panByScreen(const Offset(40, 0));
    expect(camera.focus, before);
    expect(camera.isBrowsing, isTrue);
    expect(camera.viewFocus.dx, isNot(before.dx));
    camera.follow();
    expect(camera.viewFocus, before);
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
    expect(data.demoWalkPath.first, data.startFocus);
    expect(data.demoWalkPath.last, data.startFocus);
    expect(data.demoWalkPath.length, greaterThan(8));
    expect(data.stalls.any((s) => s.name == '꽃분이네'), isTrue);
    expect(data.stalls.any((s) => s.name.contains('화장실')), isTrue);
    expect(data.stalls.any((s) => s.name == '상인교육장' && s.floor == 2), isTrue);
    final discounted = data.stalls.where((s) => s.hasDiscountProducts).toList();
    expect(discounted, isNotEmpty);
    expect(discounted.every((s) => s.floor == 1 && s.use.isFood), isTrue);
    expect(discounted.any((s) => s.name.contains('만두')), isTrue);
    expect(
      data.stalls.where((s) => s.name.contains('화장실')).every((s) => !s.hasMenu),
      isTrue,
    );
    expect(data.stalls.where((s) => s.floor == 2).every((s) => !s.hasMenu), isTrue);
    final mandu = discounted.firstWhere((s) => s.name.contains('만두'));
    expect(mandu.asStore().products.single.imageAsset, AppAssets.foodMarketMandu);
    expect(mandu.asStore().products.single.reviewImageAsset, AppAssets.foodMandu);
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

    AppSession.instance.chooseDemoAvatar(DemoAvatarGender.male);
    addTearDown(() => AppSession.instance.demoAvatarGender = null);
    await tester.pumpWidget(const MaterialApp(home: SangjuIndoorMapScreen()));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('시장 데모'), findsOneWidget);
    expect(data.restaurants, isNotEmpty);
    expect(data.restaurants.every((s) => s.floor == 1 && s.use.isFood), isTrue);
    expect(data.restaurants.any((s) => s.use == StallUse.seafood), isTrue);
    expect(data.restaurants.any((s) => s.use == StallUse.produce), isTrue);
    expect(data.restaurants, hasLength(182));
    expect(
      SangjuIndoorPainter.pickDiscountPins(data.stalls, scale: 0.4, floorFilter: 1),
      hasLength(data.restaurants.length),
    );
    expect(SangjuIndoorMap.publishedStallCount, data.restaurants.length);
    expect(find.textContaining('식품 ${data.restaurants.length}곳'), findsOneWidget);
    expect(find.textContaining('캐릭터 고정'), findsOneWidget);
    expect(find.text('카테고리 선택'), findsOneWidget);
    expect(find.text('1층 선택'), findsOneWidget);
    expect(find.text('가게 정보 보기'), findsOneWidget);
    expect(find.text('골목 시연 걷기'), findsOneWidget);
    expect(find.text('색칠 0%'), findsOneWidget);
    expect(find.text('${0}/${data.restaurants.length}곳'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.byIcon(Icons.explore_outlined), findsNothing);
    expect(find.byIcon(Icons.my_location_rounded), findsNothing);

    await tester.tap(find.text('골목 시연 걷기'));
    await tester.pump();
    expect(find.text('시연 경로 정지'), findsOneWidget);
    expect(find.text('일시정지'), findsOneWidget);
    expect(find.textContaining('골목 시연 경로 이동 중'), findsOneWidget);
    await tester.tap(find.text('일시정지'));
    await tester.pump();
    expect(find.text('이어서 걷기'), findsOneWidget);
    expect(find.textContaining('골목 시연 일시정지'), findsOneWidget);
    await tester.tap(find.text('이어서 걷기'));
    await tester.pump();
    expect(find.text('일시정지'), findsOneWidget);
    expect(find.textContaining('골목 시연 경로 이동 중'), findsOneWidget);
    await tester.tap(find.text('시연 경로 정지'));
    await tester.pump();
    expect(find.text('골목 시연 걷기'), findsOneWidget);
    expect(find.text('색칠 0%'), findsOneWidget);
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
              use: StallUse.clothes,
            ),
            verified: false,
          ),
        ),
      ),
    );
    expect(find.text('아직 가게 정보가 구현되지 않았습니다.'), findsOneWidget);
    expect(find.text('QR 인증하기'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndoorStallSheet(
            stall: IndoorStall(
              id: 'sj-chicken',
              name: '남성통닭',
              floor: 1,
              path: Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10)),
              bounds: const Rect.fromLTWH(0, 0, 10, 10),
              use: StallUse.food,
            ),
            verified: false,
            qrEnabled: true,
            onScanQr: () {},
            onOpenStore: () {},
          ),
        ),
      ),
    );
    expect(find.text('QR 인증하기'), findsOneWidget);
    expect(find.text('가게·상품 자세히 보기'), findsOneWidget);
    expect(find.textContaining('통닭'), findsWidgets);
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

  testWidgets('market demo asks for an avatar the first time', (tester) async {
    AppSession.instance.demoAvatarGender = null;
    addTearDown(() => AppSession.instance.demoAvatarGender = null);

    await tester.pumpWidget(const MaterialApp(home: SangjuIndoorMapScreen()));
    await tester.pump();

    expect(find.text('남성인가요, 여성인가요?'), findsOneWidget);
    await tester.tap(find.text('여성'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(AppSession.instance.demoAvatarGender, DemoAvatarGender.female);
    expect(find.text('남성인가요, 여성인가요?'), findsNothing);
  });
}
