import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TradadaBottomNav extends StatelessWidget {
  const TradadaBottomNav({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onStamp,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onStamp;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(Icons.home_rounded, '홈', 0),
              _item(Icons.shopping_bag_outlined, '예약내역', 1),
              Expanded(
                child: GestureDetector(
                  onTap: onStamp,
                  child: Column(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldDeep.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            color: AppColors.navy,
                            size: 28,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: const Text(
                          '스탬프 찍기',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _item(Icons.notifications_none_rounded, '알림', 2),
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
