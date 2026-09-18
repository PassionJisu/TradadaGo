import 'package:flutter/material.dart';

import '../config/assets.dart';
import '../map/market_blueprint.dart';
import '../models/market.dart';

/// 데모용 넓은 조감도. 격자 대신 실제 시장처럼 골목을 끼고 구역이 모인다.
abstract final class MarketBlueprints {
  static const canvas = Size(1152, 864);

  static MarketBlueprint? forMarket(Market market) {
    if (market.id == 'yangdong') return yangdong;
    return null;
  }

  static MarketBlueprint get yangdong => MarketBlueprint(
    marketId: 'yangdong',
    canvas: canvas,
    focus: const Rect.fromLTWH(0, 0, 1152, 864),
    floors: [_yangdongSecond, _yangdongFirst, _yangdongBasement],
  );

  /// 정문 → 간식 → 반찬 → 먹거리 3곳 → 정육 → 수산 2곳 → 청과 → 정문.
  /// GPS 경로와 점 개수·순서를 같게 맞춰 핀이 아바타와 같이 켜지게 한다.
  static const _walk = <Offset>[
    Offset(576, 800),
    Offset(576, 700),
    Offset(900, 650),
    Offset(576, 600),
    Offset(250, 510),
    Offset(576, 470),
    Offset(860, 360),
    Offset(990, 410),
    Offset(880, 490),
    Offset(250, 330),
    Offset(200, 155),
    Offset(360, 155),
    Offset(900, 155),
    Offset(576, 800),
  ];

  static final _yangdongFirst = MarketFloor(
    id: 'f1',
    label: '1층',
    caption: '수산 · 청과 · 먹거리 골목',
    isGpsFloor: true,
    backgroundAsset: AppAssets.yangdongFloor1,
    route: _walk,
    labels: const [
      MapLabel(at: Offset(230, 48), text: '수산 · 건어물', color: Color(0xFF2B6EA8), fontSize: 20),
      MapLabel(at: Offset(920, 48), text: '청과 · 채소', color: Color(0xFF2E8A4A), fontSize: 20),
      MapLabel(at: Offset(230, 248), text: '정육 · 축산', color: Color(0xFFC44B5E), fontSize: 20),
      MapLabel(at: Offset(930, 248), text: '먹거리 골목', color: Color(0xFFD06A12), fontSize: 20),
      MapLabel(at: Offset(230, 430), text: '반찬 · 떡', color: Color(0xFF148F80), fontSize: 20),
      MapLabel(at: Offset(200, 600), text: '잡화 · 생활', color: Color(0xFF6B4E9B), fontSize: 20),
      MapLabel(at: Offset(920, 540), text: '간식 · 길거리', color: Color(0xFFC48A12), fontSize: 20),
    ],
    blocks: [
      MarketBlock(
        name: '수산 · 건어물',
        rect: const Rect.fromLTWH(48, 48, 400, 190),
        theme: StallUse.seafood,
        stalls: placeRow(
          theme: StallUse.seafood,
          left: 70,
          top: 118,
          width: 360,
          height: 78,
          stalls: const [
            StallSpec('영광굴비'),
            StallSpec('양동홍어타운', storeId: 'yd-honguh'),
            StallSpec('싱싱수산', storeId: 'yd-susan'),
            StallSpec('통영멸치', use: StallUse.dried),
          ],
        ),
      ),
      MarketBlock(
        name: '청과 · 채소',
        rect: const Rect.fromLTWH(720, 48, 400, 190),
        theme: StallUse.produce,
        stalls: placeRow(
          theme: StallUse.produce,
          left: 750,
          top: 118,
          width: 350,
          height: 78,
          stalls: const [
            StallSpec('나주배상회'),
            StallSpec('햇살과일', storeId: 'yd-fruit'),
            StallSpec('텃밭채소'),
            StallSpec('화순버섯'),
          ],
        ),
      ),
      MarketBlock(
        name: '정육 · 축산',
        rect: const Rect.fromLTWH(48, 258, 400, 150),
        theme: StallUse.meat,
        stalls: placeRow(
          theme: StallUse.meat,
          left: 70,
          top: 292,
          width: 360,
          height: 78,
          stalls: const [
            StallSpec('빛고을육회', storeId: 'yd-yukhoe'),
            StallSpec('한우정육'),
            StallSpec('양동닭전'),
            StallSpec('삼겹살상회'),
          ],
        ),
      ),
      MarketBlock(
        name: '먹거리 골목',
        rect: const Rect.fromLTWH(700, 258, 420, 270),
        theme: StallUse.food,
        stalls: [
          ...placeColumn(
            theme: StallUse.food,
            left: 760,
            top: 290,
            width: 88,
            height: 200,
            stalls: const [
              StallSpec('천변국밥', storeId: 'yd-gukbap'),
              StallSpec('해물칼국수'),
              StallSpec('보리밥집'),
            ],
          ),
          ...placeRow(
            theme: StallUse.food,
            left: 860,
            top: 430,
            width: 230,
            height: 70,
            stalls: const [
              StallSpec('양동김밥명가', storeId: 'yd-gimbap'),
              StallSpec('할머니전집', storeId: 'yd-jeon'),
              StallSpec('순대곱창'),
            ],
          ),
        ],
      ),
      MarketBlock(
        name: '반찬 · 떡',
        rect: const Rect.fromLTWH(48, 430, 400, 150),
        theme: StallUse.sidedish,
        stalls: placeRow(
          theme: StallUse.sidedish,
          left: 70,
          top: 468,
          width: 360,
          height: 72,
          stalls: const [
            StallSpec('양동떡집', storeId: 'yd-tteok', use: StallUse.riceCake),
            StallSpec('손맛반찬'),
            StallSpec('김치명가'),
          ],
        ),
      ),
      MarketBlock(
        name: '잡화 · 생활',
        rect: const Rect.fromLTWH(40, 600, 360, 150),
        theme: StallUse.goods,
        stalls: placeRow(
          theme: StallUse.goods,
          left: 58,
          top: 648,
          width: 320,
          height: 70,
          stalls: const [
            StallSpec('그릇도매', use: StallUse.kitchen),
            StallSpec('이불상회'),
            StallSpec('철물점'),
          ],
        ),
      ),
      MarketBlock(
        name: '간식 · 길거리',
        rect: const Rect.fromLTWH(720, 548, 400, 200),
        theme: StallUse.snack,
        stalls: placeRow(
          theme: StallUse.snack,
          left: 750,
          top: 610,
          width: 350,
          height: 78,
          stalls: const [
            StallSpec('밤마실군밤', storeId: 'yd-gunbam'),
            StallSpec('호떡수레'),
            StallSpec('꽈배기'),
            StallSpec('어묵바'),
          ],
        ),
      ),
    ],
  );

