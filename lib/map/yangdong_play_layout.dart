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
