import 'dart:io';

import 'package:flutter/material.dart';

/// 시연용 에셋과, 보관함·카메라에서 고른 파일 경로를 같이 그린다.
class ReviewPhoto extends StatelessWidget {
  const ReviewPhoto({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;

  static bool isAsset(String source) => source.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (isAsset(source)) {
      return Image.asset(source, width: width, height: height, fit: fit);
    }
    return Image.file(File(source), width: width, height: height, fit: fit);
  }
}
