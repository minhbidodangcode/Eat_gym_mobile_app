import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/badges_and_report_model.dart';
import 'sparkline_chart.dart';

class PdfExportCard extends StatelessWidget {
  final BadgesAndReportModel model;

  const PdfExportCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF191C1B),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Medical Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DÀNH CHO BÁC SĨ & HLV CÁ NHÂN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: const Center(
                  child: Icon(
                    Icons.picture_as_pdf,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Title
          Text(
            'Báo cáo Toàn diện Dinh dưỡng & Thể chất PDF',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.01,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            'Trích xuất đầy đủ biểu đồ biến thiên cân nặng (74.5kg → 72.4kg), chỉ số thâm hụt calo trung bình, tỷ lệ % mỡ, cùng toàn bộ nhật ký macro & thực đơn đã quét bằng AI.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFC4C7C5),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Visual Clinical Snapshot Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF181D1B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'XU HƯỚNG KHỐI LƯỢNG NẠC & MỠ',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                        color: const Color(0xFFC4C7C5),
                      ),
                    ),
                    Text(
                      '-2.1 kg (4 Tuần)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sparkline Graph
                const SparklineChart(
                  dataPoints: [32, 28, 30, 22, 25, 16, 14, 6],
                  lineColor: Colors.white,
                  strokeWidth: 2.5,
                ),

                const SizedBox(height: 10),

                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thâm hụt TB',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFC4C7C5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '-385 kcal / ngày',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mỡ cơ thể ước tính',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFC4C7C5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '14.8% (-1.2%)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Date Range Selector
          Text(
            'PHẠM VI THỜI GIAN XUẤT:',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: const Color(0xFFC4C7C5),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: DateRangeFilter.values.map((range) {
              final isSelected = model.dateRange == range;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => model.setDateRange(range),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF181D1B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          range.label,
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
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Checkbox Options
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF181D1B).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MỤC DỮ LIỆU ĐÍNH KÈM:',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: const Color(0xFFC4C7C5),
                  ),
                ),
                const SizedBox(height: 8),

                _buildCheckboxRow(
                  label: 'Biểu đồ vóc dáng & Cân nặng',
                  value: model.includeBodyChart,
                  onChanged: model.toggleBodyChart,
                ),
                _buildCheckboxRow(
                  label: 'Bảng vi chất & Điện giải khoáng',
                  value: model.includeMicroNutrients,
                  onChanged: model.toggleMicroNutrients,
                ),
                _buildCheckboxRow(
                  label: 'Nhận xét & Đánh giá từ AI Coach',
                  value: model.includeAiReview,
                  onChanged: model.toggleAiReview,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Primary Export Action Button
          GestureDetector(
            onTap: model.exportStatus == ExportStatus.generating
                ? null
                : () => model.exportPdf(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _buildExportButtonContent(model.exportStatus),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Medical & HIPAA Compliance Disclaimer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 13,
                color: Color(0xFFC4C7C5),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Tệp PDF chuẩn in ấn A4, mã hóa sinh trắc học chuẩn HIPAA & Apple HealthKit.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFC4C7C5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: value ? Colors.white : const Color(0xFFC4C7C5),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      size: 13,
                      color: Color(0xFF191C1D),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButtonContent(ExportStatus status) {
    switch (status) {
      case ExportStatus.generating:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF191C1D)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ĐANG TẠO HỒ SƠ Y KHOA...',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: const Color(0xFF191C1D),
              ),
            ),
          ],
        );
      case ExportStatus.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 20,
              color: Color(0xFF191C1D),
            ),
            const SizedBox(width: 8),
            Text(
              'ĐÃ TẢI FILE THÀNH CÔNG!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: const Color(0xFF191C1D),
              ),
            ),
          ],
        );
      case ExportStatus.idle:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download,
              size: 20,
              color: Color(0xFF191C1D),
            ),
            const SizedBox(width: 8),
            Text(
              'XUẤT FILE PDF & CHIA SẺ NGAY',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: const Color(0xFF191C1D),
              ),
            ),
          ],
        );
    }
  }
}
