class Reservation {
  const Reservation({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.productName,
    required this.price,
    required this.createdAt,
  });

  final String id;
  final String storeId;
  final String storeName;
  final String productName;
  final int price;
  final DateTime createdAt;
}
