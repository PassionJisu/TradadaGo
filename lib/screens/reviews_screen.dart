import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/review.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import '../util/money.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        final session = AppSession.instance;
        final ranking = session.weeklyRanking();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Text(
              '오늘 추천 ${session.recommendsToday}/${AppSession.dailyRecommendLimit}회 · 보너스까지 ${session.recommendCountTowardBonus}/${AppSession.recommendsForBonus}',
              style: const TextStyle(
                color: AppColors.deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _Podium(ranking: ranking),
            const SizedBox(height: 18),
            const Text(
              '이번 주 포토 리뷰',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            ...session.reviews.map((r) => _ReviewCard(review: r)),
          ],
        );
      },
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.ranking});

  final List<Review> ranking;

  @override
  Widget build(BuildContext context) {
    Review? at(int i) => i < ranking.length ? ranking[i] : null;
    final second = at(1);
    final first = at(0);
    final third = at(2);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '주간 추천 랭킹',
            style: GoogleFonts.jua(fontSize: 18, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          const Text(
            'Top 3 지역사랑상품권 차등 지급',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _podiumSlot(third, 3, 64, const Color(0xFFCD7F32), won(10000)),
              _podiumSlot(first, 1, 92, AppColors.gold, won(30000)),
              _podiumSlot(second, 2, 78, const Color(0xFFC0C0C0), won(20000)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumSlot(
    Review? review,
    int place,
    double height,
    Color color,
    String prize,
  ) {
    return Expanded(
      child: Column(
        children: [
          if (review != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                review.photoAsset,
                height: 44,
                width: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              review.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            Text(
              '♥ ${review.likes}',
              style: const TextStyle(fontSize: 11, color: AppColors.pinRed),
            ),
          ] else
            const SizedBox(height: 48),
          const SizedBox(height: 6),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Center(
              child: Text(
                '$place\n$prize',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  height: 1.2,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.author,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          Text(
            review.storeName,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              review.photoAsset,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(review.body, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${review.likes}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: () {
                    final msg =
                        AppSession.instance.recommendReview(review.id);
                    if (msg != null && context.mounted) {
                      showAppNotice(context, msg);
                    }
                  },
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                  label: const Text('추천'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
