import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final titleSize = compact ? 26.0 : 36.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.logo,
          height: compact ? 88 : 132,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '트라다다 ',
                style: GoogleFonts.jua(
                  fontSize: titleSize,
                  color: AppColors.navy,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'GO!',
                style: GoogleFonts.jua(
                  fontSize: titleSize + 4,
                  color: AppColors.goldDeep,
                  height: 1,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        if (showSlogan) ...[
          const SizedBox(height: 6),
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
