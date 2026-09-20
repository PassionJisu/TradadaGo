enum UsageKind { pickup, qrVisit }

class Reservation {
  Reservation({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.productName,
    required this.price,
    required this.createdAt,
    this.kind = UsageKind.pickup,
    this.reviewId,
  });

  final String id;
  final String storeId;
  final String storeName;
  final String productName;
  final int price;
  final DateTime createdAt;
  final UsageKind kind;
  String? reviewId;

  bool get isQrVisit => kind == UsageKind.qrVisit;
  bool get hasReview => reviewId != null;

  String get timeLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${createdAt.year}.${two(createdAt.month)}.${two(createdAt.day)}  '
        '${two(createdAt.hour)}:${two(createdAt.minute)}';
  }
}
