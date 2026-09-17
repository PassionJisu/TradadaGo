import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/editorial_routes.dart';
import '../models/editorial_route.dart';
import '../theme/app_colors.dart';

class EditorialScreen extends StatelessWidget {
  const EditorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Text(
          '이번 주 추천 루트',
          style: GoogleFonts.jua(fontSize: 20, color: AppColors.navy),
        ),
        const SizedBox(height: 4),
        const Text(
          '시장을 여행지처럼 걷는 Editorial 가이드입니다.',
          style: TextStyle(
            color: AppColors.deepBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        ...EditorialRoutes.all.map(
          (route) => _RouteCard(
            route: route,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditorialRouteDetailScreen(route: route),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});

  final EditorialRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 148,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(route.coverAsset, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x990B3A6A)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 12,
                      child: Text(
                        route.title,
                        style: GoogleFonts.jua(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          route.kicker,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppColors.deepBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route.duration,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepBlue,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.straighten_rounded,
                          size: 16,
                          color: AppColors.deepBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route.distance,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepBlue,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      route.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.4, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final stop in route.stops)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(stop.name),
                            labelStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                            side: BorderSide.none,
                            backgroundColor: AppColors.skyLight,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditorialRouteDetailScreen extends StatelessWidget {
  const EditorialRouteDetailScreen({super.key, required this.route});

  final EditorialRoute route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                route.title,
                style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(route.coverAsset, fit: BoxFit.cover),
                  const ColoredBox(color: Color(0x590B3A6A)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${route.kicker} · ${route.duration} · ${route.distance}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(route.summary, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 20),
                  const Text(
                    '방문 순서',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(route.stops.length, (i) {
                    final stop = route.stops[i];
                    final last = i == route.stops.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.navy,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (!last)
                              Container(
                                width: 2,
                                height: 36,
                                color: AppColors.gold.withValues(alpha: 0.7),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                Text(
                                  stop.note,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
