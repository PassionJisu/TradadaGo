import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'market_blueprint.dart';
import '../models/indoor_stall.dart';
import '../theme/app_colors.dart';
import 'indoor_camera.dart';

class SangjuIndoorPainter extends CustomPainter {
  SangjuIndoorPainter({
    required this.stalls,
    required this.mapSize,
    required this.pad,
    required this.scale,
    required this.matrix,
    this.highlightId,
    this.floorFilter,
    this.useFilter,
    this.visitedIds = const {},
  });

  final List<IndoorStall> stalls;
  final Size mapSize;
  final double pad;
  final double scale;
  final Matrix4 matrix;
  final String? highlightId;
  final int? floorFilter;
  final StallUse? useFilter;
  final Set<String> visitedIds;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(matrix.storage);

    final world = Size(mapSize.width + pad * 2, mapSize.height + pad * 2);
    final grass = Paint()..color = const Color(0xFF8FCB5A);
    canvas.drawRect(Offset.zero & world, grass);

    _drawGroundPattern(canvas, world);

    final market = Rect.fromLTWH(pad, pad, mapSize.width, mapSize.height);
    final plaza = market.inflate(90);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plaza, const Radius.circular(48)),
      Paint()..color = const Color(0xFFC9B89A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(market, const Radius.circular(28)),
      Paint()..color = const Color(0xFFD9D3C6),
    );

    final alley = Paint()..color = const Color(0xFFC5BDB0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(market.deflate(18), const Radius.circular(18)),
      alley,
    );

    for (final stall in stalls) {
      if (floorFilter != null && stall.floor != floorFilter) continue;
      _drawStall(
        canvas,
        stall,
        stall.id == highlightId,
        faded: useFilter != null && stall.use != useFilter,
        visited: visitedIds.contains(stall.id),
      );
    }

    if (scale >= IndoorCamera.labelMinScale) {
      final labeled = pickLabels([
        for (final stall in stalls)
          if ((floorFilter == null || stall.floor == floorFilter) &&
              (useFilter == null || stall.use == useFilter))
            stall,
      ], scale);
      for (final stall in labeled) {
        _drawLabel(canvas, stall);
      }
    }

    final gate = TextPainter(
      text: const TextSpan(
        text: '정문',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.navy,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gate.paint(
      canvas,
      Offset(
        pad + mapSize.width / 2 - gate.width / 2,
        pad + mapSize.height - 36,
      ),
    );
    canvas.restore();
  }

  void _drawGroundPattern(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x3380B34A)
      ..strokeWidth = 8;
    for (var x = 0.0; x < size.width; x += 140) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += 140) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  static List<IndoorStall> pickLabels(List<IndoorStall> stalls, double scale) {
    final ranked = [...stalls]..sort((a, b) {
        final aa = a.bounds.width * a.bounds.height;
        final ba = b.bounds.width * b.bounds.height;
        return ba.compareTo(aa);
      });
    final occupied = <Rect>[];
    final kept = <IndoorStall>[];
    for (final stall in ranked) {
      final minSide = math.min(stall.bounds.width, stall.bounds.height);
      if (minSide * scale < 28) continue;
      final font = (10 + scale * 2).clamp(9.0, 15.0);
      final painter = TextPainter(
        text: TextSpan(
          text: stall.name,
          style: TextStyle(
            fontSize: font,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: math.max(8, stall.bounds.width - 6));
      final rect = Rect.fromCenter(
        center: stall.bounds.center,
        width: painter.width,
        height: painter.height,
      ).inflate(6);
      if (occupied.any((placed) => placed.overlaps(rect))) continue;
      occupied.add(rect);
      kept.add(stall);
    }
    return kept;
  }

  void _drawStall(
    Canvas canvas,
    IndoorStall stall,
    bool highlight, {
    required bool faded,
    required bool visited,
  }) {
    const unvisited = Color(0xFFFFFFFF);
    var fill = visited
        ? (stall.floor == 2 ? const Color(0xFFC9B8D9) : stall.use.color)
        : unvisited;
    if (faded) fill = fill.withValues(alpha: visited ? 0.28 : 0.7);
    canvas.drawPath(stall.path, Paint()..color = fill);
    canvas.drawPath(
      stall.path,
      Paint()
        ..color = highlight
            ? AppColors.goldDeep
            : (visited ? const Color(0xFF8A7A64) : const Color(0xFFD5DEE7))
                .withValues(alpha: faded ? 0.35 : 1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 4 : (visited ? 1.4 : 1.1),
    );
    if (highlight) {
      canvas.drawPath(
        stall.path,
        Paint()..color = AppColors.gold.withValues(alpha: 0.28),
      );
    }
  }

  void _drawLabel(Canvas canvas, IndoorStall stall) {
    final minSide = math.min(stall.bounds.width, stall.bounds.height);
    if (minSide * scale < 28) return;
    final font = (10 + scale * 2).clamp(9, 15).toDouble();
    final painter = TextPainter(
      text: TextSpan(
        text: stall.name,
        style: TextStyle(
          fontSize: font,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
          height: 1.05,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: stall.bounds.width - 6);
    painter.paint(
      canvas,
      stall.bounds.center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant SangjuIndoorPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.highlightId != highlightId ||
        oldDelegate.matrix != matrix ||
        oldDelegate.floorFilter != floorFilter ||
        oldDelegate.useFilter != useFilter ||
        oldDelegate.stalls != stalls ||
        !setEquals(oldDelegate.visitedIds, visitedIds);
  }
}
