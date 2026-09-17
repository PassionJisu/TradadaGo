import 'package:flutter/material.dart';

/// Google Maps 스타일의 파란 내 위치 점.
class GoogleLocationDot extends StatelessWidget {
  const GoogleLocationDot({super.key});

  static const blue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(64, 64),
      painter: _GoogleLocationDotPainter(),
    );
  }
}

class _GoogleLocationDotPainter extends CustomPainter {
  const _GoogleLocationDotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center.translate(0, 1.5),
      16,
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawCircle(center, 15, Paint()..color = Colors.white);
    canvas.drawCircle(center, 11, Paint()..color = GoogleLocationDot.blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
