import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../map/market_blueprint.dart';
import '../theme/app_colors.dart';

/// 2D 시장 평면도를 게임 보드처럼 그린다.
/// 시연 걷기 경로는 그리지 않는다.
class FloorPlanPainter extends CustomPainter {
  const FloorPlanPainter({
    required this.floor,
    required this.visitedStoreIds,
    required this.activeStoreId,
    required this.showStallLabels,
  });

  final MarketFloor floor;
  final Set<String> visitedStoreIds;
  final String? activeStoreId;

  /// 확대했을 때만 개별 점포 이름을 보여준다.
  final bool showStallLabels;

  static const _paper = Color(0xFFF6F2E8);
  static const _paperDot = Color(0x14123A63);
  static const _streetFill = Color(0xFFE6EDF4);
  static const _streetEdge = Color(0xFFCBD8E4);
  static const _blockFill = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (floor.backgroundAsset != null) {
      _paintOverlay(canvas);
      return;
    }

    _paintPaper(canvas, size);
    for (final street in floor.streets) {
      _paintStreet(canvas, street);
    }
    for (final block in floor.blocks) {
      _paintBlock(canvas, block);
    }
    for (final facility in floor.facilities) {
      _paintFacility(canvas, facility);
    }
  }

  void _paintOverlay(Canvas canvas) {
    for (final label in floor.labels) {
      _paintMapLabel(canvas, label);
    }
    for (final stall in floor.stalls) {
      final active = stall.storeId != null && stall.storeId == activeStoreId;
      final visited =
          stall.storeId != null && visitedStoreIds.contains(stall.storeId);
      if (active) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            stall.rect.inflate(6),
            const Radius.circular(10),
          ),
          Paint()
            ..color = AppColors.gold.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      if (visited) {
        final badge = Offset(stall.rect.right - 8, stall.rect.top + 8);
        canvas.drawCircle(badge, 8, Paint()..color = AppColors.gold);
        _drawIcon(canvas, Icons.check_rounded, badge, 11, AppColors.navy);
      }
      if (showStallLabels) {
        _drawText(
          canvas,
          stall.label,
          stall.rect.center,
          TextStyle(
            fontSize: 12,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: const [
              Shadow(color: Color(0xB0000000), blurRadius: 6),
            ],
          ),
          maxWidth: stall.rect.width,
          maxLines: 2,
        );
      }
    }
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
          shadows: const [
            Shadow(color: Color(0xE6FFF8E8), blurRadius: 8, offset: Offset(0, 1)),
          ],
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

  void _paintStreet(Canvas canvas, Street street) {
    final rrect = RRect.fromRectAndRadius(
      street.rect,
      const Radius.circular(18),
    );
    canvas.drawRRect(rrect, Paint()..color = _streetFill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _streetEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final center = street.rect.center;
    final dash = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    if (street.isVertical) {
      for (var y = street.rect.top + 26; y < street.rect.bottom - 26; y += 34) {
        canvas.drawLine(Offset(center.dx, y), Offset(center.dx, y + 16), dash);
      }
    } else {
      for (var x = street.rect.left + 26; x < street.rect.right - 26; x += 34) {
        canvas.drawLine(Offset(x, center.dy), Offset(x + 16, center.dy), dash);
      }
    }

    final label = street.label;
    if (label != null && showStallLabels) {
      final style = TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.deepBlue.withValues(alpha: 0.45),
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
          Offset(street.rect.left + 62, street.rect.center.dy),
          style,
          maxWidth: 160,
        );
      }
    }
  }

  void _paintBlock(Canvas canvas, MarketBlock block) {
    final theme = block.theme.color;
    final rrect = RRect.fromRectAndRadius(block.rect, const Radius.circular(16));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x1A123A63),
    );
    canvas.drawRRect(rrect, Paint()..color = _blockFill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = theme.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );

    final ribbon = RRect.fromRectAndCorners(
      Rect.fromLTWH(block.rect.left, block.rect.top, block.rect.width, 32),
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
    );
    canvas.drawRRect(ribbon, Paint()..color = theme);
    _drawIcon(
      canvas,
      block.theme.icon,
      Offset(block.rect.left + 22, block.rect.top + 16),
      16,
      Colors.white,
    );
    _drawText(
      canvas,
      block.name,
      Offset(block.rect.center.dx + 10, block.rect.top + 16),
      const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1,
      ),
      maxWidth: block.rect.width - 60,
      maxLines: 1,
    );

    for (final stall in block.stalls) {
      _paintStall(canvas, stall);
    }
  }

  void _paintStall(Canvas canvas, Stall stall) {
    final color = stall.use.color;
    final rrect = RRect.fromRectAndRadius(stall.rect, const Radius.circular(8));
    final isDemo = stall.isDemoStore;
    final isActive = stall.storeId != null && stall.storeId == activeStoreId;
    final visited =
        stall.storeId != null && visitedStoreIds.contains(stall.storeId);

    canvas.drawRRect(
      rrect,
      Paint()..color = color.withValues(alpha: isDemo ? 0.92 : 0.28),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isDemo
            ? (isActive ? AppColors.gold : color)
            : color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isDemo ? 3 : 1.4,
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

    if (showStallLabels) {
      _drawText(
        canvas,
        stall.label,
        stall.rect.center,
        TextStyle(
          fontSize: 11,
          height: 1.12,
          fontWeight: isDemo ? FontWeight.w900 : FontWeight.w700,
          color: isDemo ? Colors.white : AppColors.ink.withValues(alpha: 0.78),
        ),
        maxWidth: stall.rect.width - 6,
        maxLines: 2,
      );
    } else if (isDemo) {
      _drawIcon(
        canvas,
        stall.use.icon,
        stall.rect.center,
        math.min(stall.rect.height * 0.5, 22),
        Colors.white,
      );
    }

    if (visited) {
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
        !setEquals(old.visitedStoreIds, visitedStoreIds);
  }
}
