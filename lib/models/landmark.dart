enum StampCategory { market, nature, culture, heritage, history }

class Landmark {
  const Landmark({
    required this.id,
    required this.name,
    required this.photoAsset,
    required this.blurb,
    required this.category,
    required this.area,
  });

  final String id;
  final String name;
  final String photoAsset;
  final String blurb;
  final StampCategory category;
  final String area;

  String get categoryLabel => switch (category) {
        StampCategory.market => '전통시장',
        StampCategory.nature => '자연경관',
        StampCategory.culture => '문화예술',
        StampCategory.heritage => '문화유산',
        StampCategory.history => '역사유적',
      };
}
