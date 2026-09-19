import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../map/market_blueprint.dart';
import '../models/indoor_stall.dart';

class SangjuIndoorMap {
  SangjuIndoorMap._({
    required this.stalls,
    required this.mapSize,
    required this.pad,
  });

  static const asset = 'assets/data/sangju_indoor_stalls.json';
  static const plazaPad = 1200.0;
  static const publishedStallCount = 186;

  static SangjuIndoorMap? _cached;

  final List<IndoorStall> stalls;
  final Size mapSize;
  final double pad;

  Offset get startFocus => Offset(
        pad + mapSize.width / 2,
        pad + mapSize.height - 70,
      );

  List<MarketFloor> get floors => const [
        MarketFloor(
          id: '1',
          label: '1층',
          caption: '시장 내부',
          blocks: [],
        ),
        MarketFloor(
          id: '2',
          label: '2층',
          caption: '사무실 · 교육장',
          blocks: [],
        ),
      ];

  List<StallUse> usesOnFloor(int floor) {
    final seen = <StallUse>{};
    return [
      for (final stall in stalls)
        if (stall.floor == floor && stall.use.isFilterable && seen.add(stall.use))
          stall.use,
    ]..sort((a, b) => a.labelKo.compareTo(b.labelKo));
  }

  List<IndoorStall> stallsOnFloor(int floor, {StallUse? use}) {
    return [
      for (final stall in stalls)
        if (stall.floor == floor && (use == null || stall.use == use)) stall,
    ];
  }

  List<IndoorStall> uniqueNamed(List<IndoorStall> source) {
    final ranked = [...source]..sort((a, b) {
        final aa = a.bounds.width * a.bounds.height;
        final ba = b.bounds.width * b.bounds.height;
        return ba.compareTo(aa);
      });
    final seen = <String>{};
    return [
      for (final stall in ranked)
        if (seen.add(stall.name)) stall,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  static Future<SangjuIndoorMap> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
    final mapSize = Size(
      (raw['imageWidth'] as num).toDouble(),
      (raw['imageHeight'] as num).toDouble(),
    );
    final stalls = <IndoorStall>[
      for (final item in raw['stalls'] as List)
        _stall(item as Map<String, dynamic>, plazaPad),
    ];
    return _cached = SangjuIndoorMap._(
      stalls: stalls,
      mapSize: mapSize,
      pad: plazaPad,
    );
  }

  static IndoorStall _stall(Map<String, dynamic> item, double pad) {
    final coords = [
      for (final n in item['coords'] as List) (n as num).toDouble(),
    ];
    final shape = item['shape'] as String;
    final path = Path();
    if (shape == 'poly' && coords.length >= 6) {
      path.moveTo(coords[0] + pad, coords[1] + pad);
      for (var i = 2; i < coords.length; i += 2) {
        path.lineTo(coords[i] + pad, coords[i + 1] + pad);
      }
      path.close();
    } else {
      final l = coords[0] + pad;
      final t = coords[1] + pad;
      final r = coords[2] + pad;
      final b = coords[3] + pad;
      path.addRect(Rect.fromLTRB(l, t, r, b));
    }
    final name = item['name'] as String;
    return IndoorStall(
      id: item['id'] as String,
      name: name,
      floor: item['floor'] as int,
      path: path,
      bounds: path.getBounds(),
      use: inferStallUse(name),
    );
  }

  static StallUse inferStallUse(String name) {
    if (name.contains('창고')) return StallUse.storage;
    if (name.contains('화장실')) return StallUse.service;
    if (name.contains('수산') ||
        name.contains('어물') ||
        name.contains('생선') ||
        name.contains('젓')) {
      return StallUse.seafood;
    }
    if (name.contains('건어')) return StallUse.dried;
    if (name.contains('청과') ||
        name.contains('과일') ||
        name.contains('곶감') ||
        name.contains('표고')) {
      return StallUse.produce;
    }
    if (name.contains('한우') || name.contains('정육') || name.contains('고기')) {
      return StallUse.meat;
    }
    if (name.contains('반찬')) return StallUse.sidedish;
    if (name.contains('떡') || name.contains('도넛') || name.contains('튀밥')) {
      return StallUse.riceCake;
    }
    if (name.contains('식당') ||
        name.contains('국수') ||
        name.contains('치킨') ||
        name.contains('통닭') ||
        name.contains('만두') ||
        name.contains('순대') ||
        name.contains('국나라') ||
        name.contains('바베큐') ||
        name.contains('포차') ||
        name.contains('분식') ||
        name.contains('카페')) {
      return StallUse.food;
    }
    if (name.contains('포목') ||
        name.contains('한복') ||
        name.contains('패션') ||
        name.contains('란제리') ||
        name.contains('피복') ||
        name.contains('승복') ||
        name.contains('신발')) {
      return StallUse.clothes;
    }
    if (name.contains('미용') ||
        name.contains('헤어') ||
        name.contains('이용') ||
        name.contains('수선') ||
        name.contains('세탁') ||
        name.contains('사무실') ||
        name.contains('교육')) {
      return StallUse.service;
    }
    return StallUse.goods;
  }
}
