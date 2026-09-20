class Product {
  const Product({
    required this.id,
    required this.name,
    required this.originalPrice,
    required this.discountPrice,
    required this.quantity,
    required this.pickupWindow,
    this.imageAsset,
  });

  final String id;
  final String name;
  final int originalPrice;
  final int discountPrice;
  final int quantity;
  final String pickupWindow;
  final String? imageAsset;

  int get saveAmount => originalPrice - discountPrice;

  int get discountPercent =>
      originalPrice == 0 ? 0 : ((saveAmount / originalPrice) * 100).round();
}
