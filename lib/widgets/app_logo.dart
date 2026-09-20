import 'package:flutter/material.dart';

import '../config/assets.dart';
import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.showSlogan = true,
    this.compact = false,
  });

  final bool showSlogan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 로고에 워드마크가 포함되어 있어 배경 없이 그대로 올린다.
        Image.asset(
          AppAssets.logo,
          height: compact ? 96 : 150,
          filterQuality: FilterQuality.high,
        ),
        if (showSlogan) ...[
          const SizedBox(height: 10),
          Text(
            '시장도 여행처럼! 혜택은 보물처럼!',
            style: TextStyle(
              color: AppColors.deepBlue.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ],
    );
  }
}
