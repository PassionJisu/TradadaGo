import 'dart:math' as math;
import 'dart:ui' as ui;

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
    this.routeId,
    this.activePinId,
    this.guide = const [],
    this.backdrop,
    this.floorFilter,
    this.useFilter,
    this.visitedIds = const {},
    this.clipToMarket = false,
    this.showDiscountPins = true,
    this.pinIdle,
    this.pinActive,
    this.rotation = 0,
  });

  final List<IndoorStall> stalls;
  final Size mapSize;
  final double pad;
  final double scale;
  final Matrix4 matrix;
  final String? highlightId;
  final String? routeId;
  final String? activePinId;
  final List<Offset> guide;
  final IndoorMapBackdrop? backdrop;
  final int? floorFilter;
  final StallUse? useFilter;
  final Set<String> visitedIds;
  final bool clipToMarket;
  final bool showDiscountPins;
  final ui.Image? pinIdle;
  final ui.Image? pinActive;
  final double rotation;

  int get _staticSignature => Object.hash(
        floorFilter,
        useFilter,
        (scale * 20).round(),
        (rotation * 100).round(),
        clipToMarket,
        stalls.length,
        Object.hashAll(visitedIds),
      );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(matrix.storage);
    if (clipToMarket) {
      canvas.clipRect(Rect.fromLTWH(pad, pad, mapSize.width, mapSize.height));
    }
    final cache = backdrop;
    if (cache == null) {
      _paintStatic(canvas);
    } else {
      cache.draw(canvas, _staticSignature, _paintStatic);
    }
    _paintDynamic(canvas);
    canvas.restore();
  }

  void _paintStatic(Canvas canvas) {
    final world = Size(mapSize.width + pad * 2, mapSize.height + pad * 2);
    if (!clipToMarket) {
      canvas.drawRect(
        Offset.zero & world,
        Paint()..color = const Color(0xFF8FCB5A),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(pad, pad, mapSize.width, mapSize.height),
        Paint()..color = const Color(0xFFD9D3C6),
      );
    }

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
    canvas.drawRRect(
      RRect.fromRectAndRadius(market.deflate(18), const Radius.circular(18)),
      Paint()..color = const Color(0xFFC5BDB0),
    );

    for (final stall in stalls) {
      if (floorFilter != null && stall.floor != floorFilter) continue;
      _drawStall(
        canvas,
        stall,
        false,
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
    _drawUpright(
      canvas,
      Offset(pad + mapSize.width / 2, pad + mapSize.height - 24),
      () {
        gate.paint(canvas, Offset(-gate.width / 2, -gate.height / 2));
      },
    );
  }

  void _paintDynamic(Canvas canvas) {
    for (final stall in stalls) {
      if (floorFilter != null && stall.floor != floorFilter) continue;
      final marked = stall.id == highlightId || stall.id == routeId;
      if (!marked) continue;
      _drawStall(
        canvas,
        stall,
        true,
        faded: false,
        visited: visitedIds.contains(stall.id),
        overlay: true,
      );
    }
    _drawGuide(canvas);
    _drawDiscountPins(canvas);
  }

  void _drawGuide(Canvas canvas) {
    if (guide.length < 2) return;
    final path = Path()..moveTo(guide.first.dx, guide.first.dy);
    for (final point in guide.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.goldDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final end = guide.last;
    canvas.drawCircle(end, 10, Paint()..color = AppColors.goldDeep);
    canvas.drawCircle(end, 5, Paint()..color = Colors.white);
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
    bool overlay = false,
  }) {
    const unvisited = Color(0xFFFFFFFF);
    var fill = visited
        ? (stall.floor == 2 ? const Color(0xFFC9B8D9) : stall.use.color)
        : unvisited;
    if (faded) fill = fill.withValues(alpha: visited ? 0.28 : 0.7);
    if (!overlay) canvas.drawPath(stall.path, Paint()..color = fill);
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
    _drawUpright(canvas, stall.bounds.center, () {
      painter.paint(
        canvas,
        Offset(-painter.width / 2, -painter.height / 2),
      );
    });
  }

  void _drawUpright(Canvas canvas, Offset worldAnchor, VoidCallback paint) {
    canvas.save();
    canvas.translate(worldAnchor.dx, worldAnchor.dy);
    canvas.rotate(-rotation);
    paint();
    canvas.restore();
  }

  static List<IndoorStall> pickDiscountPins(
    List<IndoorStall> stalls, {
    required double scale,
    int? floorFilter,
    StallUse? useFilter,
  }) {
    if (scale <= 0) return const [];
    return [
      for (final stall in stalls)
        if ((floorFilter == null || stall.floor == floorFilter) &&
            (useFilter == null || stall.use == useFilter) &&
            stall.hasDiscountProducts)
          stall,
    ];
  }

  void _drawDiscountPins(Canvas canvas) {
    if (!showDiscountPins) return;
    final pins = pickDiscountPins(
      stalls,
      scale: scale,
      floorFilter: floorFilter,
      useFilter: useFilter,
    );
    for (final stall in pins) {
      final highlight = stall.id == activePinId;
      final pinH = (highlight ? 38 : 32) / math.max(scale, 0.08);
      final image = highlight && pinActive != null ? pinActive : pinIdle;
      final aspect = image == null ? 0.72 : image.width / image.height;
      final pinW = pinH * aspect;
      final center = stall.bounds.center;
      _drawUpright(canvas, center, () {
        final dst = Rect.fromLTWH(-pinW / 2, -pinH, pinW, pinH);
        if (image != null) {
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            dst,
            Paint()..filterQuality = FilterQuality.low,
          );
        } else {
          _drawFallbackPin(canvas, dst, highlight);
        }
      });
    }
  }

  void _drawFallbackPin(Canvas canvas, Rect dst, bool highlight) {
    final path = Path()
      ..moveTo(dst.center.dx, dst.bottom)
      ..quadraticBezierTo(dst.left, dst.center.dy + dst.height * 0.08, dst.left, dst.top + dst.height * 0.38)
      ..arcToPoint(
        Offset(dst.right, dst.top + dst.height * 0.38),
        radius: Radius.circular(dst.width * 0.48),
        clockwise: true,
      )
      ..quadraticBezierTo(dst.right, dst.center.dy + dst.height * 0.08, dst.center.dx, dst.bottom)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = highlight ? AppColors.goldDeep : AppColors.gold,
    );
    canvas.drawCircle(
      Offset(dst.center.dx, dst.top + dst.height * 0.34),
      dst.width * 0.22,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant SangjuIndoorPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.highlightId != highlightId ||
        oldDelegate.routeId != routeId ||
        oldDelegate.activePinId != activePinId ||
        !listEquals(oldDelegate.guide, guide) ||
        oldDelegate.matrix != matrix ||
        oldDelegate.floorFilter != floorFilter ||
        oldDelegate.useFilter != useFilter ||
        oldDelegate.stalls != stalls ||
        !setEquals(oldDelegate.visitedIds, visitedIds) ||
        oldDelegate.clipToMarket != clipToMarket ||
        oldDelegate.showDiscountPins != showDiscountPins ||
        oldDelegate.pinIdle != pinIdle ||
        oldDelegate.pinActive != pinActive ||
        oldDelegate.rotation != rotation;
  }
}

/// 골목·점포처럼 자주 안 바뀌는 그림을 한 번만 기록한다.
class IndoorMapBackdrop {
  ui.Picture? _picture;
  int? _key;

  void dispose() {
    _picture?.dispose();
    _picture = null;
    _key = null;
  }

  void draw(Canvas canvas, int signature, void Function(Canvas canvas) paint) {
    if (_picture == null || _key != signature) {
      _picture?.dispose();
      final recorder = ui.PictureRecorder();
      paint(Canvas(recorder));
      _picture = recorder.endRecording();
      _key = signature;
    }
    canvas.drawPicture(_picture!);
  }
}
