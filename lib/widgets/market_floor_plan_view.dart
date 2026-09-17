import 'package:flutter/material.dart';

import '../map/market_floor_plan.dart';
import '../models/market.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';

class MarketFloorPlanView extends StatelessWidget {
  const MarketFloorPlanView({
    super.key,
    required this.market,
    required this.session,
  });

  final Market market;
  final AppSession session;

  Store _store(String id) => market.stores.firstWhere((s) => s.id == id);

  @override
  Widget build(BuildContext context) {
    final zones = MarketFloorPlan.zonesFor(market);
    if (zones.isEmpty) {
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

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final area = Size(constraints.maxWidth, constraints.maxHeight);
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFF4F1EA)),
                const CustomPaint(painter: FloorPlanBasePainter()),
                for (final entry in zones.entries)
                  _zone(
                    context,
                    store: _store(entry.key),
                    rect: entry.value,
                    area: area,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _zone(
    BuildContext context, {
    required Store store,
    required Rect rect,
    required Size area,
  }) {
    final visited = session.hasEverVisited(store.id);
    final color = MarketFloorPlan.paintFor(store.id);
    final labelColor = visited
        ? (color.computeLuminance() > 0.55 ? AppColors.navy : Colors.white)
        : const Color(0xFF8A93A0);
    return Positioned(
      left: rect.left * area.width,
      top: rect.top * area.height,
      width: rect.width * area.width,
      height: rect.height * area.height,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: visited ? color : const Color(0xFFFBFBFD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: visited ? color.withValues(alpha: 0.9) : const Color(0xFFC9D0D8),
              width: visited ? 1.6 : 1.2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              showAppNotice(
                context,
                visited ? '${store.name} · 방문 완료' : '${store.name} · 아직 방문 전',
              );
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  store.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FloorPlanBasePainter extends CustomPainter {
  const FloorPlanBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final alley = Paint()..color = const Color(0xFFD9E3EA);
    final alleyStroke = Paint()
      ..color = const Color(0xFFB7C4CE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final corridor = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.40,
        size.height * 0.07,
        size.width * 0.20,
        size.height * 0.86,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(corridor, alley);
    canvas.drawRRect(corridor, alleyStroke);

    final north = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.navy,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    north.paint(canvas, Offset(size.width * 0.50 - north.width / 2, 4));

    final gate = TextPainter(
      text: const TextSpan(
        text: '정문',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.deepBlue,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gate.paint(
      canvas,
      Offset(size.width * 0.50 - gate.width / 2, size.height - 16),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StorePaintLegend extends StatelessWidget {
  const StorePaintLegend({
    super.key,
    required this.stores,
    required this.session,
  });

  final List<Store> stores;
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final store in stores)
          _LegendChip(
            store: store,
            visited: session.hasEverVisited(store.id),
          ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.store, required this.visited});

  final Store store;
  final bool visited;

  @override
  Widget build(BuildContext context) {
    final color = MarketFloorPlan.paintFor(store.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: visited ? color.withValues(alpha: 0.16) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: visited ? color : const Color(0xFFD1D5DB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: visited ? color : Colors.white,
              border: Border.all(
                color: visited ? color : const Color(0xFF9AA3AF),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            store.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: visited ? AppColors.navy : const Color(0xFF9AA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
