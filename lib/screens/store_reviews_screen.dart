import 'package:flutter/material.dart';

import '../data/gwangju_markets.dart';
import '../data/sangju_indoor_map.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import '../widgets/review_card.dart';
import 'store_detail_screen.dart';

Future<Store?> lookupStore(String storeId) async {
  final known = GwangjuMarkets.storeById(storeId);
  if (known != null) return known;
  final map = await SangjuIndoorMap.load();
  for (final stall in map.stalls) {
    if (stall.id == storeId) return stall.asStore();
  }
  return null;
}

Future<void> openStoreReviews(BuildContext context, String storeId) async {
  final store = await lookupStore(storeId);
  if (!context.mounted) return;
  if (store == null) {
    showAppNotice(context, '가게 정보를 찾을 수 없습니다.');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => StoreReviewsScreen(store: store)),
  );
}

Future<void> openStoreDetail(BuildContext context, String storeId) async {
  final store = await lookupStore(storeId);
  if (!context.mounted) return;
  if (store == null) {
    showAppNotice(context, '가게 정보를 찾을 수 없습니다.');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store)),
  );
}

class StoreReviewsScreen extends StatelessWidget {
  const StoreReviewsScreen({super.key, required this.store});

  final Store store;

  void _openStoreDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        final reviews = AppSession.instance.reviewsForStore(store.id);
        return Scaffold(
          backgroundColor: AppColors.skyLight,
          appBar: AppBar(
            title: Text(store.name),
            backgroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                '이 가게 리뷰 ${reviews.length}개',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openStoreDetail(context),
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('식당으로 이동'),
                ),
              ),
              const SizedBox(height: 16),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Text(
                    '아직 이 가게의 리뷰가 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              else
                ...reviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReviewCard(review: review, showStoreName: false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
