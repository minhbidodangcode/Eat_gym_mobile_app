import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/badges_and_report_model.dart';

class BadgeCollectionCard extends StatelessWidget {
  final BadgesAndReportModel model;

  const BadgeCollectionCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final badges = model.filteredBadges;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF191C1B),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BỘ SƯU TẬP HUY HIỆU',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.01,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF181D1B),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  '4 MỚI',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC4C7C5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BadgeCategory.values.map((cat) {
                final isSelected = model.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => model.setSelectedCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF181D1B),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        cat.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF191C1D)
                              : const Color(0xFFC4C7C5),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 2-Column Badge Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 136,
            ),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return GestureDetector(
                onTap: () => _showBadgeDetailModal(context, badge),
                child: _buildBadgeTile(badge),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeTile(BadgeItem badge) {
    if (badge.isUnlocked) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF181D1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Icon and "ĐẠT" pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Icon(
                      badge.icon,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'ĐẠT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Badge Title
            Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),

            // Badge Description
            Text(
              badge.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFC4C7C5),
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    } else {
      // Locked Badge with progress
      return Opacity(
        opacity: 0.7,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF181D1B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: Lock icon and Progress ratio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock,
                        size: 18,
                        color: Color(0xFFC4C7C5),
                      ),
                    ),
                  ),
                  Text(
                    '${badge.currentProgress} / ${badge.maxProgress}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF747876),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Badge Title
              Text(
                badge.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC4C7C5),
                ),
              ),
              const SizedBox(height: 6),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 4,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.08),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: badge.progressRatio,
                    child: Container(
                      color: const Color(0xFFC4C7C5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showBadgeDetailModal(BuildContext context, BadgeItem badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF191C1B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Badge Icon Header with Glow
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.isUnlocked
                      ? Colors.amber.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: badge.isUnlocked
                        ? Colors.amber.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    badge.icon,
                    size: 36,
                    color: badge.isUnlocked ? Colors.amber : const Color(0xFFC4C7C5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Badge Title
              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Status Pill & Points
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badge.isUnlocked
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: badge.isUnlocked
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      badge.isUnlocked ? '✓ ĐÃ MỞ KHÓA' : '🔒 ĐANG KHÓA',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badge.isUnlocked ? Colors.greenAccent : const Color(0xFFC4C7C5),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '+${badge.points} Điểm Uy Tín',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nhiệm vụ chi tiết Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF181D1B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          'YÊU CẦU NHIỆM VỤ',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.description,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiến độ:',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC4C7C5),
                          ),
                        ),
                        Text(
                          '${badge.currentProgress} / ${badge.maxProgress}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: badge.isUnlocked ? Colors.greenAccent : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 6,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.08),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: badge.progressRatio,
                          child: Container(
                            color: badge.isUnlocked ? Colors.greenAccent : Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Button Đóng
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF191C1B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'ĐÃ HIỂU',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
