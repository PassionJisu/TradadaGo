import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../models/market.dart';

/// 시장 조감도 이미지를 네이버맵 GroundOverlay로 올릴 때 사용한다.
/// 현재 플레이 화면은 전용 조감도 뷰를 쓰며, 이 레이어는 이후 확장용이다.
abstract final class MarketMapLayer {
  static const overlayIdPrefix = 'market-illustration-';

  static Future<void> applyIllustration({
    required NaverMapController controller,
    required Market market,
  }) async {
    final asset = market.illustrationAsset;
    if (asset == null) return;

    await controller.addOverlay(
      NGroundOverlay(
        id: '$overlayIdPrefix${market.id}',
        bounds: market.bounds,
        image: NOverlayImage.fromAssetImage(asset),
      ),
    );
  }
}
