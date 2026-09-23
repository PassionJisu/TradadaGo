import 'package:flutter/material.dart';

import '../state/indoor_qr_cue.dart';
import '../widgets/tradada_bottom_nav.dart';
import 'home_map_screen.dart';
import 'my_page_screen.dart';
import 'reservations_screen.dart';
import 'community_screen.dart';

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
      extendBody: true,
      floatingActionButtonLocation: _StayDockedFabLocation.center,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: ListenableBuilder(
        listenable: IndoorQrCue.instance,
        builder: (context, _) {
          return StampFab(
            alert: IndoorQrCue.instance.ready,
            onTap: () {
              setState(() => _index = 0);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapKey.currentState?.openStampFlow();
              });
            },
          );
        },
      ),
      body: IndexedStack(
        index: _index,
        children: [
          HomeMapScreen(key: _mapKey),
          const ReservationsScreen(),
          const CommunityScreen(),
          const MyPageScreen(),
        ],
      ),
      bottomNavigationBar: TradadaBottomNav(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Keeps the yellow stamp button in the bottom-nav notch when a SnackBar appears.
class _StayDockedFabLocation extends FloatingActionButtonLocation {
  const _StayDockedFabLocation._();

  static const _StayDockedFabLocation center = _StayDockedFabLocation._();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;
    final double fabY = scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height / 2.0;
    return Offset(fabX, fabY);
  }
}
