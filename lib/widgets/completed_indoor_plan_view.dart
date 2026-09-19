import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/sangju_indoor_map.dart';
import '../map/market_blueprint.dart';
import '../map/sangju_indoor_painter.dart';
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
  SangjuIndoorMap? _data;
  int _floor = 1;
  StallUse? _filterUse;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SangjuIndoorMap.load();
    if (!mounted) return;
    setState(() => _data = data);
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

    final visited = widget.session.qrVerifiedStoreIds;
    final painted = data.stalls.where((s) => visited.contains(s.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaintProgressBanner(painted: painted, total: data.stalls.length),
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
          aspectRatio: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: const Color(0xFFF7F4EC),
              child: InteractiveViewer(
                minScale: 0.35,
                maxScale: 4.5,
                child: CustomPaint(
                  size: data.mapSize,
                  painter: SangjuIndoorPainter(
                    stalls: data.stalls,
                    mapSize: data.mapSize,
                    pad: data.pad,
                    scale: 1.1,
                    matrix: Matrix4.identity()
                      ..translateByDouble(-data.pad, -data.pad, 0, 1),
                    floorFilter: _floor,
                    useFilter: _filterUse,
                    visitedIds: Set<String>.of(visited),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openIndex(SangjuIndoorMap data, Set<String> visited) {
    final listed = data.uniqueNamed(
      data.stallsOnFloor(_floor, use: _filterUse),
    );
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
                      visited.contains(stall.id) ? 'QR 인증 · 색칠됨' : '아직 방문 전',
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
