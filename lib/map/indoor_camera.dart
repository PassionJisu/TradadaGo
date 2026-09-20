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
  double scale = startScale;
  double rotation = 0;

  static const referenceScale = 0.45;
  static const labelMinScale = 0.86;
  static const startScale = 1.1;
  static const avatarBaseSize = Size(22, 36);
  static const avatarShadowSize = Size(9, 3);

  Size get worldSize => Size(mapSize.width + pad * 2, mapSize.height + pad * 2);

  Offset characterScreen(Size viewport) =>
      Offset(viewport.width / 2, viewport.height * 0.62);

  /// Avatar is a fixed size on the map, so zoom in/out changes on-screen size.
  Size avatarScreenSize() => avatarBaseSize * (scale / referenceScale);

  Size avatarShadowScreenSize() => avatarShadowSize * (scale / referenceScale);

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

  Offset worldToScreen(Offset world, Size viewport) {
    final origin = characterScreen(viewport);
    final d = world - focus;
    final c = math.cos(rotation);
    final s = math.sin(rotation);
    return origin + Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c) * scale;
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

  /// 칸 안에 있지 않아도, 양동시장처럼 옆 골목에서 가까운 점포를 켠다.
  IndoorStall? nearest(Offset world, List<IndoorStall> stalls, {double maxDist = 72}) {
    IndoorStall? best;
    var bestDist = maxDist;
    for (final stall in stalls) {
      final d = distanceToRect(world, stall.bounds);
      if (d < bestDist) {
        bestDist = d;
        best = stall;
      }
    }
    return best;
  }

  static double distanceToRect(Offset point, Rect rect) {
    final nearest = Offset(
      point.dx.clamp(rect.left, rect.right),
      point.dy.clamp(rect.top, rect.bottom),
    );
    return (nearest - point).distance;
  }
}

/// 내부 지도 시연 경로를 일정 속도로 따라간다.
class IndoorPathWalker {
  IndoorPathWalker(this.path);

  final List<Offset> path;
  int index = 0;
  double t = 0;
  bool running = false;
  bool paused = false;

  static const pixelsPerTick = 5.0;

  bool get walking => running && !paused;

  Offset get position {
    if (path.isEmpty) return Offset.zero;
    if (index >= path.length - 1) return path.last;
    return Offset.lerp(path[index], path[index + 1], t.clamp(0, 1))!;
  }

  void start() {
    running = path.length >= 2;
    paused = false;
    index = 0;
    t = 0;
  }

  void pause() {
    if (running) paused = true;
  }

  void resume() {
    if (running) paused = false;
  }

  void stop() {
    running = false;
    paused = false;
  }

  Offset? tick({double pixels = pixelsPerTick}) {
    if (!running || paused || path.length < 2) return null;
    if (index >= path.length - 1) {
      running = false;
      return path.last;
    }

    var remaining = pixels;
    while (remaining > 0 && index < path.length - 1) {
      final from = path[index];
      final to = path[index + 1];
      final len = (to - from).distance;
      if (len < 0.001) {
        index += 1;
        t = 0;
        continue;
      }
      final left = (1 - t) * len;
      if (remaining >= left) {
        remaining -= left;
        index += 1;
        t = 0;
      } else {
        t += remaining / len;
        remaining = 0;
      }
    }

    if (index >= path.length - 1) {
      running = false;
      return path.last;
    }
    return position;
  }
}
