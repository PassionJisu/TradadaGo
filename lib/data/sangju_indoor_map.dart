import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../models/indoor_stall.dart';

class SangjuIndoorMap {
  SangjuIndoorMap._({
    required this.stalls,
    required this.mapSize,
    required this.pad,
  });

  static const asset = 'assets/data/sangju_indoor_stalls.json';
  static const plazaPad = 1200.0;

  final List<IndoorStall> stalls;
  final Size mapSize;
  final double pad;

  Offset get startFocus => Offset(
        pad + mapSize.width * 0.48,
        pad + mapSize.height * 0.62,
      );

  static Future<SangjuIndoorMap> load() async {
    final raw = jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
    final mapSize = Size(
      (raw['imageWidth'] as num).toDouble(),
      (raw['imageHeight'] as num).toDouble(),
    );
    final stalls = <IndoorStall>[
      for (final item in raw['stalls'] as List)
        _stall(item as Map<String, dynamic>, plazaPad),
    ];
    return SangjuIndoorMap._(
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
    return IndoorStall(
      id: item['id'] as String,
      name: item['name'] as String,
      floor: item['floor'] as int,
      path: path,
      bounds: path.getBounds(),
    );
  }
}
