import 'package:flutter/material.dart';

import '../models/market.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../widgets/market_floor_plan_view.dart';

class CompletedMarketPlanScreen extends StatelessWidget {
  const CompletedMarketPlanScreen({super.key, required this.market});

  final Market market;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        final session = AppSession.instance;
        final total = market.stores.length;
        final painted =
            market.stores.where((s) => session.hasEverVisited(s.id)).length;
        return Scaffold(
          backgroundColor: AppColors.skyLight,
          appBar: AppBar(
            title: Text(market.name),
            backgroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                total == 0
                    ? '평면도 준비 중'
                    : '평면도 · $painted/$total곳 색칠 · 방문한 구역만 색이 채워집니다.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              MarketFloorPlanView(market: market, session: session),
              if (market.stores.isNotEmpty) ...[
                const SizedBox(height: 12),
                StorePaintLegend(stores: market.stores, session: session),
              ],
            ],
          ),
        );
      },
    );
  }
}
