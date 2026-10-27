import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/settings_screen.dart';

class BadgesHeader extends StatelessWidget {
  final VoidCallback? onAvatarTap;

  const BadgesHeader({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top App Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // NutriGym Brand Logo & Title
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191C1B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC4C7C5).withValues(alpha: 0.4)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fitness_center,
                      color: Color(0xFF00E676),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NUTRIGYM AI',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: const Color(0xFF747876),
                      ),
                    ),
                    Text(
                      'Vóc Dáng',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                        color: const Color(0xFF191C1D),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Nút mở Cài đặt hệ thống (SettingsScreen)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E2420)
                      : const Color(0xFFF1F3F4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF191C1D),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Subheading Category Tag
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF191C1D),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF191C1D).withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CLINICAL NUTRI-AUDIT & TROPHIES',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                color: const Color(0xFF5C5F5D),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Main Title
        Text(
          'Thành tựu & Báo cáo',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.03,
            color: const Color(0xFF191C1D),
          ),
        ),

        const SizedBox(height: 4),

        // Subtitle
        Text(
          'Hệ thống vinh danh Gymer Chef & Xuất hồ sơ dinh dưỡng lâm sàng',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF434846),
          ),
        ),
      ],
    );
  }
}
