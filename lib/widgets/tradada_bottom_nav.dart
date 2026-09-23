import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StampFab extends StatefulWidget {
  const StampFab({super.key, required this.onTap, this.alert = false});

  final VoidCallback onTap;
  final bool alert;

  @override
  State<StampFab> createState() => _StampFabState();
}

class _StampFabState extends State<StampFab> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.alert) _glow.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StampFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alert && !_glow.isAnimating) {
      _glow.repeat(reverse: true);
    } else if (!widget.alert && _glow.isAnimating) {
      _glow.stop();
      _glow.value = 0;
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final t = widget.alert ? _glow.value : 0.0;
        return Transform.scale(
          scale: 1 + t * 0.08,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35 + t * 0.55),
                  blurRadius: 8 + t * 18,
                  spreadRadius: t * 6,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: FloatingActionButton(
        onPressed: widget.onTap,
        tooltip: widget.alert ? 'QR 인증하기' : '스탬프 찍기',
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
        elevation: widget.alert ? 16 : 10,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 32),
      ),
    );
  }
}

class TradadaBottomNav extends StatelessWidget {
  const TradadaBottomNav({
    super.key,
    required this.index,
    required this.onSelect,
  });

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 7,
      color: const Color(0xFFF8FBFF),
      elevation: 12,
      padding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(Icons.home_rounded, '홈', 0),
              _item(Icons.receipt_long_outlined, '이용내역', 1),
              const SizedBox(width: 76),
              _item(Icons.groups_outlined, '커뮤니티', 2),
              _item(Icons.person_outline_rounded, '마이페이지', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int i) {
    final selected = index == i;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.navy : const Color(0xFF9AA3AF),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.navy : const Color(0xFF9AA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
