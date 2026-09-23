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
          '광주의 부엌 양동시장을 홍어부터 군밤까지 한 바퀴. 예약 픽업과 현장 결제 모두, 가게 앞에서 QR하면 방문 스탬프 1개입니다. 칭호는 처음 가는 가게만 세고, 포토 리뷰는 보너스 스탬프입니다.',
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
          '당일 남은 제철 과일과 생선, 떡을 저녁 전에 모아 담는 루트. 미리 예약하거나, 좌판에서 바로 결제해도 가게 앞 QR로 인증합니다.',
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
          '양동시장은 조감도, 시장 데모는 내부 지도로 들어갑니다. 대인시장 내부와 충장로 입장 지도는 아직 없습니다. 충장로는 스탬프 보드의 명소입니다.',
      stops: [
        EditorialStop(name: '양동시장', note: '조감도로 입장 · 가게 앞 QR'),
        EditorialStop(name: '대인시장', note: '위치만 있음 · 내부는 다음 단계'),
        EditorialStop(name: '시장 데모', note: '1층 식당 내부 지도'),
        EditorialStop(name: '충장로', note: '입장 지도 없음 · 우표 명소'),
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
          '양림동과 5·18민주광장은 스탬프 보드의 광주 명소입니다. 루트를 걷는다고 그 우표가 바로 찍히지는 않고, 가게 스탬프는 양동시장 가게 앞 QR로 받습니다.',
      stops: [
        EditorialStop(name: '양림동', note: '근대 골목 · 우표 명소'),
        EditorialStop(name: '양동시장', note: '고운한복 · 양동떡집 · 가게 QR'),
        EditorialStop(name: '5·18민주광장', note: '역사 명소 · 입장 지도 없음'),
      ],
    ),
  ];
}
