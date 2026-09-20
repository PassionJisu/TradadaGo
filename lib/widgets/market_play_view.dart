import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/assets.dart';
import '../data/gwangju_markets.dart';
import '../data/market_blueprints.dart';
import '../map/geo_projection.dart';
import '../map/market_blueprint.dart';
import '../models/market.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../state/location_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import 'floor_plan_painter.dart';
import 'market_map_controls.dart';
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
  final _controller = TransformationController();

  MarketBlueprint? _blueprint;
  String? _floorId;
  String? _selectedWingId;
  StallUse? _filterUse;
  bool _followUser = true;
  Size _viewport = Size.zero;

  /// 점포 칸 이름을 읽을 수 있는 배율.
  static const _labelScale = 0.72;

  /// 핀 이름표가 겹치지 않는 배율.
  static const _markerLabelScale = 0.55;
  static const _topInset = 132.0;
  static const _bottomInset = 248.0;

  LocationSession get _loc => LocationSession.instance;
  AppSession get _session => AppSession.instance;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _blueprint = MarketBlueprints.forMarket(widget.market);
    _floorId = _blueprint?.gpsFloor.id;
    _loc.addListener(_onLocation);
    _session.addListener(_onSession);
    _controller.addListener(_onTransform);
  }

  @override
  void dispose() {
    _loc.removeListener(_onLocation);
    _session.removeListener(_onSession);
    _controller.removeListener(_onTransform);
    _controller.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  void _onTransform() {
    if (mounted) setState(() {});
  }

  void _onLocation() {
    if (!mounted) return;
    if (_loc.demoPaused) {
      if (_pulse.isAnimating) _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
    final blueprint = _blueprint;
    final floor = _floor;
    if (blueprint != null &&
        floor != null &&
        floor.isGpsFloor &&
        _selectedWingId == null &&
        (_followUser || _loc.demoWalking) &&
        !_loc.demoPaused) {
      _focusOn(_avatarCanvas(blueprint), scale: 1.18);
    }
    setState(() {});
  }

  MarketFloor? get _floor {
    final blueprint = _blueprint;
    if (blueprint == null) return null;
    final id = _floorId;
    return id == null ? blueprint.gpsFloor : blueprint.floorById(id);
  }

  Store? get nearbyStore {
    final floor = _floor;
    final blueprint = _blueprint;
    if (floor == null || blueprint == null) return null;

    if (!floor.isGpsFloor) {
      for (final stall in floor.demoStores) {
        final store = _storeById(stall.storeId!);
        if (store != null && _loc.isNear(store.position)) return store;
      }
      return null;
    }

    final avatar = _avatarCanvas(blueprint);
    Store? best;
    var bestDist = 56.0;
    for (final stall in floor.demoStores) {
      final store = _storeById(stall.storeId!);
      if (store == null) continue;
      final d = _distanceToRect(avatar, stall.rect);
      if (d < bestDist) {
        bestDist = d;
        best = store;
      }
    }
    return best;
  }

  void openNearbyStamp() {
    final store = nearbyStore;
    if (store == null) {
      showAppNotice(context, '가게 칸이 켜질 때까지 골목을 걸어주세요.');
      return;
    }
    final floor = _blueprint?.floorForStore(store.id);
    if (floor != null && floor.id != _floorId) {
      setState(() => _floorId = floor.id);
    }
    showStorePreviewSheet(context, store, nearby: true);
  }

  double _distanceToRect(Offset point, Rect rect) {
    final nearest = Offset(
      point.dx.clamp(rect.left, rect.right),
      point.dy.clamp(rect.top, rect.bottom),
    );
    return (nearest - point).distance;
  }

  Store? _storeById(String id) {
    for (final store in widget.market.stores) {
      if (store.id == id) return store;
    }
    return null;
  }

  Offset _avatarCanvas(MarketBlueprint blueprint) {
    final here = _loc.current ?? widget.market.center;
    return gpsPathToUv(
      point: here,
      gpsPath: GwangjuMarkets.yangdongDemoPath,
      uvPath: blueprint.gpsFloor.route,
    );
  }

  double get _scale => _controller.value.getMaxScaleOnAxis();

  /// 시장이 차지한 영역만 화면에 맞춘다. 층 탭과 버튼은 도면 위에 떠 있다.
  void _fitPlan(Size viewport, Rect focus) {
    final availableWidth = viewport.width - 24;
    final availableHeight = viewport.height - _topInset - _bottomInset;
    if (availableWidth <= 0 || availableHeight <= 0) return;

    final scale = math.min(
      availableWidth / focus.width,
      availableHeight / focus.height,
    );
    _applyTransform(
      scale: scale,
      dx: 12 + (availableWidth - focus.width * scale) / 2 - focus.left * scale,
      dy: _topInset +
          (availableHeight - focus.height * scale) / 2 -
          focus.top * scale,
    );
  }

  void _focusOn(Offset canvasPoint, {double scale = 1.0}) {
    if (_viewport == Size.zero) return;
    _applyTransform(
      scale: scale,
      dx: _viewport.width / 2 - canvasPoint.dx * scale,
      dy: _viewport.height * 0.44 - canvasPoint.dy * scale,
    );
  }

  void _applyTransform({
    required double scale,
    required double dx,
    required double dy,
  }) {
    // z축까지 같이 키워야 getMaxScaleOnAxis()가 실제 배율을 돌려준다.
    _controller.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(2, 2, scale)
      ..setEntry(0, 3, dx)
      ..setEntry(1, 3, dy);
  }

  void _onPlanTap(Offset canvasPoint, MarketFloor floor) {
    final selected = _selectedWingId == null
        ? null
        : floor.blockById(_selectedWingId!);
    if (selected != null) {
      for (final stall in selected.stalls) {
        if (!stall.contains(canvasPoint)) {
          continue;
        }
        _openStall(stall, floor);
        return;
      }
      if (!selected.rect.inflate(36).contains(canvasPoint)) {
        _showOverview();
      }
      return;
    }

    final block = floor.blockAt(canvasPoint);
    if (block == null) return;
    if (_filterUse != null && !block.matchesUse(_filterUse)) return;
    setState(() {
      _selectedWingId = block.id;
      _followUser = false;
    });
    _fitPlan(_viewport, block.rect.inflate(28));
  }

  void _showOverview() {
    final blueprint = _blueprint;
    setState(() => _selectedWingId = null);
    if (blueprint != null) {
      _fitPlan(_viewport, blueprint.focus);
    }
  }

  void _openStall(Stall stall, MarketFloor floor) {
    final storeId = stall.storeId;
    if (storeId != null) {
      final store = _storeById(storeId);
      if (store != null) {
        showStorePreviewSheet(
          context,
          store,
          nearby: _loc.isNear(store.position),
        );
        return;
      }
    }
    showAppNotice(
      context,
      stall.label,
      title: '점포 안내',
    );
  }

  void _openIndex(MarketFloor floor) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                Text(
                  '점포 목록',
                  style: GoogleFonts.jua(fontSize: 22, color: AppColors.navy),
                ),
                const SizedBox(height: 2),
                const Text(
                  '이름을 누르면 지도에서 그 자리를 보여줍니다.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                for (final block in floor.blocks) ...[
                  if (_filterUse != null && !block.matchesUse(_filterUse))
                    const SizedBox.shrink()
                  else ...[
                    const SizedBox(height: 16),
                    Text(
                      '${block.theme.emoji} ${block.code} · ${block.name}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final stall in block.stalls)
                      if (_filterUse == null || stall.use == _filterUse)
                        _IndexRow(
                          stall: stall,
                          visited: stall.storeId != null &&
                              _session.hasPainted(stall.storeId!),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedWingId = block.id;
                              _followUser = false;
                            });
                            _fitPlan(_viewport, block.rect.inflate(28));
                          },
                        ),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final blueprint = _blueprint;
    final floor = _floor;
    if (blueprint == null || floor == null) return _unavailable();

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (viewport != _viewport) {
          _viewport = viewport;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_selectedWingId != null) {
              final block = floor.blockById(_selectedWingId!);
              if (block != null) {
                _fitPlan(viewport, block.rect.inflate(28));
                return;
              }
            }
            if (_followUser && floor.isGpsFloor) {
              _focusOn(_avatarCanvas(blueprint), scale: 1.18);
              return;
            }
            _fitPlan(viewport, blueprint.focus);
          });
        }

        final nearby = nearbyStore;
        final nearbyFloor =
            nearby == null ? null : blueprint.floorForStore(nearby.id);

        return ColoredBox(
          color: AppColors.skyLight,
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _controller,
                constrained: false,
                minScale: 0.2,
                maxScale: 4.5,
                boundaryMargin: const EdgeInsets.all(420),
                child: SizedBox(
                  width: blueprint.canvas.width,
                  height: blueprint.canvas.height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        _onPlanTap(details.localPosition, floor),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          size: blueprint.canvas,
                          painter: FloorPlanPainter(
                            floor: floor,
                            paintedStoreIds: _session.paintedStoreIds,
                            activeStoreId: nearbyFloor?.id == floor.id
                                ? nearby?.id
                                : null,
                            showStallLabels:
                                _selectedWingId != null || _scale >= _labelScale,
                            selectedBlockId: _selectedWingId,
                            filterUse: _filterUse,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ..._storeMarkers(floor),
              if (floor.isGpsFloor) _avatarMarker(_avatarCanvas(blueprint)),
              _chrome(blueprint, floor, nearby, nearbyFloor),
              Positioned(
                left: 16,
                right: 16,
                bottom: 216,
                child: _demoWalkBar(floor, blueprint),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 158,
                child: PaintProgressBanner(
                  painted:
                      blueprint.paintProgress(_session.paintedStoreIds).painted,
                  total: blueprint.paintProgress(_session.paintedStoreIds).total,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _demoWalkBar(MarketFloor floor, MarketBlueprint blueprint) {
    final inSession = _loc.demoWalking;
    final paused = _loc.demoPaused;
    return Row(
      children: [
        if (inSession) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loc.stopDemoWalk,
              icon: const Icon(Icons.stop_rounded),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('시연 경로 정지'),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: !inSession
                ? () {
                    if (widget.market.id != GwangjuMarkets.yangdong.id) {
                      return;
                    }
                    setState(() {
                      _followUser = true;
                      _selectedWingId = null;
                      if (!floor.isGpsFloor) {
                        _floorId = blueprint.gpsFloor.id;
                      }
                    });
                    _loc.startYangdongDemoWalk();
                  }
                : paused
                    ? _loc.resumeDemoWalk
                    : _loc.pauseDemoWalk,
            icon: Icon(
              !inSession
                  ? Icons.directions_walk_rounded
                  : paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                !inSession
                    ? '골목 시연 걷기'
                    : paused
                        ? '이어서 걷기'
                        : '일시정지',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _unavailable() {
    return ColoredBox(
      color: AppColors.skyLight,
      child: SafeArea(
        child: Column(
          children: [
            _header(null),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '이 시장 평면도는 다음 단계에서 열립니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepBlue,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  /// 도면 좌표를 화면 좌표로 옮긴다. 핀과 아바타는 확대해도 크기가 그대로다.
  Offset _toScreen(Offset canvasPoint) =>
      MatrixUtils.transformPoint(_controller.value, canvasPoint);

  bool _isVisible(Offset screenPoint) {
    return screenPoint.dx > -80 &&
        screenPoint.dx < _viewport.width + 80 &&
        screenPoint.dy > -40 &&
        screenPoint.dy < _viewport.height + 80;
  }

  List<Widget> _storeMarkers(MarketFloor floor) {
    final showLabels = _scale >= _markerLabelScale;
    final markers = <Widget>[];
    for (final stall in floor.demoStores) {
      final store = _storeById(stall.storeId!);
      if (store == null) continue;
      final screen = _toScreen(stall.anchor);
      if (!_isVisible(screen)) continue;

      final active = _loc.isNear(store.position);
      markers.add(
        Positioned(
          left: screen.dx - 54,
          top: screen.dy - 60,
          width: 108,
          child: _StoreMarker(
            store: store,
            active: active,
            visited: _session.hasPainted(store.id),
            showLabel: active || showLabels,
            pulse: _pulse,
            onTap: () => showStorePreviewSheet(context, store, nearby: active),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _avatarMarker(Offset canvasPoint) {
    final screen = _toScreen(canvasPoint);
    return Positioned(
      left: screen.dx - 23,
      top: screen.dy - 68,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -3 * _pulse.value),
            child: child,
          ),
          child: Column(
            children: [
              Image.asset(
                AppAssets.playAvatar,
                width: 46,
                height: 58,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              Container(
                width: 26,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chrome(
    MarketBlueprint blueprint,
    MarketFloor floor,
    Store? nearby,
    MarketFloor? nearbyFloor,
  ) {
    final sameFloor = nearbyFloor == null || nearbyFloor.id == floor.id;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _header(floor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: MarketMapToolbar(
              categoryLabel: _filterUse == null
                  ? '카테고리 선택'
                  : '${_filterUse!.emoji} ${_filterUse!.labelKo}',
              floorLabel: '${floor.label} 선택',
              categoryActive: _filterUse != null,
              onCategory: () => showCategoryPicker(
                context: context,
                uses: floor.filterUses,
                selected: _filterUse,
                onSelected: (use) => setState(() => _filterUse = use),
              ),
              onFloor: () => showFloorPicker(
                context: context,
                floors: blueprint.floors,
                selectedId: floor.id,
                alertFloorId: nearbyFloor?.id,
                onSelected: (id) => setState(() {
                  _floorId = id;
                  _selectedWingId = null;
                }),
              ),
              onStores: () => _openIndex(floor),
            ),
          ),
          if (_selectedWingId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _Banner(
                text: '${floor.blockById(_selectedWingId!)?.code ?? '이 동'} 확대 중. 가게를 눌러 정보를 보세요.',
                actionLabel: '전체 지도',
                onAction: _showOverview,
              ),
            ),
          if (nearby != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _Banner(
                text: sameFloor
                    ? '${nearby.name} 칸이 켜졌습니다. 눌러서 QR을 찍으세요!'
                    : '${nearby.name}은 ${nearbyFloor.label}입니다. 층을 바꿔 확인하세요.',
                actionLabel: sameFloor ? null : '${nearbyFloor.label} 보기',
                onAction: sameFloor
                    ? null
                    : () => setState(() => _floorId = nearbyFloor.id),
              ),
            ),
          const Expanded(child: SizedBox.expand()),
          _bottomControls(blueprint, floor),
        ],
      ),
    );
  }

  Widget _bottomControls(MarketBlueprint blueprint, MarketFloor floor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 276),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          children: [
            _RoundButton(
              icon: Icons.my_location_rounded,
              tooltip: '내 위치 따라가기',
              onTap: () {
                setState(() {
                  _followUser = true;
                  _selectedWingId = null;
                  if (!floor.isGpsFloor) {
                    _floorId = blueprint.gpsFloor.id;
                  }
                });
                _focusOn(_avatarCanvas(blueprint), scale: 1.18);
              },
            ),
            const SizedBox(height: 8),
            _RoundButton(
              icon: Icons.zoom_out_map_rounded,
              tooltip: '전체 보기',
              onTap: () {
                setState(() {
                  _followUser = false;
                  _selectedWingId = null;
                });
                _fitPlan(_viewport, blueprint.focus);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(MarketFloor? floor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: Material(
        color: const Color(0xF2FFF8E8),
        borderRadius: BorderRadius.circular(22),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.navy,
              ),
              Image.asset(AppAssets.emblem, width: 40, height: 40),
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
                    Text(
                      floor == null ? '평면도 준비 중' : floor.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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

class _IndexRow extends StatelessWidget {
  const _IndexRow({
    required this.stall,
    required this.visited,
    required this.onTap,
  });

  final Stall stall;
  final bool visited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: visited ? AppColors.goldDeep : stall.use.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                stall.use.icon,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${stall.use.emoji} ${stall.label}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: stall.use == StallUse.vacant
                      ? const Color(0xFF8A93A0)
                      : AppColors.ink,
                ),
              ),
            ),
            if (stall.isDemoStore)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '마감할인',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoreMarker extends StatelessWidget {
  const _StoreMarker({
    required this.store,
    required this.active,
    required this.visited,
    required this.showLabel,
    required this.pulse,
    required this.onTap,
  });

  final Store store;
  final bool active;
  final bool visited;
  final bool showLabel;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final glow = active ? 0.3 + pulse.value * 0.4 : 0.0;
          return Column(
            children: [
              SizedBox(
                height: 44,
                width: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (active)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: glow * 0.45),
                        ),
                      ),
                    Image.asset(
                      active
                          ? AppAssets.pinStoreActive
                          : AppAssets.pinStoreIdle,
                      width: active ? 40 : 30,
                      height: active ? 40 : 30,
                      filterQuality: FilterQuality.high,
                    ),
                    if (visited)
                      Positioned(
                        right: 2,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showLabel)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.gold
                        : Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active
                          ? AppColors.goldDeep
                          : const Color(0xFFD5DEE7),
                    ),
                  ),
                  child: Text(
                    store.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gold,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  fontSize: 13,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 21, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}
