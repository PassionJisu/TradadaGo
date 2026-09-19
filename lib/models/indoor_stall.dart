import 'dart:ui';

import '../map/market_blueprint.dart';

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
}
