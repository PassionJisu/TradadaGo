import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/market_blueprints.dart';
import '../map/market_blueprint.dart';
import '../models/market.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import 'floor_plan_painter.dart';
import 'market_map_controls.dart';

/// 마이페이지용 색칠 지도. 플레이 화면과 같은 평면도·리뷰 색칠 규칙을 쓴다.
class MarketPaintedPlanView extends StatefulWidget {
  const MarketPaintedPlanView({
    super.key,
    required this.market,
    required this.session,
  });

  final Market market;
  final AppSession session;

  @override
  State<MarketPaintedPlanView> createState() => _MarketPaintedPlanViewState();
}

class _MarketPaintedPlanViewState extends State<MarketPaintedPlanView> {
  final _controller = TransformationController();
  MarketBlueprint? _blueprint;
  String? _floorId;
  String? _selectedWingId;
  StallUse? _filterUse;
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    _blueprint = MarketBlueprints.forMarket(widget.market);
    _floorId = _blueprint?.gpsFloor.id;
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  MarketFloor? get _floor {
    final blueprint = _blueprint;
    if (blueprint == null) return null;
    final id = _floorId;
    return id == null ? blueprint.gpsFloor : blueprint.floorById(id);
  }

  double get _scale => _controller.value.getMaxScaleOnAxis();

  Store? _storeById(String id) {
    for (final store in widget.market.stores) {
      if (store.id == id) return store;
    }
    return null;
  }

  void _fit(Rect focus) {
    final availableWidth = _viewport.width - 16;
    final availableHeight = _viewport.height - 16;
    if (availableWidth <= 0 || availableHeight <= 0) return;
    final scale = math.min(
      availableWidth / focus.width,
      availableHeight / focus.height,
    );
    _controller.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(2, 2, scale)
      ..setEntry(0, 3, 8 + (availableWidth - focus.width * scale) / 2 - focus.left * scale)
      ..setEntry(1, 3, 8 + (availableHeight - focus.height * scale) / 2 - focus.top * scale);
  }

  void _onTap(Offset point, MarketFloor floor) {
    final selected = _selectedWingId == null
        ? null
        : floor.blockById(_selectedWingId!);
    if (selected != null) {
      for (final stall in selected.stalls) {
        if (!stall.contains(point)) continue;
        final storeId = stall.storeId;
        final painted = storeId != null && widget.session.hasPainted(storeId);
        final store = storeId == null ? null : _storeById(storeId);
        showAppNotice(
          context,
          painted
              ? '${stall.label} · 리뷰로 색칠됨'
              : '${stall.label} · 아직 리뷰 전',
          title: store?.name ?? selected.code,
        );
        return;
      }
      if (!selected.rect.inflate(36).contains(point)) {
        setState(() => _selectedWingId = null);
        final blueprint = _blueprint;
        if (blueprint != null) _fit(blueprint.focus);
      }
      return;
    }

    final block = floor.blockAt(point);
    if (block == null) return;
    if (_filterUse != null && !block.matchesUse(_filterUse)) return;
    setState(() => _selectedWingId = block.id);
    _fit(block.rect.inflate(28));
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
                    for (final stall in block.stalls)
                      if (_filterUse == null || stall.use == _filterUse)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${stall.use.emoji} ${stall.label}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Text(
                            stall.storeId != null &&
                                    widget.session.hasPainted(stall.storeId!)
                                ? '색칠'
                                : '미색칠',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedWingId = block.id);
                            _fit(block.rect.inflate(28));
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
    if (blueprint == null || floor == null) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1EA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          '이 시장 평면도는 준비 중입니다.',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    final progress = blueprint.paintProgress(widget.session.paintedStoreIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaintProgressBanner(painted: progress.painted, total: progress.total),
        const SizedBox(height: 8),
        MarketMapToolbar(
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
            onSelected: (id) => setState(() {
              _floorId = id;
              _selectedWingId = null;
            }),
          ),
          onStores: () => _openIndex(floor),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 5 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewport = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                if (viewport != _viewport) {
                  _viewport = viewport;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final block = _selectedWingId == null
                        ? null
                        : floor.blockById(_selectedWingId!);
                    _fit(block?.rect.inflate(28) ?? blueprint.focus);
                  });
                }
                return ColoredBox(
                  color: const Color(0xFFF7F4EC),
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        transformationController: _controller,
                        constrained: false,
                        minScale: 0.2,
                        maxScale: 4.5,
                        boundaryMargin: const EdgeInsets.all(240),
                        child: SizedBox(
                          width: blueprint.canvas.width,
                          height: blueprint.canvas.height,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) =>
                                _onTap(details.localPosition, floor),
                            child: CustomPaint(
                              size: blueprint.canvas,
                              painter: FloorPlanPainter(
                                floor: floor,
                                paintedStoreIds: widget.session.paintedStoreIds,
                                activeStoreId: null,
                                showStallLabels:
                                    _selectedWingId != null || _scale >= 0.72,
                                selectedBlockId: _selectedWingId,
                                filterUse: _filterUse,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedWingId != null)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: _miniButton(
                            Icons.zoom_out_map_rounded,
                            () {
                              setState(() => _selectedWingId = null);
                              _fit(blueprint.focus);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.navy),
        ),
      ),
    );
  }
}
