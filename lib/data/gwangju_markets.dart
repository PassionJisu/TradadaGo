import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../config/assets.dart';
import '../models/market.dart';
import '../models/product.dart';
import '../models/store.dart';

abstract final class GwangjuMarkets {
  static const cityCenter = NLatLng(35.1595, 126.9108);

  static const cityBounds = NLatLngBounds(
    southWest: NLatLng(35.10, 126.82),
    northEast: NLatLng(35.24, 126.98),
  );

  /// 양동시장 실제 권역에 맞춘 시연용 점포 좌표.
  static final yangdong = Market(
    id: 'yangdong',
    name: '양동시장',
    subtitle: '광주의 부엌 · 마감할인 시연 시장',
    center: const NLatLng(35.15355, 126.90500),
    bounds: const NLatLngBounds(
      southWest: NLatLng(35.15170, 126.90280),
      northEast: NLatLng(35.15540, 126.90740),
    ),
    isDemoReady: true,
    illustrationAsset: AppAssets.yangdongFloor1,
    stores: const [
      Store(
        id: 'yd-honguh',
        marketId: 'yangdong',
        name: '양동홍어타운',
        category: '수산',
        position: NLatLng(35.15455, 126.90385),
        description: '홍어회·홍어찜 마감 세트. 오늘 남은 회만 할인 판매합니다.',
        products: [
          Product(
            id: 'p-honguh-1',
            name: '홍어모둠 마감세트',
            originalPrice: 28000,
            discountPrice: 9900,
            quantity: 4,
            pickupWindow: '오늘 18:00–20:00',
          ),
        ],
      ),
      Store(
        id: 'yd-gukbap',
        marketId: 'yangdong',
        name: '천변국밥',
        category: '식당',
        position: NLatLng(35.15345, 126.90585),
        description: '점심 남은 국밥을 저녁 픽업 가격으로 내놓습니다.',
        products: [
          Product(
            id: 'p-gukbap-1',
            name: '돼지국밥 2인 마감팩',
            originalPrice: 16000,
            discountPrice: 6900,
            quantity: 6,
            pickupWindow: '오늘 17:30–19:30',
          ),
        ],
      ),
      Store(
        id: 'yd-gimbap',
        marketId: 'yangdong',
        name: '양동김밥명가',
        category: '분식',
        position: NLatLng(35.15370, 126.90655),
        description: '당일 생산 김밥·떡볶이 남은 수량 할인.',
        products: [
          Product(
            id: 'p-gimbap-1',
            name: '김밥 4줄 마감백',
            originalPrice: 14000,
            discountPrice: 5900,
            quantity: 8,
            pickupWindow: '오늘 16:00–18:30',
          ),
        ],
      ),
      Store(
        id: 'yd-yukhoe',
        marketId: 'yangdong',
        name: '빛고을육회',
        category: '정육·식당',
        position: NLatLng(35.15390, 126.90390),
        description: '당일 손질 육회 남은 분을 마감 할인합니다.',
        products: [
          Product(
            id: 'p-yukhoe-1',
            name: '육회 200g 마감팩',
            originalPrice: 22000,
            discountPrice: 8900,
            quantity: 3,
            pickupWindow: '오늘 17:00–19:00',
          ),
        ],
      ),
      Store(
        id: 'yd-fruit',
        marketId: 'yangdong',
        name: '햇살과일',
        category: '과일',
        position: NLatLng(35.15455, 126.90620),
        description: '오늘 팔다 남은 제철 과일 모음.',
        products: [
          Product(
            id: 'p-fruit-1',
            name: '제철과일 2kg 모음',
            originalPrice: 18000,
            discountPrice: 6900,
            quantity: 5,
            pickupWindow: '오늘 18:00–20:00',
          ),
        ],
      ),
      Store(
        id: 'yd-susan',
        marketId: 'yangdong',
        name: '싱싱수산',
        category: '수산',
        position: NLatLng(35.15455, 126.90450),
        description: '저녁 전에 소진할 생선 구이 세트.',
        products: [
          Product(
            id: 'p-susan-1',
            name: '고등어·갈치 구이세트',
            originalPrice: 20000,
            discountPrice: 7900,
            quantity: 5,
            pickupWindow: '오늘 17:30–19:30',
          ),
        ],
      ),
      Store(
        id: 'yd-tteok',
        marketId: 'yangdong',
        name: '양동떡집',
        category: '떡·한과',
        position: NLatLng(35.15290, 126.90395),
        description: '아침 생산분 중 남은 떡 모둠.',
        products: [
          Product(
            id: 'p-tteok-1',
            name: '인절미·백설기 모둠',
            originalPrice: 12000,
            discountPrice: 4900,
            quantity: 7,
            pickupWindow: '오늘 16:30–18:30',
          ),
        ],
      ),
      Store(
        id: 'yd-hanbok',
        marketId: 'yangdong',
        name: '고운한복',
        category: '생활잡화',
        position: NLatLng(35.15390, 126.90690),
        description: '시장 체험용 소품. 스탬프 시연 점포입니다.',
        products: [
          Product(
            id: 'p-hanbok-1',
            name: '전통 손수건 세트',
            originalPrice: 9000,
            discountPrice: 3900,
            quantity: 10,
            pickupWindow: '오늘 10:00–20:00',
          ),
        ],
      ),
      Store(
        id: 'yd-jeon',
        marketId: 'yangdong',
        name: '할머니전집',
        category: '식당',
        position: NLatLng(35.15395, 126.90615),
        description: '저녁 전에 남은 전 모둠을 포장 할인.',
        products: [
          Product(
            id: 'p-jeon-1',
            name: '모둠전 마감팩',
            originalPrice: 17000,
            discountPrice: 6900,
            quantity: 4,
            pickupWindow: '오늘 17:00–19:00',
          ),
        ],
      ),
      Store(
        id: 'yd-gunbam',
        marketId: 'yangdong',
        name: '밤마실군밤',
        category: '길거리 간식',
        position: NLatLng(35.15250, 126.90615),
        description: '구운 밤·고구마 남은 분량.',
        products: [
          Product(
            id: 'p-gunbam-1',
            name: '군밤 500g',
            originalPrice: 8000,
            discountPrice: 3500,
            quantity: 9,
            pickupWindow: '오늘 16:00–20:00',
          ),
        ],
      ),
    ],
  );

