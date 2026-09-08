import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

Offset geoToWorld(NLatLng point, NLatLngBounds bounds, Size world) {
  final lngSpan = bounds.eastLongitude - bounds.westLongitude;
  final latSpan = bounds.northLatitude - bounds.southLatitude;
  final nx =
      ((point.longitude - bounds.westLongitude) / lngSpan).clamp(0.08, 0.92);
  final ny =
      ((bounds.northLatitude - point.latitude) / latSpan).clamp(0.14, 0.88);
  return Offset(nx * world.width, ny * world.height);
}

/// GPS 시연 경로와 조감도 경로를 같은 진행률로 맞춘다.
Offset gpsPathToUv({
  required NLatLng point,
  required List<NLatLng> gpsPath,
  required List<Offset> uvPath,
}) {
  if (uvPath.isEmpty) return const Offset(0.5, 0.6);
  if (gpsPath.length < 2 || gpsPath.length != uvPath.length) {
    return uvPath.first;
  }

  var bestIndex = 0;
  var bestT = 0.0;
  var bestDist = double.infinity;

  for (var i = 0; i < gpsPath.length - 1; i++) {
    final projected = _project(point, gpsPath[i], gpsPath[i + 1]);
    if (projected.distance < bestDist) {
      bestDist = projected.distance;
      bestIndex = i;
      bestT = projected.t;
    }
  }

  return Offset.lerp(uvPath[bestIndex], uvPath[bestIndex + 1], bestT)!;
}

({double t, double distance}) _project(NLatLng point, NLatLng a, NLatLng b) {
  final dx = b.longitude - a.longitude;
  final dy = b.latitude - a.latitude;
  final length2 = dx * dx + dy * dy;
  final t = length2 == 0
      ? 0.0
      : (((point.longitude - a.longitude) * dx +
                (point.latitude - a.latitude) * dy) /
            length2)
          .clamp(0.0, 1.0);
  final qx = a.longitude + dx * t;
  final qy = a.latitude + dy * t;
  final distX = point.longitude - qx;
  final distY = point.latitude - qy;
  return (t: t, distance: distX * distX + distY * distY);
}
