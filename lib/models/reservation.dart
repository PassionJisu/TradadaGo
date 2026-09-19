enum UsageKind { pickup, qrVisit }

class Reservation {
  const Reservation({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.productName,
    required this.price,
    required this.createdAt,
    this.kind = UsageKind.pickup,
  });

  final String id;
  final String storeId;
  final String storeName;
  final String productName;
  final int price;
  final DateTime createdAt;
  final UsageKind kind;

  bool get isQrVisit => kind == UsageKind.qrVisit;
}
