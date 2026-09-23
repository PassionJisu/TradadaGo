import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:foodridge/config/assets.dart';
import 'package:foodridge/data/gwangju_markets.dart';
import 'package:foodridge/screens/community_screen.dart';
import 'package:foodridge/screens/login_screen.dart';
import 'package:foodridge/screens/my_page_screen.dart';
import 'package:foodridge/screens/reservations_screen.dart';
import 'package:foodridge/data/sangju_indoor_map.dart';
import 'package:foodridge/models/reservation.dart';
import 'package:foodridge/models/store.dart';
import 'package:foodridge/state/app_session.dart';
import 'package:foodridge/widgets/tradada_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Login screen shows Tradada branding', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.textContaining('임시 관리자'), findsOneWidget);
    expect(find.text('들어가기'), findsOneWidget);
  });

  testWidgets('Bottom nav uses community label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: TradadaBottomNav(index: 2, onSelect: _noop),
        ),
      ),
    );
    expect(find.text('커뮤니티'), findsOneWidget);
    expect(find.text('이용내역'), findsOneWidget);
    expect(find.text('예약내역'), findsNothing);
    expect(find.text('리뷰 & 추천'), findsNothing);
  });

  testWidgets('Community banner switches reviews and editorial', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));
    expect(find.text('커뮤니티'), findsOneWidget);
    expect(find.text('리뷰 & 추천'), findsOneWidget);
    expect(find.text('Editorial'), findsOneWidget);
    expect(find.text('주간 추천 랭킹'), findsOneWidget);

    await tester.tap(find.text('Editorial'));
    await tester.pumpAndSettle();
    expect(find.text('이번 주 추천 루트'), findsOneWidget);
    expect(find.text('양동 맛골목 반나절'), findsOneWidget);
  });

  testWidgets('Review tap lists store reviews and opens store detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));
    await tester.tap(find.text('충장로막내').first);
    await tester.pumpAndSettle();
    expect(find.text('식당으로 이동'), findsOneWidget);
    expect(find.text('이 가게 리뷰 2개'), findsOneWidget);
    expect(find.text('양동단골'), findsOneWidget);

    await tester.tap(find.text('식당으로 이동'));
    await tester.pumpAndSettle();
    expect(find.text('마감할인 상품'), findsOneWidget);
    expect(find.text('홍어모둠 마감세트'), findsOneWidget);
  });

  testWidgets('My page lists markets then paints a visited store on the plan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MyPageScreen()));
    await tester.pump();
    expect(find.text('내가 완성한 지도'), findsOneWidget);

    await tester.tap(find.text('내가 완성한 지도'));
    await tester.pumpAndSettle();
    expect(find.text('양동시장'), findsOneWidget);
    expect(find.text('대인시장'), findsOneWidget);
    expect(find.text('시장 데모'), findsOneWidget);
    expect(find.textContaining('0/12곳 색칠'), findsWidgets);
    expect(find.textContaining('0/${SangjuIndoorMap.publishedStallCount}곳 색칠'), findsOneWidget);

    await tester.tap(find.text('양동시장'));
    await tester.pumpAndSettle();
    expect(find.text('양동시장'), findsWidgets);
  });

  void _reserve(Store store) {
    final product = store.products.first;
    AppSession.instance.reserveFoods(
      store: store,
      items: [
        ReservedItem(
          name: product.name,
          unitPrice: product.discountPrice,
          quantity: 2,
        ),
      ],
    );
  }

  testWidgets('QR visit appears in usage history with review', (tester) async {
    final store = GwangjuMarkets.yangdong.stores.first;
    _reserve(store);
    expect(AppSession.instance.markQrVerified(store), isTrue);
    _reserve(store);
    expect(AppSession.instance.markQrVerified(store), isTrue);

    await tester.pumpWidget(const MaterialApp(home: ReservationsScreen()));
    expect(find.text('이용내역'), findsOneWidget);
    expect(find.text(store.name), findsNWidgets(2));
    expect(find.textContaining('QR 수령 완료'), findsNWidgets(2));
    expect(find.textContaining('× 2'), findsWidgets);
    expect(find.text('포토 리뷰 쓰기'), findsNWidgets(2));
    expect(find.text('포토 리뷰 더 남기기'), findsNothing);
    expect(find.textContaining(AppSession.instance.reservations.first.timeLabel), findsWidgets);
    expect(find.textContaining('아직 이용 내역이 없습니다'), findsNothing);
  });

  testWidgets('usage history opens a written review', (tester) async {
    final store = GwangjuMarkets.yangdong.stores.first;
    _reserve(store);
    expect(AppSession.instance.markQrVerified(store), isTrue);
    final visit = AppSession.instance.unreviewedQrVisit(store.id)!;
    AppSession.instance.addPhotoReview(
      store: store,
      body: '이용내역에서 다시 보는 포토 리뷰입니다.',
      photoAsset: AppAssets.foodHonguh,
      visitId: visit.id,
    );

    await tester.pumpWidget(const MaterialApp(home: ReservationsScreen()));
    expect(find.text('작성한 리뷰 보기'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);

    await tester.tap(find.text('작성한 리뷰 보기'));
    await tester.pumpAndSettle();
    expect(find.text('작성한 리뷰'), findsOneWidget);
    expect(find.text('이용내역에서 다시 보는 포토 리뷰입니다.'), findsOneWidget);
  });
}

void _noop(int _) {}

