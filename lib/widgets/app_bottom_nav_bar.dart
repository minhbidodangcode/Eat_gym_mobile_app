import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppBottomNavBar({
    super.key,
    this.selectedIndex = 0, // Mặc định là Tab 0: FoodBlog
    required this.onItemSelected,
  });

  // 5 Mục chuẩn theo hệ thống thiết kế EatGym Figma
  static const List<Map<String, dynamic>> navItems = [
    {
      'label': 'FoodBlog',
      'icon': Icons.restaurant_menu_outlined,
      'activeIcon': Icons.restaurant_menu,
    },
    {
      'label': 'Tìm kiếm',
      'icon': Icons.search_rounded,
      'activeIcon': Icons.search_rounded,
    },
    {
      'label': 'Hồ sơ',
      'icon': Icons.person_outline_rounded,
      'activeIcon': Icons.person_rounded,
    },
    {
      'label': 'Kế hoạch',
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_today_rounded,
    },
    {
      'label': 'Cài đặt',
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E9F2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64, // Chuẩn chiều cao 64px trong Figma Nav Frame
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = selectedIndex == index;
              final item = navItems[index];
              final IconData icon = isSelected
                  ? (item['activeIcon'] as IconData)
                  : (item['icon'] as IconData);

              final Color activeColor = isDark ? Colors.white : const Color(0xFF0F172A);
              final Color inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    onItemSelected(index);
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 23,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
