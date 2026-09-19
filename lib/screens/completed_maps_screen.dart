import 'package:flutter/material.dart';

import '../data/gwangju_markets.dart';
import '../data/sangju_indoor_map.dart';
import '../models/market.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import 'completed_market_plan_screen.dart';

class CompletedMapsScreen extends StatelessWidget {
  const CompletedMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        final session = AppSession.instance;
        return Scaffold(
          backgroundColor: AppColors.skyLight,
          appBar: AppBar(
            title: const Text('내가 완성한 지도'),
            backgroundColor: Colors.white,
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: GwangjuMarkets.all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final market = GwangjuMarkets.all[i];
              return _MarketRow(market: market, session: session);
            },
          ),
        );
      },
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.market, required this.session});

  final Market market;
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final isDemo = market.id == GwangjuMarkets.malbau.id;
    final total =
        isDemo ? SangjuIndoorMap.publishedStallCount : market.stores.length;
    final painted = isDemo
        ? session.paintedStoreIds.where((id) => id.startsWith('sj-')).length
        : market.stores.where((s) => session.hasPainted(s.id)).length;
    final ready = isDemo || total > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CompletedMarketPlanScreen(market: market),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map_outlined, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      market.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ready ? '$painted/$total곳 색칠' : '평면도 준비 중',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class CompletedMarketMapCard extends StatelessWidget {
  const CompletedMarketMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CompletedMapsScreen()),
          );
        },
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내가 완성한 지도',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '리뷰를 남긴 가게가 색으로 칠해진 지도를 다시 봅니다.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
