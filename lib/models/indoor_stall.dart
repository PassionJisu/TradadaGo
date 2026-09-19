import 'dart:ui';

class IndoorStall {
  const IndoorStall({
    required this.id,
    required this.name,
    required this.floor,
    required this.path,
    required this.bounds,
  });

  final String id;
  final String name;
  final int floor;
  final Path path;
  final Rect bounds;
}
