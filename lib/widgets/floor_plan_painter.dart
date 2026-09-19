import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../map/market_blueprint.dart';
import '../theme/app_colors.dart';

/// 점포안내도 스타일. 동·가게는 기본 흰색이고, 내 리뷰가 있으면 업종 색으로 칠한다.
class FloorPlanPainter extends CustomPainter {
  const FloorPlanPainter({
    required this.floor,
    required this.paintedStoreIds,
    required this.activeStoreId,
    required this.showStallLabels,
    this.selectedBlockId,
    this.filterUse,
  });

  final MarketFloor floor;
  final Set<String> paintedStoreIds;
  final String? activeStoreId;
  final bool showStallLabels;
  final String? selectedBlockId;
  final StallUse? filterUse;

  static const _paper = Color(0xFFF7F4EC);
  static const _paperDot = Color(0x14123A63);
  static const _streetFill = Color(0xFFC2B093);
  static const _blankFill = Color(0xFFFBFCFD);
  static const _blankEdge = Color(0xFFD5DEE7);

  @override
  void paint(Canvas canvas, Size size) {
    _paintPaper(canvas, size);
    _paintStreetNetwork(canvas);
    for (final block in floor.blocks) {
      _paintBlock(canvas, block);
    }
    for (final facility in floor.facilities) {
      _paintFacility(canvas, facility);
    }
    for (final label in floor.labels) {
      _paintMapLabel(canvas, label);
    }
  }

