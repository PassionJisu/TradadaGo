import 'package:flutter/material.dart';

/// 데모용 조감도 위 좌표 (0~1). 실제 GPS와 같은 순서로 골목을 따라간다.
abstract final class YangdongPlayLayout {
  static const anchors = <String, Offset>{
    'yd-honguh': Offset(0.22, 0.80),
    'yd-gukbap': Offset(0.32, 0.70),
    'yd-gimbap': Offset(0.44, 0.61),
    'yd-yukhoe': Offset(0.50, 0.51),
    'yd-fruit': Offset(0.60, 0.43),
    'yd-susan': Offset(0.74, 0.38),
    'yd-tteok': Offset(0.80, 0.50),
    'yd-hanbok': Offset(0.68, 0.60),
    'yd-jeon': Offset(0.52, 0.70),
    'yd-gunbam': Offset(0.34, 0.78),
  };

  /// 방문한 가게를 칠할 때 쓰는 고유 색.
  static const paints = <String, Color>{
    'yd-honguh': Color(0xFFE53935),
    'yd-gukbap': Color(0xFFFB8C00),
    'yd-gimbap': Color(0xFF43A047),
    'yd-yukhoe': Color(0xFF8E24AA),
    'yd-fruit': Color(0xFFFDD835),
    'yd-susan': Color(0xFF1E88E5),
    'yd-tteok': Color(0xFFEC407A),
    'yd-hanbok': Color(0xFF5E35B1),
    'yd-jeon': Color(0xFF6D4C41),
    'yd-gunbam': Color(0xFF00897B),
  };

  static Color paintFor(String storeId) =>
      paints[storeId] ?? const Color(0xFF607D8B);

  /// 마이페이지 평면도 구역 (0~1). 왼쪽 열은 서편, 오른쪽 열은 동편.
  static const floorZones = <String, Rect>{
    'yd-fruit': Rect.fromLTWH(0.04, 0.08, 0.34, 0.15),
    'yd-yukhoe': Rect.fromLTWH(0.04, 0.25, 0.34, 0.15),
    'yd-gimbap': Rect.fromLTWH(0.04, 0.42, 0.34, 0.15),
    'yd-gukbap': Rect.fromLTWH(0.04, 0.59, 0.34, 0.15),
    'yd-honguh': Rect.fromLTWH(0.04, 0.76, 0.34, 0.16),
    'yd-susan': Rect.fromLTWH(0.62, 0.08, 0.34, 0.15),
    'yd-tteok': Rect.fromLTWH(0.62, 0.25, 0.34, 0.15),
    'yd-hanbok': Rect.fromLTWH(0.62, 0.42, 0.34, 0.15),
    'yd-jeon': Rect.fromLTWH(0.62, 0.59, 0.34, 0.15),
    'yd-gunbam': Rect.fromLTWH(0.62, 0.76, 0.34, 0.16),
  };

  static const path = <Offset>[
    Offset(0.18, 0.86),
    Offset(0.22, 0.80),
    Offset(0.32, 0.70),
    Offset(0.44, 0.61),
    Offset(0.50, 0.51),
    Offset(0.60, 0.43),
    Offset(0.74, 0.38),
    Offset(0.80, 0.50),
    Offset(0.68, 0.60),
    Offset(0.52, 0.70),
    Offset(0.34, 0.78),
    Offset(0.22, 0.82),
  ];
}
