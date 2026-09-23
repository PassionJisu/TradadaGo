import '../config/assets.dart';
import '../map/market_blueprint.dart';
import '../models/product.dart';

class _Dish {
  const _Dish(
    this.keyword,
    this.title,
    this.image,
    this.original,
    this.discount,
  );

  final String keyword;
  final String title;
  final String image;
  final int original;
  final int discount;
}

/// 이름에 음식이 드러나는 1층 가게만 연다. 사진이 없는 메뉴는 넣지 않는다.
const _dishes = <_Dish>[
  _Dish('바베큐', '숯불 바베큐', AppAssets.foodBulgogi, 24000, 10900),
  _Dish('한우', '한우 불고기', AppAssets.foodBulgogi, 28000, 12900),
  _Dish('꼬치닭', '꼬치닭', AppAssets.foodChicken, 16000, 6900),
  _Dish('통닭', '통닭', AppAssets.foodChicken, 18000, 7900),
  _Dish('치킨', '치킨', AppAssets.foodChicken, 18000, 7900),
  _Dish('닭마을', '닭 백숙', AppAssets.foodChicken, 20000, 8900),
  _Dish('만두', '만두', AppAssets.foodMandu, 12000, 4900),
  _Dish('순대', '순대', AppAssets.foodSundae, 14000, 5900),
  _Dish('도넛', '도넛', AppAssets.foodDonut, 8000, 3500),
  _Dish('호떡', '호떡', AppAssets.foodDonut, 6000, 2500),
  _Dish('약과', '약과', AppAssets.foodYakgwa, 12000, 4900),
  _Dish('한과', '한과', AppAssets.foodYakgwa, 14000, 5900),
  _Dish('과자', '전통 과자', AppAssets.foodYakgwa, 10000, 4500),
  _Dish('김밥', '김밥', AppAssets.foodGimbap, 8000, 3500),
  _Dish('어묵', '어묵', AppAssets.foodSundae, 9000, 3900),
  _Dish('찐빵', '찐빵', AppAssets.foodTteok, 7000, 3000),
  _Dish('두부', '두부', AppAssets.foodTofu, 6000, 2500),
  _Dish('반찬', '반찬 모음', AppAssets.foodJeon, 14000, 5900),
  _Dish('떡집', '떡 모둠', AppAssets.foodTteok, 13000, 4900),
  _Dish('분식', '떡볶이', AppAssets.foodTteokbokki, 9000, 3900),
  _Dish('생선', '생선구이', AppAssets.foodMackerel, 16000, 6900),
  _Dish('건어', '건어 소분', AppAssets.foodDried, 18000, 6900),
  _Dish('어물', '수산 모둠', AppAssets.foodSeafood, 22000, 8900),
  _Dish('수산', '수산 모둠', AppAssets.foodSeafood, 22000, 8900),
  _Dish('젓도', '젓갈', AppAssets.foodSeafood, 15000, 5900),
  _Dish('청과', '제철 과일', AppAssets.foodFruit, 15000, 5900),
  _Dish('곶감', '곶감', AppAssets.foodFruit, 18000, 7900),
  _Dish('농장', '제철 농산물', AppAssets.foodFruit, 14000, 5900),
  _Dish('농산', '제철 농산물', AppAssets.foodFruit, 14000, 5900),
  _Dish('국수', '국수', AppAssets.foodGukbap, 10000, 4500),
  _Dish('국나라', '국밥', AppAssets.foodGukbap, 11000, 4900),
  _Dish('식당', '백반', AppAssets.foodGukbap, 11000, 4900),
  _Dish('포차', '포차 안주', AppAssets.foodJeon, 16000, 6900),
];

_Dish? _dishFor(String name) {
  for (final dish in _dishes) {
    if (name.contains(dish.keyword)) return dish;
  }
  return null;
}

bool _blockedName(String name) {
  return name.contains('창고') ||
      name.contains('화장실') ||
      name.contains('계단') ||
      name.contains('사무실');
}

/// 1층 식품 가게를 연다. 수산·청과·다과·정육·먹거리가 포함되고, 창고·의류는 빠진다.
bool indoorStallHasMenu({
  required String name,
  required int floor,
  required StallUse use,
}) {
  if (floor != 1 || !use.isFood || _blockedName(name)) return false;
  return _dishFor(name) != null;
}

List<Product> indoorDemoProducts({
  required String stallId,
  required String stallName,
  required StallUse use,
  int floor = 1,
}) {
  if (!indoorStallHasMenu(name: stallName, floor: floor, use: use)) {
    return const [];
  }
  final dish = _dishFor(stallName)!;
  return [
    Product(
      id: '$stallId-p1',
      name: '$stallName ${dish.title}',
      originalPrice: dish.original,
      discountPrice: dish.discount,
      quantity: 6,
      pickupWindow: '오늘 17:00–19:30',
      imageAsset: dish.image,
    ),
  ];
}
