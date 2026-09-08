import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/assets.dart';
import '../data/gwangju_markets.dart';
import '../models/market.dart';
import '../state/location_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import '../widgets/market_play_view.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  HomeMapScreenState createState() => HomeMapScreenState();
}

class HomeMapScreenState extends State<HomeMapScreen> {
  Market? _focused;
  bool _mapReady = false;
  final _playKey = GlobalKey<MarketPlayViewState>();

  LocationSession get _loc => LocationSession.instance;

  @override
  void initState() {
    super.initState();
    _loc.startGps();
  }

  void openStampFlow() {
    if (_focused == null) {
      showAppNotice(context, '시장 핀을 눌러 조감도로 들어가세요.');
      return;
    }
    _playKey.currentState?.openNearbyStamp();
  }

  Future<void> _onMapReady(NaverMapController controller) async {
    final overlay = controller.getLocationOverlay();
    overlay.setIsVisible(false);
    controller.setLocationTrackingMode(NLocationTrackingMode.none);
    _mapReady = true;
    await controller.addOverlayAll({
      for (final market in GwangjuMarkets.all) _marketMarker(market),
    });
    if (mounted) setState(() {});
  }

  NMarker _marketMarker(Market market) {
    final marker = NMarker(
      id: 'market-${market.id}',
      position: market.center,
      icon: const NOverlayImage.fromAssetImage(AppAssets.pinMarket),
      size: const Size(64, 64),
      caption: NOverlayCaption(
        text: market.name,
        textSize: 14,
        color: AppColors.navy,
        haloColor: Colors.white,
      ),
      subCaption: NOverlayCaption(
        text: market.isDemoReady ? '탭해서 입장' : '1차 데모 준비 중',
        textSize: 11,
        color: AppColors.deepBlue,
        haloColor: Colors.white,
      ),
    );
    marker.setOnTapListener((_) => _openMarket(market));
    return marker;
  }

  void _openMarket(Market market) {
    if (!market.isDemoReady) {
      showAppNotice(context, '${market.name}은 다음 단계에서 열립니다. 양동시장을 선택하세요.');
      return;
    }
    _loc.enterMarketPlay(
      marketName: market.name,
      bounds: market.bounds,
      entrance: market.id == GwangjuMarkets.yangdong.id
          ? GwangjuMarkets.yangdongDemoPath.first
          : market.center,
    );
    setState(() => _focused = market);
  }

  void _backToCity() {
    _loc.leaveMarketPlay();
    setState(() {
      _focused = null;
      _mapReady = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _focused == null ? _cityMap() : _playMap(),
    );
  }

  Widget _playMap() {
    return MarketPlayView(
      key: _playKey,
      market: _focused!,
      onBack: _backToCity,
    );
  }

  Widget _cityMap() {
    return Stack(
      key: const ValueKey('city-map'),
      children: [
        NaverMap(
          options: const NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: GwangjuMarkets.cityCenter,
              zoom: 12.4,
            ),
            extent: GwangjuMarkets.cityBounds,
            minZoom: 11,
            maxZoom: 16.5,
            scaleBarEnable: false,
            locationButtonEnable: false,
            logoAlign: NLogoAlign.leftBottom,
          ),
          onMapReady: _onMapReady,
        ),
        SafeArea(
          child: Column(
            children: [
              const _CityHeader(),
              if (!_mapReady)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(color: AppColors.gold),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HintChip('광주 전통시장 핀만 표시됩니다. 양동시장을 눌러 입장하세요.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CityHeader extends StatelessWidget {
  const _CityHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Material(
        color: const Color(0xE6FFF8E8),
        borderRadius: BorderRadius.circular(22),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(
            children: [
              Image.asset(AppAssets.logo, width: 48, height: 48),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '트라다다 ',
                            style: GoogleFonts.jua(
                              fontSize: 20,
                              color: AppColors.navy,
                            ),
                          ),
                          TextSpan(
                            text: 'GO!',
                            style: GoogleFonts.jua(
                              fontSize: 20,
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '전통시장 핀을 선택하세요',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6FFF8E8),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