  static final _yangdongSecond = MarketFloor(
    id: 'f2',
    label: '2층',
    caption: '의류 · 침구 · 그릇 · 2층 먹거리',
    backgroundAsset: AppAssets.yangdongFloor2,
    labels: const [
      MapLabel(at: Offset(250, 40), text: '의류 · 한복', color: Color(0xFF8A4EA8), fontSize: 20),
      MapLabel(at: Offset(900, 40), text: '침구 · 커튼', color: Color(0xFF6B5BB0), fontSize: 20),
      MapLabel(at: Offset(250, 470), text: '그릇 · 주방', color: Color(0xFF3D6BB8), fontSize: 20),
      MapLabel(at: Offset(900, 470), text: '2층 먹거리', color: Color(0xFFD06A12), fontSize: 20),
    ],
    blocks: [
      MarketBlock(
        name: '의류 · 한복',
        rect: const Rect.fromLTWH(40, 40, 500, 380),
        theme: StallUse.clothes,
        stalls: placeRow(
          theme: StallUse.clothes,
          left: 70,
          top: 160,
          width: 430,
          height: 90,
          stalls: const [
            StallSpec('고운한복', storeId: 'yd-hanbok'),
            StallSpec('양동주단'),
            StallSpec('개량한복'),
            StallSpec('생활한복'),
            StallSpec('수선방'),
          ],
        ),
      ),
      MarketBlock(
        name: '침구 · 커튼',
        rect: const Rect.fromLTWH(640, 40, 480, 380),
        theme: StallUse.goods,
        stalls: placeRow(
          theme: StallUse.goods,
          left: 680,
          top: 160,
          width: 410,
          height: 90,
          stalls: const [
            StallSpec('양동이불'),
            StallSpec('커튼공방'),
            StallSpec('혼수이불'),
            StallSpec('한실침구'),
          ],
        ),
      ),
      MarketBlock(
        name: '그릇 · 주방',
        rect: const Rect.fromLTWH(40, 480, 500, 330),
        theme: StallUse.kitchen,
        stalls: placeRow(
          theme: StallUse.kitchen,
          left: 70,
          top: 560,
          width: 430,
          height: 90,
          stalls: const [
            StallSpec('놋그릇방'),
            StallSpec('업소용그릇'),
            StallSpec('무등도자기'),
            StallSpec('칼갈이집'),
          ],
        ),
      ),
      MarketBlock(
        name: '2층 먹거리',
        rect: const Rect.fromLTWH(640, 480, 480, 330),
        theme: StallUse.food,
        stalls: placeRow(
          theme: StallUse.food,
          left: 680,
          top: 560,
          width: 410,
          height: 90,
          stalls: const [
            StallSpec('손칼국수'),
            StallSpec('비빔밥집'),
            StallSpec('전통차방'),
            StallSpec('찐빵집', use: StallUse.snack),
          ],
        ),
      ),
    ],
  );

  static final _yangdongBasement = MarketFloor(
    id: 'b1',
    label: '지하',
    caption: '공영주차장 · 창고 · 식자재',
    backgroundAsset: AppAssets.yangdongFloorB1,
    labels: const [
      MapLabel(at: Offset(576, 36), text: '공영주차장', color: Color(0xFF5A6A7A), fontSize: 22),
      MapLabel(at: Offset(250, 500), text: '상인 창고', color: Color(0xFF8A6A4A), fontSize: 20),
      MapLabel(at: Offset(900, 500), text: '식자재 상회', color: Color(0xFF2E8A4A), fontSize: 20),
    ],
    blocks: [
      MarketBlock(
        name: '상인 창고',
        rect: const Rect.fromLTWH(40, 510, 500, 310),
        theme: StallUse.storage,
        stalls: placeRow(
          theme: StallUse.storage,
          left: 70,
          top: 600,
          width: 430,
          height: 90,
          stalls: const [
            StallSpec('창고 A'),
            StallSpec('창고 B'),
            StallSpec('냉장창고'),
            StallSpec('빈 창고', use: StallUse.vacant),
          ],
        ),
      ),
      MarketBlock(
        name: '식자재 상회',
        rect: const Rect.fromLTWH(640, 510, 480, 310),
        theme: StallUse.produce,
        stalls: placeRow(
          theme: StallUse.produce,
          left: 680,
          top: 600,
          width: 410,
          height: 90,
          stalls: const [
            StallSpec('대성식자재'),
            StallSpec('건어물도매', use: StallUse.dried),
            StallSpec('양념도매'),
            StallSpec('포장자재', use: StallUse.goods),
          ],
        ),
      ),
    ],
  );
}
