import 'package:flutter/material.dart';

import '../data/gwangju_markets.dart';
import '../models/reservation.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import 'my_visit_review_screen.dart';
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
                      '아직 이용 내역이 없습니다.\n식당 메뉴를 예약한 뒤, 가게 앞에서 QR로 수령하세요.',
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
                          AppSession.instance.canWriteReviewFor(r);
                      final review = r.hasReview
                          ? AppSession.instance.reviewById(r.reviewId)
                          : null;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: review == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MyVisitReviewScreen(review: review),
                                    ),
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            ? '${_won(r.price)} · QR 수령 완료'
                                            : '${_won(r.price)} · 예약됨',
                                        style: const TextStyle(
                                          color: AppColors.pinRed,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.timeLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (r.isOpenReservation)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: OutlinedButton(
                                            onPressed: () => _confirmCancel(
                                              context,
                                              r,
                                            ),
                                            child: const Text('예약 취소'),
                                          ),
                                        )
                                      else if (canReview)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: FilledButton.tonalIcon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      WriteReviewScreen(
                                                    store: store,
                                                    visitId: r.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.photo_camera_outlined,
                                            ),
                                            label: const Text('포토 리뷰 쓰기'),
                                          ),
                                        )
                                      else if (r.hasReview)
                                        const Text(
                                          '작성한 리뷰 보기',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.teal,
                                          ),
                                        )
                                      else if (r.isQrVisit)
                                        const Text(
                                          '예약한 메뉴를 가게 앞에서 QR로 수령하면 리뷰를 1회 작성할 수 있습니다.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (r.hasReview)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8, top: 4),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF9AA3AF),
                                    ),
                                  ),
                              ],
                            ),
                          ),
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

  static Future<void> _confirmCancel(
    BuildContext context,
    Reservation reservation,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정말 취소하시겠습니까?'),
        content: Text('${reservation.storeName} 예약이 이용내역에서 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아니오'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('예약 취소'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    AppSession.instance.cancelReservation(reservation.id);
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
