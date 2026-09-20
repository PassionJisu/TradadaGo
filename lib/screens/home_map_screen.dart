import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/assets.dart';
import '../data/gwangju_markets.dart';
import '../models/market.dart';
import '../state/location_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import '../widgets/google_location_dot.dart';
import '../widgets/market_play_view.dart';
import 'sangju_indoor_map_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  HomeMapScreenState createState() => HomeMapScreenState();
}

class HomeMapScreenState extends State<HomeMapScreen> {
  Market? _focused;
  bool _mapReady = false;
  NaverMapController? _map;
  final _playKey = GlobalKey<MarketPlayViewState>();
  final _indoorKey = GlobalKey<SangjuIndoorMapScreenState>();

  LocationSession get _loc => LocationSession.instance;

  @override
  void initState() {
    super.initState();
    _loc.addListener(_syncMyLocation);
    _loc.startGps();
  }

  @override
  void dispose() {
    _loc.removeListener(_syncMyLocation);
    super.dispose();
  }

  void openStampFlow() {
    if (_focused == null) {
      showAppNotice(context, '시장 핀을 눌러 조감도로 들어가세요.');
      return;
    }
    if (_focused!.id == GwangjuMarkets.malbau.id) {
      _indoorKey.currentState?.openNearbyStamp();
      return;
    }
    _playKey.currentState?.openNearbyStamp();
  }

  Future<void> _onMapReady(NaverMapController controller) async {
    _map = controller;
    controller.setLocationTrackingMode(NLocationTrackingMode.none);
    await _styleMyLocation(controller);
    _mapReady = true;
    await controller.addOverlayAll({
      for (final market in GwangjuMarkets.all) _marketMarker(market),
    });
    _syncMyLocation();
    if (mounted) setState(() {});
  }

  Future<void> _styleMyLocation(NaverMapController controller) async {
    if (!mounted) return;
    final overlay = controller.getLocationOverlay();
    final icon = await NOverlayImage.fromWidget(
      widget: const GoogleLocationDot(),
      size: const Size(64, 64),
      context: context,
    );
    if (!mounted || _map != controller) return;
    overlay.setIcon(icon);
    overlay.setIconSize(const Size(22, 22));
    overlay.setAnchor(NPoint.relativeCenter);
    overlay.setSubIcon(null);
    overlay.setCircleColor(const Color(0x331A73E8));
    overlay.setCircleRadius(36);
    overlay.setCircleOutlineColor(const Color(0x661A73E8));
    overlay.setCircleOutlineWidth(1);
  }

  void _syncMyLocation() {
    final controller = _map;
    final here = _loc.current;
    if (!_mapReady || controller == null) return;
    final overlay = controller.getLocationOverlay();
    if (here == null) {
      overlay.setIsVisible(false);
      return;
    }
    overlay.setPosition(here);
    overlay.setIsVisible(true);
  }

  Future<void> _goToMyLocation() async {
    final here = _loc.current;
    final controller = _map;
    if (here == null || controller == null) {
      showAppNotice(context, '위치를 찾는 중입니다. 잠시 후 다시 눌러주세요.');
      _loc.startGps();
      return;
    }
    await controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: here, zoom: 14.6),
    );
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
    if (market.id == GwangjuMarkets.malbau.id) {
      setState(() => _focused = market);
      return;
    }
    if (!market.isDemoReady) {
      showAppNotice(context, '${market.name}은 다음 단계에서 열립니다. 양동시장 또는 시장 데모를 선택하세요.');
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
    _map = null;
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
      child: _focused == null
          ? _cityMap()
          : _focused!.id == GwangjuMarkets.malbau.id
              ? SangjuIndoorMapScreen(
                  key: _indoorKey,
                  onBack: _backToCity,
                )
              : _playMap(),
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
                child: _HintChip('광주 전통시장 핀만 표시됩니다. 양동시장 또는 시장 데모를 눌러 입장하세요.'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('시장 내부 지도 · 상주종합시장'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SangjuIndoorMapScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 108,
          child: Material(
            color: Colors.white,
            elevation: 4,
            shadowColor: const Color(0x330B3A6A),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: '내 위치',
              onPressed: _goToMyLocation,
              color: GoogleLocationDot.blue,
              icon: const Icon(Icons.my_location_rounded),
            ),
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
              Image.asset(AppAssets.emblem, width: 48, height: 48),
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