  static final daein = Market(
    id: 'daein',
    name: '대인시장',
    subtitle: '1차 데모 준비 중',
    center: const NLatLng(35.14820, 126.91980),
    bounds: const NLatLngBounds(
      southWest: NLatLng(35.14680, 126.91820),
      northEast: NLatLng(35.14960, 126.92140),
    ),
    stores: const [],
  );

  static final malbau = Market(
    id: 'malbau',
    name: '말바우시장',
    subtitle: '1차 데모 준비 중',
    center: const NLatLng(35.18040, 126.91120),
    bounds: const NLatLngBounds(
      southWest: NLatLng(35.17900, 126.90960),
      northEast: NLatLng(35.18180, 126.91280),
    ),
    stores: const [],
  );

  static List<Market> get all => [yangdong, daein, malbau];

  static Market byId(String id) => all.firstWhere((m) => m.id == id);

  static Store? storeById(String id) {
    for (final market in all) {
      for (final store in market.stores) {
        if (store.id == id) return store;
      }
    }
    return null;
  }

  /// 조감도 걷기 노선과 같은 순서. 정문에서 구역을 한 바퀴 돈 뒤 돌아온다.
  static const yangdongDemoPath = <NLatLng>[
    NLatLng(35.15215, 126.90500),
    NLatLng(35.15235, 126.90500),
    NLatLng(35.15250, 126.90615),
    NLatLng(35.15270, 126.90500),
    NLatLng(35.15290, 126.90395),
    NLatLng(35.15320, 126.90500),
    NLatLng(35.15345, 126.90585),
    NLatLng(35.15370, 126.90655),
    NLatLng(35.15395, 126.90615),
    NLatLng(35.15390, 126.90390),
    NLatLng(35.15455, 126.90385),
    NLatLng(35.15455, 126.90450),
    NLatLng(35.15455, 126.90620),
    NLatLng(35.15215, 126.90500),
  ];
}
