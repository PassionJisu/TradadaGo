import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/indoor_stall.dart';
import '../theme/app_colors.dart';

class SangjuIndoorPainter extends CustomPainter {
  SangjuIndoorPainter({
    required this.stalls,
    required this.mapSize,
    required this.pad,
    required this.scale,
    required this.matrix,
    this.highlightId,
  });

  final List<IndoorStall> stalls;
  final Size mapSize;
  final double pad;
  final double scale;
  final Matrix4 matrix;
  final String? highlightId;

  static const _roofs = <Color>[
    Color(0xFFE8D5B5),
    Color(0xFFD9C4A0),
    Color(0xFFE2C9B0),
    Color(0xFFD7B58A),
    Color(0xFFC9D6C2),
    Color(0xFFD4C8BE),
    Color(0xFFE6D0A8),
    Color(0xFFCBB79A),
    Color(0xFFDCC6AA),
    Color(0xFFC5B49A),
  ];

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
      _drawStall(canvas, stall, stall.id == highlightId);
    }

    if (scale > 0.85) {
      for (final stall in stalls) {
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

  void _drawStall(Canvas canvas, IndoorStall stall, bool highlight) {
    final roof = _roofs[stall.id.hashCode.abs() % _roofs.length];
    final fill = stall.floor == 2 ? const Color(0xFFC9B8D9) : roof;
    canvas.drawPath(stall.path, Paint()..color = fill);
    canvas.drawPath(
      stall.path,
      Paint()
        ..color = highlight ? AppColors.goldDeep : const Color(0xFF8A7A64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 4 : 1.4,
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
        oldDelegate.stalls != stalls;
  }
}
