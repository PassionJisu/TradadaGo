import '../config/assets.dart';
import '../models/editorial_route.dart';

abstract final class EditorialRoutes {
  static const all = <EditorialRoute>[
    EditorialRoute(
      id: 'yangdong-taste',
      title: '양동 맛골목 반나절',
      kicker: '시장 미식',
      duration: '약 90분',
      distance: '800m',
      coverAsset: AppAssets.foodGimbap,
      summary:
          '광주의 부엌 양동시장을 홍어부터 군밤까지 한 바퀴. 마감할인 픽업 창구를 따라가면 걸음마다 스탬프가 쌓입니다.',
      stops: [
        EditorialStop(name: '양동홍어타운', note: '홍어모둠으로 입맛 열기'),
        EditorialStop(name: '천변국밥', note: '점심 국밥 마감팩'),
        EditorialStop(name: '할머니전집', note: '모둠전 포장'),
        EditorialStop(name: '밤마실군밤', note: '귀가길 간식'),
      ],
    ),
    EditorialRoute(
      id: 'closing-deals',
      title: '오늘만의 마감할인 알뜰 코스',
      kicker: '알뜰 탐방',
      duration: '약 60분',
      distance: '600m',
      coverAsset: AppAssets.skyHeader,
      summary:
          '당일 남은 제철 과일과 생선, 떡을 저녁 전에 모아 담는 루트. 폐기 직전 상품을 여행 기념품처럼 챙깁니다.',
      stops: [
        EditorialStop(name: '햇살과일', note: '제철과일 2kg 모음'),
        EditorialStop(name: '싱싱수산', note: '고등어·갈치 구이세트'),
        EditorialStop(name: '양동떡집', note: '인절미·백설기 모둠'),
      ],
    ),
    EditorialRoute(
      id: 'three-markets',
      title: '광주 전통시장 일주',
      kicker: '도시 여행',
      duration: '반나절',
      distance: '시장 3곳',
      coverAsset: AppAssets.landmarkChungjang,
      summary:
          '양동에서 시작해 대인·시장 데모까지. 양동은 조감도, 시장 데모는 내부 지도로 입장할 수 있습니다.',
      stops: [
        EditorialStop(name: '양동시장', note: '조감도 입장 · 스탬프'),
        EditorialStop(name: '대인시장', note: '야시장 골목 예습'),
        EditorialStop(name: '시장 데모', note: '내부 지도 시연'),
        EditorialStop(name: '충장로', note: '번화가에서 하루 마무리'),
      ],
    ),
    EditorialRoute(
      id: 'culture-market',
      title: '양림동에서 시장으로',
      kicker: '문화 산책',
      duration: '약 2시간',
      distance: '도보+시장',
      coverAsset: AppAssets.landmarkYangnim,
      summary:
          '호랑가시나무 마을을 둘러본 뒤 양동시장에서 마감할인을 픽업하는 여행 루트. 스탬프 보드의 양림동 우표와 이어집니다.',
      stops: [
        EditorialStop(name: '양림동', note: '근대 골목 산책'),
        EditorialStop(name: '양동시장', note: '고운한복 · 떡집'),
        EditorialStop(name: '5·18민주광장', note: '광주의 기억'),
      ],
    ),
  ];
}
