class CollectedStamp {
  const CollectedStamp({
    required this.landmarkId,
    required this.source,
    required this.at,
    required this.points,
  });

  final String landmarkId;
  final String source;
  final DateTime at;
  final int points;
}
