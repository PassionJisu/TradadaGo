import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/gwangju_landmarks.dart';
import '../models/collected_stamp.dart';
import '../models/landmark.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/money.dart';

class StampBoard extends StatefulWidget {
  const StampBoard({super.key, required this.session});

  final AppSession session;

  @override
  State<StampBoard> createState() => _StampBoardState();
}

class _StampBoardState extends State<StampBoard> with SingleTickerProviderStateMixin {
  int? _board;
  StampCategory? _filter;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void didUpdateWidget(StampBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final latest = widget.session.boardIndex;
    if (_board != null && _board! > latest) _board = latest;
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  int get _boardIndex {
    final latest = widget.session.boardIndex;
    final chosen = _board ?? latest;
    if (chosen < 0 || chosen > latest) return latest;
    return chosen;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final board = _boardIndex;
    final fill = session.fillOnBoard(board);
    final start = board * AppSession.boardSize;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${board + 1}번째 보드',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepBlue,
                      ),
                    ),
                    Text(
                      '나의 스탬프 수집판',
                      style: GoogleFonts.jua(fontSize: 22, color: AppColors.navy),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_grouped(session.stampPoints)}P',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$fill / ${AppSession.boardSize} 칸 완료',
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          _MilestoneBar(fill: fill),
          if (session.boardCount > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: session.boardCount,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final selected = index == board;
                  final done = session.fillOnBoard(index) == AppSession.boardSize;
                  return ChoiceChip(
                    label: Text(done ? '${index + 1}보드 완성' : '${index + 1}보드'),
                    selected: selected,
                    onSelected: (_) => setState(() => _board = index),
                    selectedColor: AppColors.gold,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.navy : const Color(0xFF6B7280),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(null, '전체'),
                for (final category in StampCategory.values)
                  _filterChip(category, _categoryLabel(category)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppSession.boardSize,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppSession.columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, i) {
              final stampIndex = start + i;
              final filled = stampIndex < session.stamps.length;
              final stamp = filled ? session.stamps[stampIndex] : null;
              final landmark = stamp == null ? null : GwangjuLandmarks.byId(stamp.landmarkId);
              final dimmed = landmark != null && _filter != null && landmark.category != _filter;
              return _StampCell(
                number: i + 1,
                stamp: stamp,
                landmark: landmark,
                dimmed: dimmed,
                shine: _shine,
                onTap: stamp == null || landmark == null || dimmed
                    ? null
                    : () => _openStamp(context, stamp, landmark, i + 1),
              );
            },
          ),
          const SizedBox(height: 14),
          _RewardPreview(fill: fill),
        ],
      ),
      ),
    );
  }

  Widget _filterChip(StampCategory? category, String label) {
    final selected = _filter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = category),
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppColors.navy,
        ),
      ),
    );
  }

  void _openStamp(BuildContext context, CollectedStamp stamp, Landmark landmark, int number) {
    final date = _date(stamp.at);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  landmark.photoAsset,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _CategoryBadge(category: landmark.category),
                  const SizedBox(width: 8),
                  Text(
                    '$number번 우표',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                landmark.name,
                style: GoogleFonts.jua(fontSize: 26, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              Text(landmark.blurb, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 10),
              Text('방문일  $date', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('위치  ${landmark.area}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '받은 경로  ${_sourceLabel(stamp.source)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        );
      },
    );
  }

  String _date(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${at.year}.${two(at.month)}.${two(at.day)}';
  }
}

class _MilestoneBar extends StatelessWidget {
  const _MilestoneBar({required this.fill});

  final int fill;

  @override
  Widget build(BuildContext context) {
    final t = (fill / AppSession.boardSize).clamp(0.0, 1.0);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 18,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EDF4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: width * t,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A3D), AppColors.gold, AppColors.goldDeep],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  for (final tick in [0, 10, 20, 30])
                    Positioned(
                      left: (tick / AppSession.boardSize) * width - (tick == 30 ? 8 : 0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fill >= tick ? AppColors.navy : Colors.white,
                          border: Border.all(color: AppColors.navy, width: 1.4),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text('10', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text('20', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text('30', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _RewardPreview extends StatelessWidget {
  const _RewardPreview({required this.fill});

  final int fill;

  @override
  Widget build(BuildContext context) {
    final done = fill >= AppSession.boardSize;
    final ratio = fill / AppSession.boardSize;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.goldDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '이 보드를 완성했습니다' : '보드 완성 보상',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy),
                ),
                Text(
                  '광주 탐험가 칭호 · 지역화폐 ${won(10000)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Text(
            '${(ratio * 100).round()}%',
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}

class _StampCell extends StatelessWidget {
  const _StampCell({
    required this.number,
    required this.stamp,
    required this.landmark,
    required this.dimmed,
    required this.shine,
    required this.onTap,
  });

  final int number;
  final CollectedStamp? stamp;
  final Landmark? landmark;
  final bool dimmed;
  final Animation<double> shine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final filled = stamp != null && landmark != null;
    return GestureDetector(
      onTap: onTap,
      child: filled ? _filled(landmark!) : _empty(),
    );
  }

  Widget _filled(Landmark landmark) {
    return Opacity(
      opacity: dimmed ? 0.28 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldDeep, width: 1.6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(landmark.photoAsset, fit: BoxFit.cover),
              AnimatedBuilder(
                animation: shine,
                builder: (context, _) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.2 + shine.value * 2.4, -1),
                        end: Alignment(-0.2 + shine.value * 2.4, 1),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 3,
                top: 3,
                child: _CategoryBadge(category: landmark.category, tiny: true),
              ),
              const Positioned(
                right: 4,
                top: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  child: SizedBox(width: 7, height: 7),
                ),
              ),
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return CustomPaint(
      painter: const _DashedFramePainter(),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Color(0xFFC5CDD6),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category, this.tiny = false});

  final StampCategory category;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: tiny ? 3 : 8, vertical: tiny ? 1 : 3),
      decoration: BoxDecoration(
        color: _categoryColor(category),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _categoryLabel(category),
        style: TextStyle(
          color: category == StampCategory.market ? AppColors.navy : Colors.white,
          fontSize: tiny ? 7 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DashedFramePainter extends CustomPainter {
  const _DashedFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5DDE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 4;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + 3;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedFramePainter oldDelegate) => false;
}

String _categoryLabel(StampCategory category) => switch (category) {
      StampCategory.market => '전통시장',
      StampCategory.nature => '자연경관',
      StampCategory.culture => '문화예술',
      StampCategory.heritage => '문화유산',
      StampCategory.history => '역사유적',
    };

Color _categoryColor(StampCategory category) => switch (category) {
      StampCategory.market => AppColors.goldDeep,
      StampCategory.nature => AppColors.teal,
      StampCategory.culture => AppColors.deepBlue,
      StampCategory.heritage => AppColors.navy,
      StampCategory.history => AppColors.pinRed,
    };

String _grouped(int value) => won(value).replaceAll('원', '');

String _sourceLabel(String source) {
  return switch (source) {
    'visit' => '가게 방문',
    'review' => '포토 리뷰 보너스',
    'recommend' => '추천 보너스',
    _ => source,
  };
}
