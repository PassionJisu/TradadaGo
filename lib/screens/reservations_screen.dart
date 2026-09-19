import 'package:flutter/material.dart';

import '../data/gwangju_markets.dart';
import '../models/reservation.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import 'write_review_screen.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSession.instance,
      builder: (context, _) {
        final items = AppSession.instance.reservations;
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '이용내역',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              if (items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      '아직 이용 내역이 없습니다.\n가게 앞에서 QR을 찍거나 마감할인 상품을 예약해보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = items[i];
                      final store = _storeFor(r);
                      final canReview =
                          AppSession.instance.canWriteReview(store.id);
                      final reviewed = AppSession.instance.hasPainted(store.id);
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.storeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(r.productName),
                            const SizedBox(height: 6),
                            Text(
                              r.isQrVisit
                                  ? 'QR 방문 인증'
                                  : '${_won(r.price)} · 픽업 예약',
                              style: const TextStyle(
                                color: AppColors.pinRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (!r.isQrVisit &&
                                AppSession.instance.hasQrVerified(r.storeId))
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'QR 인증됨',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (canReview)
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonalIcon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            WriteReviewScreen(store: store),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: Text(
                                    reviewed ? '포토 리뷰 더 남기기' : '포토 리뷰 쓰기',
                                  ),
                                ),
                              )
                            else
                              const Text(
                                '가게 앞에서 QR 인증하면 여기서 리뷰를 작성할 수 있습니다.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static Store _storeFor(Reservation item) {
    return GwangjuMarkets.storeById(item.storeId) ??
        Store(
          id: item.storeId,
          marketId: item.storeId.startsWith('sj-') ? 'malbau' : 'visit',
          name: item.storeName,
          category: '방문',
          position: GwangjuMarkets.cityCenter,
          products: const [],
          requireGps: false,
        );
  }

  static String _won(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final left = s.length - i;
      buf.write(s[i]);
      if (left > 1 && left % 3 == 1) buf.write(',');
    }
    return '$buf' '원';
  }
}
