import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/gwangju_landmarks.dart';
import '../models/title_tier.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import '../util/money.dart';
import 'inquiry_screen.dart';
import 'login_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        final s = AppSession.instance;
        return ColoredBox(
          color: AppColors.skyLight,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Text(
                  '${s.displayName}의 여정',
                  style: GoogleFonts.jua(
                    fontSize: 26,
                    color: AppColors.navy,
                  ),
                ),
                const Text('스탬프 보드 · 칭호작 · 반복 미션'),
                const SizedBox(height: 14),
                _MissionCard(session: s),
                const SizedBox(height: 14),
                _TitleCard(session: s),
                const SizedBox(height: 14),
                _StampBoard(session: s),
                const SizedBox(height: 14),
                _DemoStampCard(session: s),
                if (s.voucherLog.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    '지급 내역',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...s.voucherLog.reversed.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('· $line'),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InquiryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('신고 / 문의하기'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.pinRed),
                  label: const Text(
                    '로그아웃',
                    style: TextStyle(
                      color: AppColors.pinRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그인 화면으로 돌아갈까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    AppSession.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _DemoStampCard extends StatelessWidget {
  const _DemoStampCard({required this.session});
  final AppSession session;

  void _grant(BuildContext context, int count) {
    final grant = session.addDemoVisitStamps(count);
    showAppNotice(context, grant.message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '시연 도구',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'QR 없이 방문 스탬프를 채워 보드·칭호를 확인합니다.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _grant(context, 1),
                  child: const Text('스탬프 1개'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _grant(context, 10),
                  child: const Text('스탬프 10개'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.session});
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final next = session.nextTitle();
    final unique = session.uniqueVisitCount;
    final titleGoal = next?.uniqueStores ?? 50;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '미션',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          _bar(
            label: next == null
                ? '칭호작 완료 · 상시 리워드로 전환'
                : '${next.korean}까지 안 가본 가게 $unique/${next.uniqueStores}',
            value: (unique / titleGoal).clamp(0, 1),
          ),
          const SizedBox(height: 8),
          _bar(
            label:
                '추천 ${session.recommendCountTowardBonus}/${AppSession.recommendsForBonus}회 → 스탬프 1개',
            value: session.recommendCountTowardBonus /
                AppSession.recommendsForBonus,
          ),
          const SizedBox(height: 8),
          _bar(
            label:
                '오늘 추천 ${session.recommendsToday}/${AppSession.dailyRecommendLimit}회',
            value: session.recommendsToday / AppSession.dailyRecommendLimit,
          ),
          const SizedBox(height: 8),
          _bar(
            label:
                '반복 미션 스탬프 ${session.repeatingProgress}/${AppSession.repeatingStampGoal} → 상품권 1만 원',
            value: session.repeatingProgress / AppSession.repeatingStampGoal,
          ),
        ],
      ),
    );
  }

  Widget _bar({required String label, required double value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, height: 1.3)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            color: AppColors.goldDeep,
            backgroundColor: const Color(0xFFE8EEF5),
          ),
        ),
      ],
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.session});
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '칭호작',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '안 가본 가게 방문 횟수만 반영됩니다. 리뷰·추천 스탬프는 제외.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          for (final tier in TitleCatalog.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    session.earnedTitleIds.contains(tier.id)
                        ? Icons.emoji_events
                        : Icons.emoji_events_outlined,
                    color: session.earnedTitleIds.contains(tier.id)
                        ? AppColors.goldDeep
                        : const Color(0xFF9AA3AF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tier.korean} (${tier.english}) · ${tier.uniqueStores}곳 · ${won(tier.voucherWon)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: session.earnedTitleIds.contains(tier.id)
                            ? AppColors.navy
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StampBoard extends StatelessWidget {
  const _StampBoard({required this.session});
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final start = session.boardIndex * AppSession.boardSize;
    final cells = List<int>.generate(AppSession.boardSize, (i) => start + i);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '나의 체크판 · ${session.boardIndex + 1}번째 보드',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '광주 우표 스탬프 ${session.boardFillCount}/${AppSession.boardSize} · 30칸이 차면 다음 보드',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppSession.boardSize,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppSession.columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, i) {
              final stampIndex = cells[i];
              final filled = stampIndex < session.stamps.length;
              final rowStart = (i ~/ AppSession.columns) * AppSession.columns;
              final rowFilled = List.generate(AppSession.columns, (c) {
                return cells[rowStart + c] < session.stamps.length;
              }).every((e) => e);
              return GestureDetector(
                onTap: filled
                    ? () => _openStamp(context, stampIndex)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: filled
                        ? (rowFilled
                            ? const Color(0xFFFFF3B0)
                            : const Color(0xFFFFF8E8))
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: filled
                          ? (rowFilled ? AppColors.goldDeep : AppColors.navy)
                          : const Color(0xFFE5E7EB),
                      width: 1.4,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: filled
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(
                            GwangjuLandmarks.byId(
                              session.stamps[stampIndex].landmarkId,
                            ).photoAsset,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                              color: Color(0xFF9AA3AF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openStamp(BuildContext context, int stampIndex) {
    final stamp = session.stamps[stampIndex];
    final landmark = GwangjuLandmarks.byId(stamp.landmarkId);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(landmark.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(landmark.photoAsset),
            ),
            const SizedBox(height: 10),
            Text(landmark.blurb),
            const SizedBox(height: 6),
            Text(
              '출처: ${_sourceLabel(stamp.source)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(String source) {
    return switch (source) {
      'visit' => '가게 방문 QR',
      'review' => '포토 리뷰 보너스',
      'recommend' => '추천 10회 보너스',
      _ => source,
    };
  }
}
