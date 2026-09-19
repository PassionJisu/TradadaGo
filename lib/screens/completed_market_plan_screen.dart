import 'package:flutter/material.dart';

import '../models/market.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../widgets/market_painted_plan_view.dart';

class CompletedMarketPlanScreen extends StatelessWidget {
  const CompletedMarketPlanScreen({super.key, required this.market});

  final Market market;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        final session = AppSession.instance;
        return Scaffold(
          backgroundColor: AppColors.skyLight,
          appBar: AppBar(
            title: Text(market.name),
            backgroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text(
                '내가 리뷰를 남긴 가게만 색이 칠해집니다. 한 동의 가게를 모두 칠하면 동 색도 돌아옵니다.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              MarketPaintedPlanView(market: market, session: session),
            ],
          ),
        );
      },
    );
  }
}
