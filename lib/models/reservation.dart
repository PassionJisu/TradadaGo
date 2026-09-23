enum ReservationStatus { reserved, visited }

class ReservedItem {
  const ReservedItem({
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  final String name;
  final int unitPrice;
  final int quantity;

  int get linePrice => unitPrice * quantity;

  String get label => '$name × $quantity';
}

class Reservation {
  Reservation({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.createdAt,
    this.status = ReservationStatus.reserved,
    this.reviewId,
  });

  final String id;
  final String storeId;
  final String storeName;
  final List<ReservedItem> items;
  final DateTime createdAt;
  ReservationStatus status;
  String? reviewId;

  bool get isQrVisit => status == ReservationStatus.visited;
  bool get isOpenReservation => status == ReservationStatus.reserved;
  bool get hasReview => reviewId != null;

  int get price => items.fold(0, (sum, item) => sum + item.linePrice);

  bool get isWalkIn => items.isEmpty;

  String get productName => isWalkIn
      ? '현장 방문'
      : items.map((item) => item.label).join(', ');

  List<String> get eatenFoods => [for (final item in items) item.label];

  String get timeLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${createdAt.year}.${two(createdAt.month)}.${two(createdAt.day)}  '
        '${two(createdAt.hour)}:${two(createdAt.minute)}';
  }
}
