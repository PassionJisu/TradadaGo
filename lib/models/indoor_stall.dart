import 'dart:ui';

import '../data/gwangju_markets.dart';
import '../data/indoor_demo_products.dart';
import '../data/market_demo_shops.dart';
import '../map/market_blueprint.dart';
import 'store.dart';

class IndoorStall {
  const IndoorStall({
    required this.id,
    required this.name,
    required this.floor,
    required this.path,
    required this.bounds,
    this.use = StallUse.goods,
    this.demo,
  });

  final String id;
  final String name;
  final int floor;
  final Path path;
  final Rect bounds;
  final StallUse use;
  final DemoShop? demo;

  bool get hasMenu =>
      demo != null || indoorStallHasMenu(name: name, floor: floor, use: use);

  IndoorStall withDemo(DemoShop shop) {
    return IndoorStall(
      id: id,
      name: shop.name,
      floor: floor,
      path: path,
      bounds: bounds,
      use: shop.use,
      demo: shop,
    );
  }

  bool get hasDiscountProducts => hasMenu;

  Store asStore({bool qrUnlocked = false}) {
    final products = demo?.productsFor(id) ??
        indoorDemoProducts(
          stallId: id,
          stallName: name,
          use: use,
          floor: floor,
        );
    return Store(
      id: id,
      marketId: GwangjuMarkets.malbau.id,
      name: name,
      category: use.labelKo,
      position: GwangjuMarkets.malbau.center,
      products: products,
      description: products.isEmpty
          ? '아직 가게 정보가 구현되지 않았습니다.'
          : '$floor층 · ${use.labelKo}',
      requireGps: !qrUnlocked,
    );
  }
}
