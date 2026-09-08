import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'store.dart';

class Market {
  const Market({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.center,
    required this.bounds,
    required this.stores,
    this.illustrationAsset,
    this.isDemoReady = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final NLatLng center;
  final NLatLngBounds bounds;
  final List<Store> stores;

  /// 시장 조감도 이미지. 핀을 눌러 들어간 플레이 화면에서 사용한다.
  final String? illustrationAsset;
  final bool isDemoReady;
}
