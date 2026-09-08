import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../models/reservation.dart';
import '../models/store.dart';

class AppSession extends ChangeNotifier {
  AppSession._();
  static final AppSession instance = AppSession._();

  bool loggedIn = false;
  String displayName = '관리자';
  final Set<String> stampedStoreIds = {};
  final List<Reservation> reservations = [];

  bool login(String id, String password) {
    if (id.trim() == Env.adminId && password == Env.adminPassword) {
      loggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    loggedIn = false;
    notifyListeners();
  }

  bool hasStamp(String storeId) => stampedStoreIds.contains(storeId);

  bool addStamp(String storeId) {
    if (stampedStoreIds.contains(storeId)) return false;
    stampedStoreIds.add(storeId);
    notifyListeners();
    return true;
  }

  void addReservation({
    required Store store,
    required String productName,
    required int price,
  }) {
    reservations.insert(
      0,
      Reservation(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        storeId: store.id,
        storeName: store.name,
        productName: productName,
        price: price,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
