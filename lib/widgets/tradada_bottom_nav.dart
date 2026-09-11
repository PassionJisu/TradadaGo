import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StampFab extends StatelessWidget {
  const StampFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      tooltip: '스탬프 찍기',
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.navy,
      elevation: 10,
      shape: const CircleBorder(),
      child: const Icon(Icons.qr_code_scanner_rounded, size: 32),
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
              _item(Icons.shopping_bag_outlined, '예약내역', 1),
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
