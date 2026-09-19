import 'package:flutter/material.dart';

import '../models/store.dart';
import '../theme/app_colors.dart';
import '../util/money.dart';
import '../screens/qr_scan_screen.dart';
import '../screens/store_detail_screen.dart';

Future<void> showStorePreviewSheet(BuildContext context, Store store, {required bool nearby}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final product = store.products.first;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                if (nearby)
                  const Text(
                    '핀 활성화',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(store.category),
            const SizedBox(height: 12),
            if (product.imageAsset != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  product.imageAsset!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  won(product.originalPrice),
                  style: const TextStyle(
                    color: Color(0xFF9AA3AF),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  won(product.discountPrice),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pinRed,
                  ),
                ),
              ],
            ),
            if (!nearby) ...[
              const SizedBox(height: 8),
              const Text(
                '스탬프는 가게 앞에서만 찍을 수 있어요. 상품 예약은 가능합니다.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StoreDetailScreen(store: store),
                  ),
                );
              },
              child: const Text('가게·상품 자세히 보기'),
            ),
            if (nearby) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QrScanScreen(store: store),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('카메라로 QR 인증'),
              ),
            ],
          ],
        ),
      );
    },
  );
}
