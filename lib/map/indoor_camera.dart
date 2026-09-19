import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/indoor_stall.dart';

class IndoorCamera {
  IndoorCamera({
    required this.mapSize,
    required this.pad,
    required this.focus,
  });

  final Size mapSize;
  final double pad;
  Offset focus;
  double scale = 0.45;
  double rotation = 0;

  Size get worldSize => Size(mapSize.width + pad * 2, mapSize.height + pad * 2);

  Offset characterScreen(Size viewport) =>
      Offset(viewport.width / 2, viewport.height * 0.62);

  double minScale(Size viewport) {
    return math.min(
      viewport.width / mapSize.width,
      viewport.height / mapSize.height,
    );
  }

  static const maxScale = 4.8;

  void clampScale(Size viewport) {
    scale = scale.clamp(minScale(viewport), maxScale);
  }

  void clampFocus() {
    final min = Offset(pad + 60, pad + 60);
    final max = Offset(
      pad + mapSize.width - 60,
      pad + mapSize.height - 60,
    );
    focus = Offset(
      focus.dx.clamp(min.dx, max.dx),
      focus.dy.clamp(min.dy, max.dy),
    );
  }

  Offset screenVectorToWorld(Offset delta) {
    final d = delta / scale;
    final c = math.cos(-rotation);
    final s = math.sin(-rotation);
    return Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c);
  }

  void panByScreenDelta(Offset delta) {
    focus -= screenVectorToWorld(delta);
    clampFocus();
  }

  void walkInView(Offset viewDir, double worldPixels) {
    final len = viewDir.distance;
    if (len < 0.001) return;
    final n = viewDir / len;
    focus += screenVectorToWorld(n * worldPixels * scale);
    clampFocus();
  }

  Offset screenToWorld(Offset screen, Size viewport) {
    return focus + screenVectorToWorld(screen - characterScreen(viewport));
  }

  Matrix4 mapMatrix(Size viewport) {
    final origin = characterScreen(viewport);
    return Matrix4.identity()
      ..translateByDouble(origin.dx, origin.dy, 0, 1)
      ..rotateZ(rotation)
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-focus.dx, -focus.dy, 0, 1);
  }

  IndoorStall? hit(Offset world, List<IndoorStall> stalls) {
    for (final stall in stalls.reversed) {
      if (stall.path.contains(world)) return stall;
    }
    return null;
  }
}
