import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/badges_and_report_model.dart';
import '../theme/app_theme.dart';
import '../widgets/badge_collection_card.dart';
import '../widgets/level_progress_card.dart';
import '../widgets/pdf_export_card.dart';
import '../widgets/smartwatch_health_card.dart';

class BadgesAndReportScreen extends StatefulWidget {
  final bool isSubPage;

  const BadgesAndReportScreen({
    super.key,
    this.isSubPage = false,
  });

  @override
  State<BadgesAndReportScreen> createState() => _BadgesAndReportScreenState();
}

class _BadgesAndReportScreenState extends State<BadgesAndReportScreen> {
  final BadgesAndReportModel _model = BadgesAndReportModel.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _model.fetchAchievementsData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem màn hình có thể pop an toàn không
    final bool canPop = Navigator.canPop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B0E0D) : AppColors.background,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 32,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Thành Tựu & Báo Cáo',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: isDark ? const Color(0xFF1E293B) : AppColors.outline,
              height: 1,
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedBuilder(
          animation: _model,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: () => _model.fetchAchievementsData(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle & Header Tag
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CLINICAL NUTRI-AUDIT & TROPHIES',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hồ Sơ Danh Hiệu & Lâm Sàng',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hệ thống vinh danh Gymer Chef & Trích xuất hồ sơ dinh dưỡng y khoa',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Monolith 1: Overall Level & Progress
                    LevelProgressCard(model: _model),

                    const SizedBox(height: 18),

                    // Monolith 2: Smartwatch & Health Connect Real-Time Sync
                    SmartwatchHealthCard(model: _model, isDark: isDark),

                    const SizedBox(height: 18),

                    // Monolith 3: Gymer Chef Badge Collection Grid (Light mode)
                    BadgeCollectionCard(model: _model),

                    const SizedBox(height: 18),

                    // Monolith 4: PDF Medical & Clinical Nutrition Export Engine (Light mode)
                    PdfExportCard(model: _model),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
}
