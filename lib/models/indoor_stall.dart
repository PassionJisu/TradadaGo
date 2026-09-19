import 'dart:ui';

import '../data/gwangju_markets.dart';
import '../data/indoor_demo_products.dart';
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
  });

  final String id;
  final String name;
  final int floor;
  final Path path;
  final Rect bounds;
  final StallUse use;

  bool get hasDiscountProducts => indoorDemoProducts(
        stallId: id,
        stallName: name,
        use: use,
      ).isNotEmpty;

  Store asStore() {
    return Store(
      id: id,
      marketId: GwangjuMarkets.malbau.id,
      name: name,
      category: use.labelKo,
      position: GwangjuMarkets.malbau.center,
      products: indoorDemoProducts(
        stallId: id,
        stallName: name,
        use: use,
      ),
      description: '$floor층 · ${use.labelKo} · 마감할인 시연',
      requireGps: false,
    );
  }
}
