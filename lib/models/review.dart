class Review {
  Review({
    required this.id,
    required this.author,
    required this.storeId,
    required this.storeName,
    required this.body,
    required this.photoAsset,
    required this.createdAt,
    this.likes = 0,
    this.isMine = false,
    this.eatenFoods = const [],
  });

  final String id;
  final String author;
  final String storeId;
  final String storeName;
  final String body;
  final String photoAsset;
  final DateTime createdAt;
  int likes;
  final bool isMine;
  final List<String> eatenFoods;

  String get eatenLabel => eatenFoods.join(' · ');
}
