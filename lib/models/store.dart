import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'product.dart';

class Store {
  const Store({
    required this.id,
    required this.marketId,
    required this.name,
    required this.category,
    required this.position,
    required this.products,
    this.description = '',
  });

  final String id;
  final String marketId;
  final String name;
  final String category;
  final NLatLng position;
  final String description;
  final List<Product> products;

  String get qrPayload => 'TRADADAGO:$id';
}
