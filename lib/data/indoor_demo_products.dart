import '../config/assets.dart';
import '../map/market_blueprint.dart';
import '../models/product.dart';

List<Product> indoorDemoProducts({
  required String stallId,
  required String stallName,
  required StallUse use,
}) {
  if (!use.isFilterable) return const [];

  Product pack({
    required String suffix,
    required String title,
    required int original,
    required int discount,
    required int quantity,
    required String image,
    String window = '오늘 17:00–19:30',
  }) {
    return Product(
      id: '$stallId-$suffix',
      name: title,
      originalPrice: original,
      discountPrice: discount,
      quantity: quantity,
      pickupWindow: window,
      imageAsset: image,
    );
  }

  return switch (use) {
    StallUse.seafood => [
      pack(
        suffix: 'p1',
        title: '$stallName 모둠 마감팩',
        original: 24000,
        discount: 8900,
        quantity: 4,
        image: AppAssets.foodSeafood,
      ),
      pack(
        suffix: 'p2',
        title: '$stallName 구이 소분',
        original: 16000,
        discount: 5900,
        quantity: 5,
        image: AppAssets.foodMackerel,
        window: '오늘 16:30–19:00',
      ),
    ],
    StallUse.dried => [
      pack(
        suffix: 'p1',
        title: '$stallName 건어 소분팩',
        original: 18000,
        discount: 6900,
        quantity: 6,
        image: AppAssets.foodDried,
      ),
    ],
    StallUse.produce => [
      pack(
        suffix: 'p1',
        title: '$stallName 제철 과일 모음',
        original: 15000,
        discount: 5900,
        quantity: 8,
        image: AppAssets.foodFruit,
      ),
    ],
    StallUse.meat => [
      pack(
        suffix: 'p1',
        title: '$stallName 불고기 마감팩',
        original: 22000,
        discount: 9900,
        quantity: 4,
        image: AppAssets.foodBulgogi,
      ),
    ],
    StallUse.food => [
      pack(
        suffix: 'p1',
        title: '$stallName 저녁 마감세트',
        original: 18000,
        discount: 6900,
        quantity: 6,
        image: AppAssets.foodGukbap,
      ),
    ],
    StallUse.snack => [
      pack(
        suffix: 'p1',
        title: '$stallName 간식 마감팩',
        original: 12000,
        discount: 4900,
        quantity: 7,
        image: AppAssets.foodTteokbokki,
      ),
    ],
    StallUse.sidedish => [
      pack(
        suffix: 'p1',
        title: '$stallName 반찬 모음',
        original: 14000,
        discount: 5900,
        quantity: 6,
        image: AppAssets.foodJeon,
      ),
    ],
    StallUse.riceCake => [
      pack(
        suffix: 'p1',
        title: '$stallName 떡 모둠',
        original: 13000,
        discount: 4900,
        quantity: 8,
        image: AppAssets.foodTteok,
      ),
    ],
    StallUse.clothes => [
      pack(
        suffix: 'p1',
        title: '$stallName 소품 마감세트',
        original: 16000,
        discount: 6900,
        quantity: 5,
        image: AppAssets.foodBojagi,
      ),
    ],
    StallUse.kitchen => [
      pack(
        suffix: 'p1',
        title: '$stallName 주방 소품 세트',
        original: 15000,
        discount: 5900,
        quantity: 5,
        image: AppAssets.foodBojagi,
      ),
    ],
    StallUse.goods => [
      pack(
        suffix: 'p1',
        title: '$stallName 마감팩',
        original: 12000,
        discount: 4900,
        quantity: 6,
        image: AppAssets.foodYakgwa,
      ),
    ],
    _ => const [],
  };
}
