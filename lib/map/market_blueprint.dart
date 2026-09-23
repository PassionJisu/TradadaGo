import 'package:flutter/material.dart';

/// 점포 용도. 데모 지도에서 구역 색과 아이콘을 나눌 때 쓴다.
enum StallUse {
  seafood,
  dried,
  produce,
  meat,
  food,
  snack,
  sidedish,
  riceCake,
  goods,
  clothes,
  kitchen,
  service,
  vacant,
  parking,
  storage,
}

extension StallUseStyle on StallUse {
  String get emoji => switch (this) {
    StallUse.seafood => '🐟',
    StallUse.dried => '🦐',
    StallUse.produce => '🍎',
    StallUse.meat => '🥩',
    StallUse.food => '🍜',
    StallUse.snack => '🍡',
    StallUse.sidedish => '🥗',
    StallUse.riceCake => '🍡',
    StallUse.goods => '🧺',
    StallUse.clothes => '👕',
    StallUse.kitchen => '🍳',
    StallUse.service => '🛎️',
    StallUse.vacant => '⬜',
    StallUse.parking => '🅿️',
    StallUse.storage => '📦',
  };

  String get labelKo => switch (this) {
    StallUse.seafood => '수산',
    StallUse.dried => '건어물',
    StallUse.produce => '청과',
    StallUse.meat => '정육',
    StallUse.food => '먹거리',
    StallUse.snack => '간식',
    StallUse.sidedish => '반찬',
    StallUse.riceCake => '떡',
    StallUse.goods => '잡화',
    StallUse.clothes => '의류',
    StallUse.kitchen => '주방',
    StallUse.service => '안내',
    StallUse.vacant => '공실',
    StallUse.parking => '주차',
    StallUse.storage => '창고',
  };

  bool get isFilterable => switch (this) {
    StallUse.vacant || StallUse.parking || StallUse.storage => false,
    _ => true,
  };

  /// 시장 데모에서 정보·카테고리·핀을 여는 음식 업종.
  bool get isFood => switch (this) {
    StallUse.seafood ||
    StallUse.dried ||
    StallUse.produce ||
    StallUse.meat ||
    StallUse.food ||
    StallUse.snack ||
    StallUse.sidedish ||
    StallUse.riceCake => true,
    _ => false,
  };

  Color get color => switch (this) {
    StallUse.seafood => const Color(0xFF4A9FE0),
    StallUse.dried => const Color(0xFF7C97AF),
    StallUse.produce => const Color(0xFF4CB963),
    StallUse.meat => const Color(0xFFE9697C),
    StallUse.food => const Color(0xFFF79034),
    StallUse.snack => const Color(0xFFF0B429),
    StallUse.sidedish => const Color(0xFF19B39E),
    StallUse.riceCake => const Color(0xFFEE77AC),
    StallUse.goods => const Color(0xFF9575DC),
    StallUse.clothes => const Color(0xFFB169C4),
    StallUse.kitchen => const Color(0xFF6485D2),
    StallUse.service => const Color(0xFF8698AC),
    StallUse.vacant => const Color(0xFFC3CCD6),
    StallUse.parking => const Color(0xFF93A2B1),
    StallUse.storage => const Color(0xFFB09A7C),
  };

  IconData get icon => switch (this) {
    StallUse.seafood => Icons.set_meal_rounded,
    StallUse.dried => Icons.dry_rounded,
    StallUse.produce => Icons.local_florist_rounded,
    StallUse.meat => Icons.kebab_dining_rounded,
    StallUse.food => Icons.ramen_dining_rounded,
    StallUse.snack => Icons.icecream_rounded,
    StallUse.sidedish => Icons.rice_bowl_rounded,
    StallUse.riceCake => Icons.cake_rounded,
    StallUse.goods => Icons.shopping_basket_rounded,
    StallUse.clothes => Icons.checkroom_rounded,
    StallUse.kitchen => Icons.soup_kitchen_rounded,
    StallUse.service => Icons.support_agent_rounded,
    StallUse.vacant => Icons.storefront_rounded,
    StallUse.parking => Icons.local_parking_rounded,
    StallUse.storage => Icons.inventory_2_rounded,
  };
}

enum FacilityKind { restroom, info, stairs, elevator, parking, gate, atm }

