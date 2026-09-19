import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../state/location_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import '../util/money.dart';
import 'qr_scan_screen.dart';
import 'write_review_screen.dart';

class StoreDetailScreen extends StatelessWidget {
  const StoreDetailScreen({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        final nearby = LocationSession.instance.isNear(store.position);
        final canScan = !store.requireGps || nearby;
        final stampedToday =
            AppSession.instance.hasVisitStampToday(store.id);
        final painted = AppSession.instance.hasPainted(store.id);
        final canReview = AppSession.instance.canWriteReview(store.id);
        final storeReviews = AppSession.instance.reviewsForStore(store.id);

        return Scaffold(
      backgroundColor: AppColors.skyLight,
      appBar: AppBar(
        title: Text(store.name),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        store.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      painted
                          ? '방문 완료'
                          : (canScan ? 'QR 인증 가능' : '접근 필요'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: painted || canScan
                            ? AppColors.teal
                            : const Color(0xFF9AA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  store.description,
                  style: const TextStyle(height: 1.4),
                ),
                if (stampedToday) ...[
                  const SizedBox(height: 10),
                  const Text(
                    '오늘 이 가게 방문 스탬프를 이미 받았습니다. (하루 1회)',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (store.products.isNotEmpty) ...[
            const Text(
              '마감할인 상품',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            ...store.products.map((p) => _ProductCard(store: store, product: p)),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: canScan
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QrScanScreen(store: store),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(canScan ? 'QR 인증하기' : '가게 앞에서만 QR 인증이 됩니다'),
          ),
          const SizedBox(height: 10),
          if (canReview)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WriteReviewScreen(store: store),
                  ),
                );
              },
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(painted ? '포토 리뷰 더 남기기' : '포토 리뷰 쓰고 방문 완료하기'),
            ),
          if (storeReviews.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              '이 가게 리뷰',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            for (final review in storeReviews.take(6))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        review.photoAsset,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.author,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(review.body, style: const TextStyle(height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: store.qrPayload));
              showAppNotice(context, 'QR 값 복사됨: ${store.qrPayload}');
            },
            child: Text('시연 QR 값  ${store.qrPayload}'),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.store, required this.product});

  final Store store;
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.imageAsset != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                product.imageAsset!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '남은 ${product.quantity}개 · ${product.pickupWindow}',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  won(product.originalPrice),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9AA3AF),
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  won(product.discountPrice),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pinRed,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pinRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${product.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${won(product.saveAmount)} 절약',
            style: const TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                AppSession.instance.addReservation(
                  store: store,
                  productName: product.name,
                  price: product.discountPrice,
                );
                showAppNotice(context, '${product.name} 픽업 예약이 완료되었습니다.');
              },
              child: const Text('픽업 예약하기'),
            ),
          ),
        ],
      ),
    );
  }
}
