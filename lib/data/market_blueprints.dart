import 'package:flutter/material.dart';

import '../map/market_blueprint.dart';
import '../models/market.dart';

/// 점포안내도처럼 동(A~O)과 골목만으로 짠 데모 평면도.
/// 배경 사진은 쓰지 않고, 길은 동 사이를 지나도록만 둔다.
abstract final class MarketBlueprints {
  static const canvas = Size(1200, 960);

  static MarketBlueprint? forMarket(Market market) {
    if (market.id == 'yangdong') return yangdong;
    return null;
  }

  static MarketBlueprint get yangdong => MarketBlueprint(
    marketId: 'yangdong',
    canvas: canvas,
    focus: const Rect.fromLTWH(20, 20, 1160, 920),
    floors: [_yangdongSecond, _yangdongFirst, _yangdongBasement],
  );

  /// 정문 → 간식 → 반찬 → 먹거리 → 수산 → 청과 → 정육 → 정문.
  /// 모든 점은 가로·세로 골목 중심선 위에만 둔다.
  static const walk = <Offset>[
    Offset(600, 910),
    Offset(600, 868),
    Offset(732, 868),
    Offset(732, 596),
    Offset(844, 596),
    Offset(620, 596),
    Offset(396, 596),
    Offset(284, 596),
    Offset(284, 188),
    Offset(284, 324),
    Offset(396, 324),
    Offset(620, 324),
    Offset(844, 324),
    Offset(732, 324),
    Offset(732, 868),
    Offset(600, 868),
    Offset(600, 910),
  ];