extension FacilityKindStyle on FacilityKind {
  IconData get icon => switch (this) {
    FacilityKind.restroom => Icons.wc_rounded,
    FacilityKind.info => Icons.info_rounded,
    FacilityKind.stairs => Icons.stairs_rounded,
    FacilityKind.elevator => Icons.elevator_rounded,
    FacilityKind.parking => Icons.local_parking_rounded,
    FacilityKind.gate => Icons.door_sliding_rounded,
    FacilityKind.atm => Icons.local_atm_rounded,
  };

  Color get color => switch (this) {
    FacilityKind.restroom => const Color(0xFF5B8DEF),
    FacilityKind.info => const Color(0xFF17A2A2),
    FacilityKind.stairs => const Color(0xFF8B7BD8),
    FacilityKind.elevator => const Color(0xFF8B7BD8),
    FacilityKind.parking => const Color(0xFF6D7D8C),
    FacilityKind.gate => const Color(0xFFE0A21C),
    FacilityKind.atm => const Color(0xFF4CAF50),
  };
}

/// 개별 점포 칸. [storeId]가 있으면 스탬프를 찍을 수 있는 시연 점포다.
@immutable
class Stall {
  const Stall({
    required this.rect,
    required this.label,
    required this.use,
    this.storeId,
  });

  final Rect rect;
  final String label;
  final StallUse use;
  final String? storeId;

  bool get isDemoStore => storeId != null;

  /// 핀이 앉는 점. 칸 위쪽 중앙이다.
  Offset get anchor => Offset(rect.center.dx, rect.top + 2);

  bool contains(Offset point) => rect.inflate(4).contains(point);
}

@immutable
class StallSpec {
  const StallSpec(this.label, {this.use, this.storeId});

  final String label;
  final StallUse? use;
  final String? storeId;
}

@immutable
class MarketBlock {
  const MarketBlock({
    required this.id,
    required this.code,
    required this.name,
    required this.rect,
    required this.theme,
    required this.stalls,
  });

  final String id;
  final String code;
  final String name;
  final Rect rect;
  final StallUse theme;
  final List<Stall> stalls;

  List<Stall> get shopStalls => stalls
      .where(
        (stall) =>
            stall.use != StallUse.vacant &&
            stall.use != StallUse.parking &&
            stall.use != StallUse.storage,
      )
      .toList();

  List<Stall> get colorableStalls =>
      shopStalls.where((stall) => stall.storeId != null).toList();

  bool isComplete(Set<String> paintedStoreIds) {
    final shops = shopStalls;
    if (shops.isEmpty) return false;
    return shops.every(
      (stall) =>
          stall.storeId != null && paintedStoreIds.contains(stall.storeId),
    );
  }

  bool matchesUse(StallUse? use) {
    if (use == null) return true;
    if (theme == use) return true;
    return stalls.any((stall) => stall.use == use);
  }
}

@immutable
class Street {
  const Street(this.rect, {this.label});

  final Rect rect;
  final String? label;

  bool get isVertical => rect.height >= rect.width;
}

@immutable
class Facility {
  const Facility({
    required this.rect,
    required this.label,
    required this.kind,
  });

  final Rect rect;
  final String label;
  final FacilityKind kind;
}

@immutable
class MapLabel {
  const MapLabel({
    required this.at,
    required this.text,
    required this.color,
    this.fontSize = 22,
  });

  final Offset at;
  final String text;
  final Color color;
  final double fontSize;
}

@immutable
class MarketFloor {
  const MarketFloor({
    required this.id,
    required this.label,
    required this.caption,
    required this.blocks,
    this.streets = const [],
    this.facilities = const [],
    this.labels = const [],
    this.route = const [],
    this.backgroundAsset,
    this.isGpsFloor = false,
  });

  final String id;
  final String label;
  final String caption;
  final List<MarketBlock> blocks;
  final List<Street> streets;
  final List<Facility> facilities;
  final List<MapLabel> labels;

  /// 조감도 배경. 있으면 격자 블록 대신 그림을 깐다.
  final String? backgroundAsset;

  /// 아바타만 이 점을 따라간다. 지도에는 그리지 않는다.
  final List<Offset> route;
  final bool isGpsFloor;

  Iterable<Stall> get stalls => blocks.expand((block) => block.stalls);

  List<Stall> get demoStores =>
      stalls.where((stall) => stall.isDemoStore).toList();

  Stall? stallForStore(String storeId) {
    for (final stall in stalls) {
      if (stall.storeId == storeId) return stall;
    }
    return null;
  }

  MarketBlock? blockById(String id) {
    for (final block in blocks) {
      if (block.id == id) return block;
    }
    return null;
  }

