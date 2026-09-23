import '../config/assets.dart';
import '../map/market_blueprint.dart';
import '../models/product.dart';

/// 화장실·계단·사무실은 가게가 아니다.
bool indoorStallIsFacility(String name) {
  return name.contains('화장실') ||
      name.contains('계단') ||
      name.contains('사무실');
}

class DemoKind {
  const DemoKind({
    required this.sign,
    required this.use,
    required this.product,
    required this.storePhoto,
    required this.reviewPhoto,
    required this.original,
    required this.discount,
  });

  final String sign;
  final StallUse use;
  final String product;

  /// 시장 좌판·진열 사진. 가게 정보에 쓴다.
  final String storePhoto;

  /// 집어 먹거나 집에 가져가 찍은 사진. 리뷰에 쓴다.
  final String? reviewPhoto;
  final int original;
  final int discount;
}

class DemoShop {
  const DemoShop({required this.name, required this.kind});

  final String name;
  final DemoKind kind;

  StallUse get use => kind.use;

  List<Product> productsFor(String stallId) {
    return [
      Product(
        id: '$stallId-p1',
        name: '$name ${kind.product}',
        originalPrice: kind.original,
        discountPrice: kind.discount,
        quantity: 6,
        pickupWindow: '오늘 17:00–19:30',
        imageAsset: kind.storePhoto,
        reviewImageAsset: kind.reviewPhoto,
      ),
    ];
  }
}

/// 1층 칸마다 붙이는 시장 식당. 이름은 상호와 메뉴가 섞인다.
abstract final class MarketDemoShops {
  static const reviewPhotos = [
    AppAssets.foodReviewEomuk,
    AppAssets.foodReviewHotteok,
    AppAssets.foodReviewChicken,
    AppAssets.foodReviewTwigim,
    AppAssets.foodReviewDak,
    AppAssets.foodReviewMarshmallow,
    AppAssets.foodReviewSquid,
    AppAssets.foodReviewCorndog,
    AppAssets.foodReviewCroquette,
    AppAssets.foodReviewChimney,
    AppAssets.foodReviewPotatoIce,
    AppAssets.foodReviewIceRoll,
    AppAssets.foodReviewGukbap,
  ];

  static const _houses = [
    '꽃분이네',
    '할매네',
    '남도댁',
    '서석집',
    '양동네',
    '대인네',
    '말바우',
    '송정네',
    '금남집',
    '충장네',
    '무등댁',
    '양림네',
    '월산집',
    '광산네',
    '백운댁',
    '동명네',
    '수완집',
    '지산네',
    '봉선댁',
    '운암네',
    '문흥집',
    '두암네',
    '학동댁',
    '산수집',
    '중흥네',
    '쌍촌댁',
    '화정네',
    '상무집',
    '금호네',
    '풍암댁',
    '주월네',
    '효천집',
    '진월네',
    '방림댁',
    '서창네',
    '첨단집',
    '송원네',
    '우산댁',
    '신가네',
    '빛고을',
  ];

  static const _wings = ['', ' 별관', ' 골목점'];

