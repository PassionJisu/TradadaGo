import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'editorial_screen.dart';
import 'reviews_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.skyLight,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '커뮤니티',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _CommunityBanner(
                index: _tab,
                onSelect: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  ReviewsScreen(),
                  EditorialScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner({
    required this.index,
    required this.onSelect,
  });

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            _segment(
              selected: index == 0,
              icon: Icons.rate_review_rounded,
              title: '리뷰 & 추천',
              subtitle: '포토 리뷰 · 주간 랭킹',
              onTap: () => onSelect(0),
            ),
            _segment(
              selected: index == 1,
              icon: Icons.map_outlined,
              title: 'Editorial',
              subtitle: '추천 방문 루트',
              onTap: () => onSelect(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.navy,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
