import 'package:flutter/material.dart';

import '../models/review.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onTap,
    this.showStoreName = true,
  });

  final Review review;
  final VoidCallback? onTap;
  final bool showStoreName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
              if (showStoreName)
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
        ),
      ),
    );
  }
}
