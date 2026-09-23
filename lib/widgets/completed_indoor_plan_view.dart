import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/sangju_indoor_map.dart';
import '../map/market_blueprint.dart';
import '../map/sangju_indoor_painter.dart';
import '../map/store_pin_images.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import 'market_map_controls.dart';

class CompletedIndoorPlanView extends StatefulWidget {
  const CompletedIndoorPlanView({super.key, required this.session});

  final AppSession session;

  @override
  State<CompletedIndoorPlanView> createState() => _CompletedIndoorPlanViewState();
}

class _CompletedIndoorPlanViewState extends State<CompletedIndoorPlanView> {
  final _controller = TransformationController();
  SangjuIndoorMap? _data;
  int _floor = 1;
  StallUse? _filterUse;
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  Future<void> _load() async {
    final data = await SangjuIndoorMap.load();
    if (!mounted) return;
    setState(() => _data = data);
    await StorePinImages.ensureLoaded();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _scale => _controller.value.getMaxScaleOnAxis();

  void _fit(Size viewport) {
    final data = _data;
    if (data == null || viewport.isEmpty) return;
    final map = data.mapSize;
    final scale = math.min(
      (viewport.width - 12) / map.width,
      (viewport.height - 12) / map.height,
    );
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - map.width * scale) / 2,
        (viewport.height - map.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final visited = widget.session.paintedStoreIds;
    final restaurants = data.restaurants;
    final painted = restaurants.where((s) => visited.contains(s.id)).length;
    final fit = _viewport.isEmpty
        ? 0.2
        : math.min(
            (_viewport.width - 12) / data.mapSize.width,
            (_viewport.height - 12) / data.mapSize.height,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaintProgressBanner(painted: painted, total: restaurants.length),
        const SizedBox(height: 8),
        MarketMapToolbar(
          categoryLabel: _filterUse == null
              ? '카테고리 선택'
              : '${_filterUse!.emoji} ${_filterUse!.labelKo}',
          floorLabel: '$_floor층 선택',
          categoryActive: _filterUse != null,
          onCategory: () => showCategoryPicker(
            context: context,
            uses: data.usesOnFloor(_floor),
            selected: _filterUse,
            onSelected: (use) => setState(() => _filterUse = use),
          ),
          onFloor: () => showFloorPicker(
            context: context,
            floors: data.floors,
            selectedId: '$_floor',
            onSelected: (id) => setState(() {
              _floor = int.parse(id);
              _filterUse = null;
            }),
          ),
          onStores: () => _openIndex(data, visited),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 5 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewport = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                if (viewport != _viewport && viewport.width > 0) {
                  _viewport = viewport;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fit(viewport);
                  });
                }
                return ColoredBox(
                  color: const Color(0xFFF7F4EC),
                  child: InteractiveViewer(
                    transformationController: _controller,
                    constrained: false,
                    minScale: math.max(0.08, fit * 0.92),
                    maxScale: 6,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: SizedBox(
                      width: data.mapSize.width,
                      height: data.mapSize.height,
                      child: CustomPaint(
                        size: data.mapSize,
                        painter: SangjuIndoorPainter(
                          stalls: data.stalls,
                          mapSize: data.mapSize,
                          pad: data.pad,
                          scale: _scale,
                          matrix: Matrix4.identity()
                            ..translateByDouble(-data.pad, -data.pad, 0, 1),
                          floorFilter: _floor,
                          useFilter: _filterUse,
                          visitedIds: Set<String>.of(visited),
                          clipToMarket: true,
                          pinIdle: StorePinImages.idle,
                          pinActive: StorePinImages.active,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openIndex(SangjuIndoorMap data, Set<String> visited) {
    final listed = data.uniqueNamed([
      for (final stall in data.stallsOnFloor(_floor, use: _filterUse))
        if (stall.hasMenu) stall,
    ]);
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
                const SizedBox(height: 8),
                for (final stall in listed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: stall.use.color.withValues(alpha: 0.18),
                      child: Text(stall.use.emoji),
                    ),
                    title: Text(
                      stall.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      visited.contains(stall.id) ? '리뷰 · 색칠됨' : '아직 리뷰 전',
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