  static final _yangdongFirst = MarketFloor(
    id: 'f1',
    label: '1층',
    caption: '동을 누르면 확대됩니다 · 리뷰하면 가게가 색칠됩니다',
    isGpsFloor: true,
    route: walk,
    streets: _Mall.streets,
    facilities: const [
      Facility(
        rect: Rect.fromLTWH(548, 888, 104, 44),
        label: '정문',
        kind: FacilityKind.gate,
      ),
      Facility(
        rect: Rect.fromLTWH(548, 18, 104, 36),
        label: '후문',
        kind: FacilityKind.gate,
      ),
      Facility(
        rect: Rect.fromLTWH(16, 400, 44, 70),
        label: '화장실',
        kind: FacilityKind.restroom,
      ),
      Facility(
        rect: Rect.fromLTWH(1140, 400, 44, 70),
        label: '화장실',
        kind: FacilityKind.restroom,
      ),
      Facility(
        rect: Rect.fromLTWH(1088, 888, 88, 44),
        label: '주차',
        kind: FacilityKind.parking,
      ),
      Facility(
        rect: Rect.fromLTWH(16, 888, 88, 44),
        label: '안내',
        kind: FacilityKind.info,
      ),
    ],
    labels: const [
      MapLabel(
        at: Offset(600, 8),
        text: '양동시장 점포안내도',
        color: Color(0xFF1F4E79),
        fontSize: 18,
      ),
    ],
    blocks: [
      _wing(
        col: 1,
        row: 0,
        code: 'A동',
        name: '수산',
        theme: StallUse.seafood,
        columns: 2,
        stalls: const [
          StallSpec('영광굴비', use: StallUse.dried, storeId: 'yd-gulbi'),
          StallSpec('통영멸치', use: StallUse.dried, storeId: 'yd-myeolchi'),
          StallSpec('양동홍어타운', storeId: 'yd-honguh'),
          StallSpec('싱싱수산', storeId: 'yd-susan'),
        ],
      ),
      _wing(
        col: 2,
        row: 0,
        code: 'B동',
        name: '청과',
        theme: StallUse.produce,
        columns: 2,
        stalls: const [
          StallSpec('나주배상회'),
          StallSpec('텃밭채소'),
          StallSpec('햇살과일', storeId: 'yd-fruit'),
          StallSpec('화순버섯'),
        ],
      ),
      _wing(
        col: 3,
        row: 0,
        code: 'C동',
        name: '정육',
        theme: StallUse.meat,
        columns: 2,
        stalls: const [
          StallSpec('한우정육'),
          StallSpec('양동닭전'),
          StallSpec('빛고을육회', storeId: 'yd-yukhoe'),
          StallSpec('삼겹살상회'),
        ],
      ),
      _wing(
        col: 1,
        row: 1,
        code: 'D동',
        name: '먹거리',
        theme: StallUse.food,
        columns: 3,
        headerHeight: 118,
        stalls: const [
          StallSpec('천변국밥', storeId: 'yd-gukbap'),
          StallSpec('양동김밥명가', storeId: 'yd-gimbap'),
          StallSpec('할머니전집', storeId: 'yd-jeon'),
        ],
      ),
      _wing(
        col: 2,
        row: 1,
        code: 'E동',
        name: '반찬',
        theme: StallUse.sidedish,
        columns: 2,
        stalls: const [
          StallSpec('손맛반찬'),
          StallSpec('김치명가'),
          StallSpec('양동떡집', storeId: 'yd-tteok', use: StallUse.riceCake),
          StallSpec('장아찌집'),
        ],
      ),
      _wing(
        col: 3,
        row: 1,
        code: 'F동',
        name: '간식',
        theme: StallUse.snack,
        columns: 2,
        stalls: const [
          StallSpec('호떡수레'),
          StallSpec('꽈배기'),
          StallSpec('밤마실군밤', storeId: 'yd-gunbam'),
          StallSpec('어묵바'),
        ],
      ),
      _wing(
        col: 0,
        row: 0,
        code: 'M동',
        name: '기타',
        theme: StallUse.goods,
        columns: 2,
        stalls: const [
          StallSpec('열쇠수리'),
          StallSpec('시계집'),
          StallSpec('구두수선'),
          StallSpec('빈 점포', use: StallUse.vacant),
        ],
      ),
      _wing(
        col: 4,
        row: 0,
        code: 'J동',
        name: '건어물',
        theme: StallUse.dried,
        columns: 2,
        stalls: const [
          StallSpec('굴비도매'),
          StallSpec('멸치상회'),
          StallSpec('황태덕장'),
          StallSpec('다시마집'),
        ],
      ),
      _wing(
        col: 0,
        row: 1,
        code: 'N동',
        name: '안내',
        theme: StallUse.service,
        columns: 2,
        stalls: const [
          StallSpec('상인회'),
          StallSpec('고객안내'),
          StallSpec('분실물'),
          StallSpec('방송실'),
        ],
      ),
      _wing(
        col: 4,
        row: 1,
        code: 'K동',
        name: '떡',
        theme: StallUse.riceCake,
        columns: 2,
        stalls: const [
          StallSpec('인절미집'),
          StallSpec('한과상회'),
          StallSpec('찹쌀떡'),
          StallSpec('약과방'),
        ],
      ),
      _wing(
        col: 0,
        row: 2,
        code: 'O동',
        name: '수선',
        theme: StallUse.clothes,
        columns: 2,
        stalls: const [
          StallSpec('옷수선'),
          StallSpec('이불솜'),
          StallSpec('커튼집'),
          StallSpec('빈 점포', use: StallUse.vacant),
        ],
      ),
      _wing(
        col: 1,
        row: 2,
        code: 'G동',
        name: '잡화',
        theme: StallUse.goods,
        columns: 2,
        stalls: const [
          StallSpec('그릇도매', use: StallUse.kitchen),
          StallSpec('이불상회'),
          StallSpec('철물점'),
          StallSpec('문구사'),
        ],
      ),
      _wing(
        col: 2,
        row: 2,
        code: 'H동',
        name: '생활',
        theme: StallUse.kitchen,
        columns: 2,
        stalls: const [
          StallSpec('플라스틱'),
          StallSpec('바구니'),
          StallSpec('포장재'),
          StallSpec('생활용품'),
        ],
      ),
      _wing(
        col: 3,
        row: 2,
        code: 'I동',
        name: '분식',
        theme: StallUse.food,
        columns: 2,
        stalls: const [
          StallSpec('순대곱창'),
          StallSpec('김밥천국'),
          StallSpec('떡볶이'),
          StallSpec('어묵집'),
        ],
      ),
      _wing(
        col: 4,
        row: 2,
        code: 'L동',
        name: '길거리',
        theme: StallUse.snack,
        columns: 2,
        stalls: const [
          StallSpec('붕어빵'),
          StallSpec('군고구마'),
          StallSpec('오뎅바'),
          StallSpec('식혜집'),
        ],
      ),
    ],
  );

