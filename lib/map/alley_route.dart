import 'dart:ui';

/// 시연 걷기와 같은 복도만 따라, 지금 위치에서 목적지까지 가장 짧은 길을 잇는다.
List<Offset> alleyRoute({
  required List<Offset> path,
  required Offset from,
  required Offset to,
}) {
  final segments = <(Offset, Offset)>[];
  for (var i = 0; i < path.length - 1; i++) {
    if ((path[i] - path[i + 1]).distance > 1) {
      segments.add((path[i], path[i + 1]));
    }
  }
  if (segments.isEmpty) return [from, to];
  final through = _CorridorGraph(segments).shortest(from, to);
  final route = <Offset>[from];
  for (final point in through) {
    if ((route.last - point).distance > 1.2) route.add(point);
  }
  if ((route.last - to).distance > 1.2) route.add(to);
  return route;
}

class _CorridorGraph {
  _CorridorGraph(List<(Offset, Offset)> segments) {
    final splits = <List<Offset>>[
      for (final segment in segments) [segment.$1, segment.$2],
    ];
    for (var i = 0; i < segments.length; i++) {
      for (var j = i + 1; j < segments.length; j++) {
        final hit = _intersection(segments[i].$1, segments[i].$2, segments[j].$1, segments[j].$2);
        if (hit != null) {
          splits[i].add(hit);
          splits[j].add(hit);
        }
        if (_onSegment(segments[i].$1, segments[i].$2, segments[j].$1)) {
          splits[i].add(segments[j].$1);
        }
        if (_onSegment(segments[i].$1, segments[i].$2, segments[j].$2)) {
          splits[i].add(segments[j].$2);
        }
        if (_onSegment(segments[j].$1, segments[j].$2, segments[i].$1)) {
          splits[j].add(segments[i].$1);
        }
        if (_onSegment(segments[j].$1, segments[j].$2, segments[i].$2)) {
          splits[j].add(segments[i].$2);
        }
      }
    }

    for (var i = 0; i < segments.length; i++) {
      final start = segments[i].$1;
      final ordered = [...splits[i]]..sort((a, b) {
          final da = (a - start).distance;
          final db = (b - start).distance;
          return da.compareTo(db);
        });
      String? previous;
      for (final point in ordered) {
        final id = _add(point);
        if (previous != null) _link(previous, id);
        previous = id;
      }
    }
    _atomic = [
      for (final entry in edges.entries)
        for (final (next, _) in entry.value)
          if (entry.key.compareTo(next) < 0) (entry.key, next),
    ];
  }

  final nodes = <String, Offset>{};
  final edges = <String, List<(String, double)>>{};
  late final List<(String, String)> _atomic;

  List<Offset> shortest(Offset from, Offset to) {
    final start = _attach(from);
    final goal = _attach(to);
    if (start == null || goal == null) return const [];
    if (start == goal) return [nodes[start]!];

    final dist = <String, double>{start: 0};
    final prev = <String, String>{};
    final used = <String>{};
    while (used.length < nodes.length) {
      String? best;
      var bestDistance = double.infinity;
      for (final entry in dist.entries) {
        if (used.contains(entry.key) || entry.value >= bestDistance) continue;
        best = entry.key;
        bestDistance = entry.value;
      }
      if (best == null) break;
      if (best == goal) break;
      used.add(best);
      for (final (next, weight) in edges[best] ?? const <(String, double)>[]) {
        final nextDistance = bestDistance + weight;
        if (nextDistance + 0.01 >= (dist[next] ?? double.infinity)) continue;
        dist[next] = nextDistance;
        prev[next] = best;
      }
    }
    if (start != goal && !prev.containsKey(goal)) return const [];

    final keys = <String>[goal];
    var cursor = goal;
    while (cursor != start) {
      final parent = prev[cursor];
      if (parent == null) return const [];
      cursor = parent;
      keys.add(cursor);
    }
    return [for (final key in keys.reversed) nodes[key]!];
  }

  String? _attach(Offset target) {
    var bestEdge = -1;
    var bestPoint = Offset.zero;
    var bestDistance = double.infinity;
    for (var i = 0; i < _atomic.length; i++) {
      final a = nodes[_atomic[i].$1]!;
      final b = nodes[_atomic[i].$2]!;
      final point = _project(a, b, target);
      final distance = (point - target).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestPoint = point;
        bestEdge = i;
      }
    }
    if (bestEdge < 0) return null;
    final id = _add(bestPoint);
    final (a, b) = _atomic[bestEdge];
    if (id != a && id != b) {
      _unlink(a, b);
      _link(a, id);
      _link(id, b);
      _atomic[bestEdge] = (a, id);
      _atomic.add((id, b));
    }
    return id;
  }

  String _add(Offset point) {
    final id = '${(point.dx * 2).round()},${(point.dy * 2).round()}';
    nodes.putIfAbsent(id, () => point);
    edges.putIfAbsent(id, () => []);
    return id;
  }

  void _link(String a, String b) {
    if (a == b) return;
    final weight = (nodes[a]! - nodes[b]!).distance;
    if (weight < 0.4) return;
    final from = edges[a]!;
    if (from.any((edge) => edge.$1 == b)) return;
    from.add((b, weight));
    edges[b]!.add((a, weight));
  }

  void _unlink(String a, String b) {
    edges[a]?.removeWhere((edge) => edge.$1 == b);
    edges[b]?.removeWhere((edge) => edge.$1 == a);
  }
}

Offset? _intersection(Offset a, Offset b, Offset c, Offset d) {
  final r = b - a;
  final s = d - c;
  final denom = r.dx * s.dy - r.dy * s.dx;
  if (denom.abs() < 1e-6) return null;
  final qp = c - a;
  final t = (qp.dx * s.dy - qp.dy * s.dx) / denom;
  final u = (qp.dx * r.dy - qp.dy * r.dx) / denom;
  if (t < -0.001 || t > 1.001 || u < -0.001 || u > 1.001) return null;
  return Offset(a.dx + r.dx * t, a.dy + r.dy * t);
}

bool _onSegment(Offset a, Offset b, Offset point) {
  final ab = b - a;
  final length2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (length2 < 1) return (point - a).distance < 1.5;
  final t = ((point.dx - a.dx) * ab.dx + (point.dy - a.dy) * ab.dy) / length2;
  if (t < -0.002 || t > 1.002) return false;
  final clamped = t.clamp(0.0, 1.0);
  final projected = Offset(a.dx + ab.dx * clamped, a.dy + ab.dy * clamped);
  return (projected - point).distance <= 1.5;
}

Offset _project(Offset a, Offset b, Offset target) {
  final ab = b - a;
  final length2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (length2 < 0.001) return a;
  final t = (((target.dx - a.dx) * ab.dx) + ((target.dy - a.dy) * ab.dy)) / length2;
  final clamped = t.clamp(0.0, 1.0);
  return Offset(a.dx + ab.dx * clamped, a.dy + ab.dy * clamped);
}
