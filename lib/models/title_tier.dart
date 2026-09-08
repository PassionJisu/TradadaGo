class TitleTier {
  const TitleTier({
    required this.id,
    required this.korean,
    required this.english,
    required this.uniqueStores,
    required this.voucherWon,
  });

  final String id;
  final String korean;
  final String english;
  final int uniqueStores;
  final int voucherWon;
}

abstract final class TitleCatalog {
  static const explorer = TitleTier(
    id: 'explorer',
    korean: '지역 탐방가',
    english: 'Explorer',
    uniqueStores: 10,
    voucherWon: 10000,
  );
  static const expert = TitleTier(
    id: 'expert',
    korean: '지역 전문가',
    english: 'Expert',
    uniqueStores: 30,
    voucherWon: 50000,
  );
  static const master = TitleTier(
    id: 'master',
    korean: '지역 마스터',
    english: 'Master',
    uniqueStores: 50,
    voucherWon: 100000,
  );

  static const all = [explorer, expert, master];
}
