import 'package:flutter/material.dart';

import '../models/market.dart';
import '../models/store.dart';
import 'yangdong_play_layout.dart';

abstract final class MarketFloorPlan {
  static const _palette = <Color>[
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFFDD835),
    Color(0xFF1E88E5),
    Color(0xFFEC407A),
    Color(0xFF5E35B1),
    Color(0xFF6D4C41),
    Color(0xFF00897B),
  ];

  static Map<String, Rect> zonesFor(Market market) {
    if (market.id == 'yangdong') return YangdongPlayLayout.floorZones;
    return gridZones(market.stores);
  }

  static Map<String, Rect> gridZones(List<Store> stores) {
    if (stores.isEmpty) return const {};
    const columns = 2;
    const gutter = 0.04;
    const left = 0.04;
    const top = 0.08;
    const usableW = 0.92;
    const usableH = 0.84;
    final rows = (stores.length / columns).ceil();
    final cellW = (usableW - gutter) / columns;
    final cellH = (usableH - gutter * (rows - 1).clamp(0, 100)) / rows;
    final zones = <String, Rect>{};
    for (var i = 0; i < stores.length; i++) {
      final col = i % columns;
      final row = i ~/ columns;
      zones[stores[i].id] = Rect.fromLTWH(
        left + col * (cellW + gutter),
        top + row * (cellH + gutter),
        cellW,
        cellH,
      );
    }
    return zones;
  }

  static Color paintFor(String storeId) =>
      YangdongPlayLayout.paints[storeId] ??
      _palette[storeId.hashCode.abs() % _palette.length];
}
