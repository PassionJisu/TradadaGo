import 'package:flutter/material.dart';

import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../widgets/tradada_bottom_nav.dart';
import 'home_map_screen.dart';
import 'placeholder_screen.dart';
import 'reservations_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _mapKey = GlobalKey<HomeMapScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeMapScreen(key: _mapKey),
          const ReservationsScreen(),
          const PlaceholderScreen(
            title: '알림',
            message: '알림은 2차에서 연결합니다.',
            icon: Icons.notifications_none_rounded,
          ),
          ListenableBuilder(
            listenable: AppSession.instance,
            builder: (context, _) {
              return PlaceholderScreen(
                title: '마이페이지',
                message: '스탬프 보드·미션은 다음 단계에서 붙입니다.',
                icon: Icons.person_outline_rounded,
                extra: Text(
                  '스탬프 ${AppSession.instance.stampedStoreIds.length}개',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: TradadaBottomNav(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
        onStamp: () {
          setState(() => _index = 0);
          _mapKey.currentState?.openStampFlow();
        },
      ),
    );
  }
}