  void _paintPaper(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _paper);
    final dot = Paint()..color = _paperDot;
    const step = 28.0;
    for (var y = step; y < size.height; y += step) {
      for (var x = step; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.4, dot);
      }
    }
  }

  void _paintStreetNetwork(Canvas canvas) {
    final path = Path();
    for (final street in floor.streets) {
      path.addRect(street.rect);
    }
    canvas.drawPath(path, Paint()..color = _streetFill);

    for (final street in floor.streets) {
      final label = street.label;
      if (label != null && (showStallLabels || selectedBlockId != null)) {
        final style = TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.deepBlue.withValues(alpha: 0.4),
        );
        if (street.isVertical) {
          canvas.save();
          canvas.translate(street.rect.center.dx, street.rect.top + 70);
          canvas.rotate(math.pi / 2);
          _drawText(canvas, label, Offset.zero, style, maxWidth: 160);
          canvas.restore();
        } else {
          _drawText(
            canvas,
            label,
            Offset(street.rect.left + 72, street.rect.center.dy),
            style,
            maxWidth: 180,
          );
        }
      }
    }
  }

  void _paintBlock(Canvas canvas, MarketBlock block) {
    final complete = block.isComplete(paintedStoreIds);
    final selected = block.id == selectedBlockId;
    final matching = block.matchesUse(filterUse);
    final dim = filterUse != null && !matching;
    final theme = block.theme.color;
    final fill = complete ? theme.withValues(alpha: 0.88) : _blankFill;
    final edge = complete
        ? theme
        : (selected ? AppColors.goldDeep : _blankEdge);
    final rrect = RRect.fromRectAndRadius(block.rect, const Radius.circular(16));

    canvas.save();
    if (dim) canvas.drawRRect(rrect, Paint()..color = const Color(0x00FFFFFF));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x1A123A63),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = fill.withValues(alpha: dim ? 0.28 : 1),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = (selected ? AppColors.gold : edge).withValues(
          alpha: dim ? 0.35 : 1,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 4 : 2.2,
    );

    final titleColor = complete
        ? Colors.white
        : AppColors.navy.withValues(alpha: dim ? 0.35 : 0.9);
    _drawText(
      canvas,
      block.code,
      Offset(block.rect.center.dx, block.rect.top + 22),
      TextStyle(
        fontSize: selected || showStallLabels ? 20 : 26,
        fontWeight: FontWeight.w900,
        color: titleColor,
        height: 1,
      ),
      maxWidth: block.rect.width - 12,
      maxLines: 1,
    );
    _drawText(
      canvas,
      block.name,
      Offset(block.rect.center.dx, block.rect.top + 44),
      TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: titleColor.withValues(alpha: complete ? 0.92 : 0.55),
        height: 1,
      ),
      maxWidth: block.rect.width - 16,
      maxLines: 1,
    );

    final revealStalls = selected || showStallLabels;
    if (revealStalls) {
      for (final stall in block.stalls) {
        _paintStall(canvas, stall, dim: dim && stall.use != filterUse);
      }
    } else if (complete) {
      _drawIcon(
        canvas,
        block.theme.icon,
        block.rect.center.translate(0, 16),
        28,
        Colors.white.withValues(alpha: dim ? 0.4 : 0.92),
      );
    }

    canvas.restore();
  }

  void _paintStall(Canvas canvas, Stall stall, {required bool dim}) {
    final painted =
        stall.storeId != null && paintedStoreIds.contains(stall.storeId);
    final isActive = stall.storeId != null && stall.storeId == activeStoreId;
    final color = stall.use.color;
    final fill = painted ? color.withValues(alpha: 0.94) : _blankFill;
    final rrect = RRect.fromRectAndRadius(stall.rect, const Radius.circular(8));

    canvas.drawRRect(
      rrect,
      Paint()..color = fill.withValues(alpha: dim ? 0.28 : 1),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = (isActive
                ? AppColors.gold
                : (painted ? color : _blankEdge))
            .withValues(alpha: dim ? 0.4 : 1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stall.isDemoStore ? 2.4 : 1.3,
    );

    if (isActive) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(stall.rect.inflate(5), const Radius.circular(11)),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    final labelColor = painted
        ? Colors.white
        : AppColors.ink.withValues(alpha: dim ? 0.35 : 0.78);
    _drawText(
      canvas,
      stall.label,
      stall.rect.center,
      TextStyle(
        fontSize: 11,
        height: 1.12,
        fontWeight: stall.isDemoStore ? FontWeight.w900 : FontWeight.w700,
        color: labelColor,
      ),
      maxWidth: stall.rect.width - 6,
      maxLines: 2,
    );

    if (painted) {
      final badge = Offset(stall.rect.right - 9, stall.rect.top + 9);
      canvas.drawCircle(badge, 8, Paint()..color = AppColors.gold);
      _drawIcon(canvas, Icons.check_rounded, badge, 11, AppColors.navy);
    }
  }

  void _paintFacility(Canvas canvas, Facility facility) {
    final isGate = facility.kind == FacilityKind.gate;
    final color = facility.kind.color;
    final rrect = RRect.fromRectAndRadius(
      facility.rect,
      Radius.circular(isGate ? 18 : 12),
    );

    canvas.drawRRect(
      rrect,
      Paint()..color = isGate ? AppColors.gold : Colors.white,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isGate ? AppColors.goldDeep : color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (isGate) {
      _drawIcon(
        canvas,
        facility.kind.icon,
        Offset(facility.rect.left + 26, facility.rect.center.dy),
        18,
        AppColors.navy,
      );
      _drawText(
        canvas,
        facility.label,
        Offset(facility.rect.center.dx + 12, facility.rect.center.dy),
        const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: AppColors.navy,
          height: 1,
        ),
        maxWidth: facility.rect.width - 40,
        maxLines: 1,
      );
      return;
    }

    _drawIcon(
      canvas,
      facility.kind.icon,
      Offset(facility.rect.center.dx, facility.rect.top + 24),
      22,
      color,
    );
    _drawText(
      canvas,
      facility.label,
      Offset(facility.rect.center.dx, facility.rect.bottom - 20),
      TextStyle(
        fontSize: 11,
        height: 1.1,
        fontWeight: FontWeight.w800,
        color: color.withValues(alpha: 0.95),
      ),
      maxWidth: facility.rect.width - 4,
      maxLines: 2,
    );
  }

  void _paintMapLabel(Canvas canvas, MapLabel label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label.text,
        style: TextStyle(
          fontSize: label.fontSize,
          height: 1,
          fontWeight: FontWeight.w900,
          color: label.color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(label.at.dx - painter.width / 2, label.at.dy - painter.height / 2),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style, {
    double maxWidth = 200,
    int maxLines = 2,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: math.max(maxWidth, 12));
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _drawIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter old) {
    return old.floor != floor ||
        old.showStallLabels != showStallLabels ||
        old.activeStoreId != activeStoreId ||
        old.selectedBlockId != selectedBlockId ||
        old.filterUse != filterUse ||
        !setEquals(old.paintedStoreIds, paintedStoreIds);
  }
}
