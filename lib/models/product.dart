class Product {
  const Product({
    required this.id,
    required this.name,
    required this.originalPrice,
    required this.discountPrice,
    required this.quantity,
    required this.pickupWindow,
    this.imageAsset,
    this.reviewImageAsset,
  });

  final String id;
  final String name;
  final int originalPrice;
  final int discountPrice;
  final int quantity;
  final String pickupWindow;
  final String? imageAsset;

  /// 픽업해서 먹으며 올린 리뷰용 사진. 가게 진열 사진과 구분한다.
  final String? reviewImageAsset;

  int get saveAmount => originalPrice - discountPrice;

  int get discountPercent =>
      originalPrice == 0 ? 0 : ((saveAmount / originalPrice) * 100).round();
}