  MarketBlock? blockAt(Offset point) {
    for (final block in blocks) {
      if (block.rect.contains(point)) return block;
    }
    return null;
  }

  List<Stall> get colorableStalls =>
      stalls.where((stall) => stall.storeId != null).toList();

  List<StallUse> get filterUses {
    final seen = <StallUse>{};
    for (final stall in stalls) {
      if (stall.use.isFilterable) seen.add(stall.use);
    }
    return StallUse.values.where(seen.contains).toList();
  }
}

@immutable
class MarketBlueprint {
  const MarketBlueprint({
    required this.marketId,
    required this.canvas,
    required this.floors,
    required this.focus,
  });

  final String marketId;
  final Size canvas;
  final List<MarketFloor> floors;
  final Rect focus;

  bool get isMultiFloor => floors.length > 1;

  MarketFloor get gpsFloor =>
      floors.firstWhere((floor) => floor.isGpsFloor, orElse: () => floors.first);

  MarketFloor? floorForStore(String storeId) {
    for (final floor in floors) {
      if (floor.stallForStore(storeId) != null) return floor;
    }
    return null;
  }

  MarketFloor floorById(String id) =>
      floors.firstWhere((floor) => floor.id == id, orElse: () => floors.first);

  List<Stall> get colorableStalls =>
      floors.expand((floor) => floor.colorableStalls).toList();

  ({int painted, int total}) paintProgress(Set<String> paintedStoreIds) {
    final targets = colorableStalls;
    final painted = targets
        .where((stall) => paintedStoreIds.contains(stall.storeId))
        .length;
    return (painted: painted, total: targets.length);
  }
}

/// 점포 목록을 격자로 배치해 색 구역을 만든다.
MarketBlock buildBlock({
  required String name,
  required Rect rect,
  required StallUse theme,
  required int columns,
  required List<StallSpec> stalls,
  String? id,
  String? code,
  double headerHeight = 36,
  double gap = 7,
  double padding = 9,
}) {
  assert(columns > 0);
  if (stalls.isEmpty) {
    return MarketBlock(
      id: id ?? name,
      code: code ?? name,
      name: name,
      rect: rect,
      theme: theme,
      stalls: const [],
    );
  }

  final rows = (stalls.length / columns).ceil();
  final inner = Rect.fromLTWH(
    rect.left + padding,
    rect.top + headerHeight,
    rect.width - padding * 2,
    rect.height - headerHeight - padding,
  );
  final cellWidth = (inner.width - gap * (columns - 1)) / columns;
  final cellHeight = (inner.height - gap * (rows - 1)) / rows;

  final placed = <Stall>[];
  for (var i = 0; i < stalls.length; i++) {
    final spec = stalls[i];
    final column = i % columns;
    final row = i ~/ columns;
    placed.add(
      Stall(
        rect: Rect.fromLTWH(
          inner.left + column * (cellWidth + gap),
          inner.top + row * (cellHeight + gap),
          cellWidth,
          cellHeight,
        ),
        label: spec.label,
        use: spec.use ?? theme,
        storeId: spec.storeId,
      ),
    );
  }

  return MarketBlock(
    id: id ?? name,
    code: code ?? name,
    name: name,
    rect: rect,
    theme: theme,
    stalls: placed,
  );
}

/// 골목을 향한 점포 한 줄. 격자 블록 대신 아케이드처럼 붙인다.
List<Stall> placeRow({
  required List<StallSpec> stalls,
  required StallUse theme,
  required double left,
  required double top,
  required double width,
  required double height,
}) {
  if (stalls.isEmpty) return const [];
  final cell = width / stalls.length;
  return [
    for (var i = 0; i < stalls.length; i++)
      Stall(
        rect: Rect.fromLTWH(left + i * cell + 3, top, cell - 6, height),
        label: stalls[i].label,
        use: stalls[i].use ?? theme,
        storeId: stalls[i].storeId,
      ),
  ];
}

List<Stall> placeColumn({
  required List<StallSpec> stalls,
  required StallUse theme,
  required double left,
  required double top,
  required double width,
  required double height,
}) {
  if (stalls.isEmpty) return const [];
  final cell = height / stalls.length;
  return [
    for (var i = 0; i < stalls.length; i++)
      Stall(
        rect: Rect.fromLTWH(left, top + i * cell + 3, width, cell - 6),
        label: stalls[i].label,
        use: stalls[i].use ?? theme,
        storeId: stalls[i].storeId,
      ),
  ];
}
