import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../map/market_blueprint.dart';
import '../theme/app_colors.dart';

class PaintProgressBanner extends StatelessWidget {
  const PaintProgressBanner({
    super.key,
    required this.painted,
    required this.total,
  });

  final int painted;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : painted / total;
    final percent = (ratio * 100).round();
    return Material(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '색칠 $percent%  ·  $painted/$total곳 리뷰',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: const Color(0xFFE6EDF4),
                color: AppColors.goldDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketMapToolbar extends StatelessWidget {
  const MarketMapToolbar({
    super.key,
    required this.categoryLabel,
    required this.floorLabel,
    required this.onCategory,
    required this.onFloor,
    required this.onStores,
    this.categoryActive = false,
  });

  final String categoryLabel;
  final String floorLabel;
  final VoidCallback onCategory;
  final VoidCallback onFloor;
  final VoidCallback onStores;
  final bool categoryActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MapActionButton(
            icon: Icons.tune_rounded,
            label: categoryLabel,
            selected: categoryActive,
            onTap: onCategory,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MapActionButton(
            icon: Icons.layers_rounded,
            label: floorLabel,
            onTap: onFloor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MapActionButton(
            icon: Icons.storefront_rounded,
            label: '가게 정보 보기',
            onTap: onStores,
          ),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.gold : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Column(
            children: [
              Icon(icon, size: 18, color: AppColors.navy),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showCategoryPicker({
  required BuildContext context,
  required List<StallUse> uses,
  required StallUse? selected,
  required ValueChanged<StallUse?> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          Text(
            '카테고리 별 분류',
            style: GoogleFonts.jua(fontSize: 22, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          const Text(
            '보고 싶은 업종을 고르면 해당 동과 가게가 강조됩니다.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 10),
          _CategoryTile(
            emoji: '🗺️',
            label: '전체',
            selected: selected == null,
            onTap: () {
              onSelected(null);
              Navigator.pop(ctx);
            },
          ),
          for (final use in uses)
            _CategoryTile(
              emoji: use.emoji,
              label: use.labelKo,
              selected: selected == use,
              color: use.color,
              onTap: () {
                onSelected(use);
                Navigator.pop(ctx);
              },
            ),
        ],
      );
    },
  );
}

Future<void> showFloorPicker({
  required BuildContext context,
  required List<MarketFloor> floors,
  required String selectedId,
  String? alertFloorId,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          Text(
            '층 선택',
            style: GoogleFonts.jua(fontSize: 22, color: AppColors.navy),
          ),
          const SizedBox(height: 10),
          for (final floor in floors)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: floor.id == selectedId
                    ? AppColors.gold
                    : const Color(0xFFF3F6FA),
                child: Text(
                  floor.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
              ),
              title: Text(
                floor.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(floor.caption),
              trailing: floor.id == alertFloorId
                  ? const Icon(Icons.place_rounded, color: AppColors.pinRed)
                  : (floor.id == selectedId
                      ? const Icon(Icons.check_rounded, color: AppColors.navy)
                      : null),
              onTap: () {
                onSelected(floor.id);
                Navigator.pop(ctx);
              },
            ),
        ],
      );
    },
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: selected
            ? (color ?? AppColors.navy).withValues(alpha: 0.16)
            : const Color(0xFFF3F6FA),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.navy)
          : null,
      onTap: onTap,
    );
  }
}
