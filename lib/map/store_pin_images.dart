import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../config/assets.dart';

abstract final class StorePinImages {
  static ui.Image? idle;
  static ui.Image? active;

  static Future<void> ensureLoaded() async {
    idle ??= await _load(AppAssets.pinStoreIdle);
    active ??= await _load(AppAssets.pinStoreActive);
  }

  static Future<ui.Image> _load(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
