import 'package:flutter/material.dart';

import '../models/review.dart';
import '../theme/app_colors.dart';
import '../widgets/review_card.dart';

class MyVisitReviewScreen extends StatelessWidget {
  const MyVisitReviewScreen({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyLight,
      appBar: AppBar(
        title: const Text('작성한 리뷰'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ReviewCard(review: review, showRecommend: false),
        ],
      ),
    );
  }
}
