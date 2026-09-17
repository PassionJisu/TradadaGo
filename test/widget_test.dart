import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:foodridge/screens/community_screen.dart';
import 'package:foodridge/screens/login_screen.dart';
import 'package:foodridge/screens/my_page_screen.dart';
import 'package:foodridge/state/app_session.dart';
import 'package:foodridge/widgets/tradada_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Login screen shows Tradada branding', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.textContaining('트라다다'), findsWidgets);
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
    expect(find.text('가게로 이동'), findsOneWidget);
    expect(find.text('이 가게 리뷰 2개'), findsOneWidget);
    expect(find.text('양동단골'), findsOneWidget);

    await tester.tap(find.text('가게로 이동'));
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
    expect(find.text('말바우시장'), findsOneWidget);

    await tester.tap(find.text('양동시장'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0/10곳 색칠'), findsWidgets);

    AppSession.instance.addVisitStamp('yd-honguh');
    await tester.pump();
    expect(find.textContaining('1/10곳 색칠'), findsWidgets);
    expect(find.text('양동홍어타운'), findsWidgets);
  });
}

void _noop(int _) {}

