class EditorialStop {
  const EditorialStop({required this.name, required this.note});

  final String name;
  final String note;
}

class EditorialRoute {
  const EditorialRoute({
    required this.id,
    required this.title,
    required this.kicker,
    required this.duration,
    required this.distance,
    required this.coverAsset,
    required this.summary,
    required this.stops,
  });

  final String id;
  final String title;
  final String kicker;
  final String duration;
  final String distance;
  final String coverAsset;
  final String summary;
  final List<EditorialStop> stops;
}