  static final _yangdongSecond = MarketFloor(
    id: 'f2',
    label: '2층',
    caption: '의류 · 침구 · 그릇 · 2층 먹거리',
    streets: const [
      Street(Rect.fromLTWH(80, 430, 1040, 56), label: '2층 중앙 복도'),
      Street(Rect.fromLTWH(572, 80, 56, 760)),
    ],
    facilities: const [
      Facility(
        rect: Rect.fromLTWH(548, 20, 104, 40),
        label: '계단',
        kind: FacilityKind.stairs,
      ),
      Facility(
        rect: Rect.fromLTWH(20, 430, 52, 56),
        label: '엘리베이터',
        kind: FacilityKind.elevator,
      ),
      Facility(
        rect: Rect.fromLTWH(1128, 430, 52, 56),
        label: '화장실',
        kind: FacilityKind.restroom,
      ),
    ],
    blocks: [
      buildBlock(
        id: 'f2-a',
        code: 'A동',
        name: '의류',
        theme: StallUse.clothes,
        rect: const Rect.fromLTWH(88, 80, 460, 330),
        columns: 2,
        stalls: const [
          StallSpec('고운한복', storeId: 'yd-hanbok'),
          StallSpec('양동주단'),
          StallSpec('개량한복'),
          StallSpec('생활한복'),
          StallSpec('수선방'),
          StallSpec('아동복'),
        ],
      ),
      buildBlock(
        id: 'f2-b',
        code: 'B동',
        name: '침구',
        theme: StallUse.goods,
        rect: const Rect.fromLTWH(652, 80, 460, 330),
        columns: 2,
        stalls: const [
          StallSpec('양동이불'),
          StallSpec('커튼공방'),
          StallSpec('혼수이불'),
          StallSpec('한실침구'),
        ],
      ),
      buildBlock(
        id: 'f2-c',
        code: 'C동',
        name: '그릇',
        theme: StallUse.kitchen,
        rect: const Rect.fromLTWH(88, 508, 460, 350),
        columns: 2,
        stalls: const [
          StallSpec('놋그릇방'),
          StallSpec('업소용그릇'),
          StallSpec('무등도자기'),
          StallSpec('칼갈이집'),
        ],
      ),
      buildBlock(
        id: 'f2-d',
        code: 'D동',
        name: '먹거리',
        theme: StallUse.food,
        rect: const Rect.fromLTWH(652, 508, 460, 350),
        columns: 2,
        stalls: const [
          StallSpec('손칼국수'),
          StallSpec('비빔밥집'),
          StallSpec('전통차방'),
          StallSpec('찐빵집', use: StallUse.snack),
        ],
      ),
    ],
  );

  static final _yangdongBasement = MarketFloor(
    id: 'b1',
    label: '지하',
    caption: '공영주차장 · 창고 · 식자재',
    streets: const [
      Street(Rect.fromLTWH(80, 430, 1040, 56), label: '지하 복도'),
    ],
    facilities: const [
      Facility(
        rect: Rect.fromLTWH(88, 70, 1024, 340),
        label: '공영주차장',
        kind: FacilityKind.parking,
      ),
      Facility(
        rect: Rect.fromLTWH(548, 20, 104, 40),
        label: '계단',
        kind: FacilityKind.stairs,
      ),
    ],
    blocks: [
      buildBlock(
        id: 'b1-a',
        code: 'A동',
        name: '창고',
        theme: StallUse.storage,
        rect: const Rect.fromLTWH(88, 508, 460, 350),
        columns: 2,
        stalls: const [
          StallSpec('창고 A'),
          StallSpec('창고 B'),
          StallSpec('냉장창고'),
          StallSpec('빈 창고', use: StallUse.vacant),
        ],
      ),
      buildBlock(
        id: 'b1-b',
        code: 'B동',
        name: '식자재',
        theme: StallUse.produce,
        rect: const Rect.fromLTWH(652, 508, 460, 350),
        columns: 2,
        stalls: const [
          StallSpec('대성식자재'),
          StallSpec('건어물도매', use: StallUse.dried),
          StallSpec('양념도매'),
          StallSpec('포장자재', use: StallUse.goods),
        ],
      ),
    ],
  );

  static MarketBlock _wing({
    required int col,
    required int row,
    required String code,
    required String name,
    required StallUse theme,
    required int columns,
    required List<StallSpec> stalls,
    double headerHeight = 36,
  }) {
    return buildBlock(
      id: 'f1-${code.replaceAll('동', '').toLowerCase()}',
      code: code,
      name: name,
      theme: theme,
      rect: _Mall.cell(col, row),
      columns: columns,
      headerHeight: headerHeight,
      stalls: stalls,
    );
  }
}

abstract final class _Mall {
  static const origin = Offset(88, 80);
  static const alley = 56.0;
  static const cellW = 168.0;
  static const cellH = 216.0;

  static Rect cell(int col, int row) {
    return Rect.fromLTWH(
      origin.dx + col * (cellW + alley),
      origin.dy + row * (cellH + alley),
      cellW,
      cellH,
    );
  }

  static const streets = <Street>[
    Street(Rect.fromLTWH(32, 52, 1136, 56), label: '북쪽 골목'),
    Street(Rect.fromLTWH(32, 296, 1136, 56), label: '중앙 골목'),
    Street(Rect.fromLTWH(32, 568, 1136, 56)),
    Street(Rect.fromLTWH(32, 840, 1136, 56), label: '남쪽 골목'),
    Street(Rect.fromLTWH(32, 52, 56, 844)),
    Street(Rect.fromLTWH(256, 52, 56, 844)),
    Street(Rect.fromLTWH(480, 52, 56, 844)),
    Street(Rect.fromLTWH(704, 52, 56, 844)),
    Street(Rect.fromLTWH(928, 52, 56, 844)),
    Street(Rect.fromLTWH(1152, 52, 40, 844)),
  ];
}
