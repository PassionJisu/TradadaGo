import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/assets.dart';
import '../data/gwangju_markets.dart';
import '../map/geo_projection.dart';
import '../map/yangdong_play_layout.dart';
import '../models/market.dart';
import '../models/store.dart';
import '../state/location_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import 'store_preview_sheet.dart';

class MarketPlayView extends StatefulWidget {
  const MarketPlayView({
    super.key,
    required this.market,
    required this.onBack,
  });

  final Market market;
  final VoidCallback onBack;

  @override
  State<MarketPlayView> createState() => MarketPlayViewState();
}

class MarketPlayViewState extends State<MarketPlayView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  LocationSession get _loc => LocationSession.instance;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _loc.addListener(_onTick);
  }

  @override
  void dispose() {
    _loc.removeListener(_onTick);
    _pulse.dispose();
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Store? get nearbyStore {
    for (final store in widget.market.stores) {
      if (_loc.isNear(store.position)) return store;
    }
    return null;
  }

  void openNearbyStamp() {
    final store = nearbyStore;
    if (store == null) {
      showAppNotice(context, '가게 핀이 켜질 때까지 골목을 걸어주세요.');
      return;
    }
    showStorePreviewSheet(context, store, nearby: true);
  }

  Offset _pinUv(Store store, Size area) {
    final anchor = YangdongPlayLayout.anchors[store.id];
    if (anchor != null) {
      return Offset(anchor.dx * area.width, anchor.dy * area.height);
    }
    return geoToWorld(store.position, widget.market.bounds, area);
  }

  Offset _avatarUv(Size area) {
    final here = _loc.current ?? widget.market.center;
    final uv = gpsPathToUv(
      point: here,
      gpsPath: GwangjuMarkets.yangdongDemoPath,
      uvPath: YangdongPlayLayout.path,
    );
    return Offset(uv.dx * area.width, uv.dy * area.height);
  }

  @override
  Widget build(BuildContext context) {
    final nearby = nearbyStore;
    final mapAsset =
        widget.market.illustrationAsset ?? AppAssets.yangdongPlayMap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final area = Size(constraints.maxWidth, constraints.maxHeight);
        final avatar = _avatarUv(area);

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.pogoGrass,
              child: Image.asset(
                mapAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                width: area.width,
                height: area.height,
              ),
            ),
            for (final store in widget.market.stores)
              _storePin(store, _pinUv(store, area)),
            _avatarLayer(avatar),
            SafeArea(
              child: Column(
                children: [
                  _playHeader(),
                  if (nearby != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Material(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            '${nearby.name} 핀이 켜졌습니다. 탭해서 QR을 찍으세요!',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    child: FilledButton.icon(
                      onPressed: _loc.demoWalking
                          ? _loc.stopDemoWalk
                          : () {
                              if (widget.market.id ==
                                  GwangjuMarkets.yangdong.id) {
                                _loc.startYangdongDemoWalk();
                              }
                            },
                      icon: Icon(
                        _loc.demoWalking
                            ? Icons.stop_rounded
                            : Icons.directions_walk_rounded,
                      ),
                      label: Text(
                        _loc.demoWalking ? '시연 경로 정지' : '골목 시연 걷기',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _playHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Material(
        color: const Color(0xE6FFF8E8),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.navy,
              ),
              Image.asset(AppAssets.logo, width: 44, height: 44),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.market.name,
                      style: GoogleFonts.jua(
                        fontSize: 20,
                        color: AppColors.navy,
                      ),
                    ),
                    const Text(
                      '조감도 · 가게 핀을 찾아 걸어보세요',
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

  Widget _avatarLayer(Offset worldPos) {
    return Positioned(
      left: worldPos.dx - 36,
      top: worldPos.dy - 122,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -4 * _pulse.value),
              child: child,
            );
          },
          child: Column(
            children: [
              Image.asset(
                AppAssets.playAvatar,
                width: 72,
                height: 118,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              Container(
                width: 28,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storePin(Store store, Offset worldPos) {
    final active = _loc.isNear(store.position);
    final pinSize = active ? 56.0 : 40.0;
    return Positioned(
      left: worldPos.dx - 48,
      top: worldPos.dy - 78,
      width: 96,
      child: GestureDetector(
        onTap: () => showStorePreviewSheet(context, store, nearby: active),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final glow = active ? 0.28 + (_pulse.value * 0.42) : 0.0;
            return Column(
              children: [
                SizedBox(
                  height: 64,
                  width: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (active)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: glow * 0.4),
                          ),
                        ),
                      Image.asset(
                        active
                            ? AppAssets.pinStoreActive
                            : AppAssets.pinStoreIdle,
                        width: pinSize,
                        height: pinSize,
                        filterQuality: FilterQuality.high,
                      ),
                    ],
                  ),
                ),
                Text(
                  store.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    shadows: [
                      Shadow(color: Color(0xF2FFF8E8), blurRadius: 6),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