  static const _kinds = <DemoKind>[
    DemoKind(
      sign: '어묵',
      use: StallUse.snack,
      product: '어묵꼬치',
      storePhoto: AppAssets.foodMarketEomuk,
      reviewPhoto: AppAssets.foodReviewEomuk,
      original: 9000,
      discount: 3900,
    ),
    DemoKind(
      sign: '호떡',
      use: StallUse.riceCake,
      product: '씨앗호떡',
      storePhoto: AppAssets.foodMarketHotteok,
      reviewPhoto: AppAssets.foodReviewHotteok,
      original: 6000,
      discount: 2500,
    ),
    DemoKind(
      sign: '치킨',
      use: StallUse.food,
      product: '양념치킨',
      storePhoto: AppAssets.foodMarketChicken,
      reviewPhoto: AppAssets.foodReviewChicken,
      original: 18000,
      discount: 7900,
    ),
    DemoKind(
      sign: '튀김',
      use: StallUse.food,
      product: '모둠튀김',
      storePhoto: AppAssets.foodMarketTwigim,
      reviewPhoto: AppAssets.foodReviewTwigim,
      original: 12000,
      discount: 4900,
    ),
    DemoKind(
      sign: '제과',
      use: StallUse.riceCake,
      product: '크림도넛',
      storePhoto: AppAssets.foodMarketDonut,
      reviewPhoto: null,
      original: 8000,
      discount: 3500,
    ),
    DemoKind(
      sign: '건어물',
      use: StallUse.dried,
      product: '건어 소분',
      storePhoto: AppAssets.foodMarketDried,
      reviewPhoto: AppAssets.foodDried,
      original: 18000,
      discount: 6900,
    ),
    DemoKind(
      sign: '쌈',
      use: StallUse.sidedish,
      product: '쌈 모둠',
      storePhoto: AppAssets.foodMarketSsam,
      reviewPhoto: null,
      original: 14000,
      discount: 5900,
    ),
    DemoKind(
      sign: '닭집',
      use: StallUse.food,
      product: '닭한마리',
      storePhoto: AppAssets.foodChicken,
      reviewPhoto: AppAssets.foodReviewDak,
      original: 22000,
      discount: 9900,
    ),
    DemoKind(
      sign: '오징어',
      use: StallUse.seafood,
      product: '오징어구이',
      storePhoto: AppAssets.foodMarketSquid,
      reviewPhoto: AppAssets.foodReviewSquid,
      original: 16000,
      discount: 6900,
    ),
    DemoKind(
      sign: '핫도그',
      use: StallUse.snack,
      product: '감자핫도그',
      storePhoto: AppAssets.foodMarketSnack,
      reviewPhoto: AppAssets.foodReviewCorndog,
      original: 7000,
      discount: 3000,
    ),
    DemoKind(
      sign: '고로케',
      use: StallUse.snack,
      product: '치즈고로케',
      storePhoto: AppAssets.foodMarketSnack,
      reviewPhoto: AppAssets.foodReviewCroquette,
      original: 8000,
      discount: 3500,
    ),
    DemoKind(
      sign: '아이스크림',
      use: StallUse.snack,
      product: '시장 아이스크림',
      storePhoto: AppAssets.foodReviewIceRoll,
      reviewPhoto: AppAssets.foodReviewPotatoIce,
      original: 6000,
      discount: 2500,
    ),
    DemoKind(
      sign: '김밥',
      use: StallUse.food,
      product: '김밥',
      storePhoto: AppAssets.foodMarketGimbap,
      reviewPhoto: AppAssets.foodGimbap,
      original: 8000,
      discount: 3500,
    ),
    DemoKind(
      sign: '분식',
      use: StallUse.food,
      product: '떡볶이',
      storePhoto: AppAssets.foodMarketTteokbokki,
      reviewPhoto: AppAssets.foodTteokbokki,
      original: 9000,
      discount: 3900,
    ),
    DemoKind(
      sign: '청과',
      use: StallUse.produce,
      product: '제철 과일',
      storePhoto: AppAssets.foodMarketFruit,
      reviewPhoto: AppAssets.foodFruit,
      original: 15000,
      discount: 5900,
    ),
    DemoKind(
      sign: '국밥',
      use: StallUse.food,
      product: '국밥',
      storePhoto: AppAssets.foodGukbap,
      reviewPhoto: AppAssets.foodReviewGukbap,
      original: 11000,
      discount: 4900,
    ),
    DemoKind(
      sign: '만두',
      use: StallUse.food,
      product: '찐만두',
      storePhoto: AppAssets.foodMarketMandu,
      reviewPhoto: AppAssets.foodMandu,
      original: 12000,
      discount: 4900,
    ),
    DemoKind(
      sign: '순대',
      use: StallUse.food,
      product: '순대',
      storePhoto: AppAssets.foodMarketSundae,
      reviewPhoto: AppAssets.foodSundae,
      original: 14000,
      discount: 5900,
    ),
    DemoKind(
      sign: '수산',
      use: StallUse.seafood,
      product: '수산 모둠',
      storePhoto: AppAssets.foodSeafood,
      reviewPhoto: AppAssets.foodMackerel,
      original: 22000,
      discount: 8900,
    ),
    DemoKind(
      sign: '정육',
      use: StallUse.meat,
      product: '불고기',
      storePhoto: AppAssets.foodBulgogi,
      reviewPhoto: AppAssets.foodYukhoe,
      original: 24000,
      discount: 10900,
    ),
    DemoKind(
      sign: '한과',
      use: StallUse.riceCake,
      product: '약과',
      storePhoto: AppAssets.foodYakgwa,
      reviewPhoto: null,
      original: 12000,
      discount: 4900,
    ),
    DemoKind(
      sign: '떡집',
      use: StallUse.riceCake,
      product: '떡 모둠',
      storePhoto: AppAssets.foodTteok,
      reviewPhoto: null,
      original: 13000,
      discount: 4900,
    ),
    DemoKind(
      sign: '전집',
      use: StallUse.food,
      product: '모둠전',
      storePhoto: AppAssets.foodJeon,
      reviewPhoto: null,
      original: 14000,
      discount: 5900,
    ),
    DemoKind(
      sign: '두부',
      use: StallUse.sidedish,
      product: '두부',
      storePhoto: AppAssets.foodTofu,
      reviewPhoto: null,
      original: 6000,
      discount: 2500,
    ),
    DemoKind(
      sign: '디저트',
      use: StallUse.snack,
      product: '길거리 디저트',
      storePhoto: AppAssets.foodReviewChimney,
      reviewPhoto: AppAssets.foodReviewMarshmallow,
      original: 7000,
      discount: 3000,
    ),
  ];

  static DemoShop at(int index) {
    final house = _houses[index % _houses.length];
    final kind = _kinds[index % _kinds.length];
    final wing = _wings[(index ~/ 120).clamp(0, _wings.length - 1)];
    final bare = index < _houses.length && index % 3 == 0;
    final name = bare ? house : '$house ${kind.sign}$wing';
    return DemoShop(name: name, kind: kind);
  }
}
