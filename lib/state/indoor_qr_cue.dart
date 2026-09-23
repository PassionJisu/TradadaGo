import 'package:flutter/foundation.dart';

/// 시장 데모에서 식당 앞 QR이 켜졌는지. 가운데 버튼이 이 값을 본다.
class IndoorQrCue extends ChangeNotifier {
  IndoorQrCue._();
  static final IndoorQrCue instance = IndoorQrCue._();

  bool ready = false;
  String? storeName;

  void setReady({required bool ready, String? storeName}) {
    if (this.ready == ready && this.storeName == storeName) return;
    this.ready = ready;
    this.storeName = storeName;
    notifyListeners();
  }

  void clear() => setReady(ready: false);
}
