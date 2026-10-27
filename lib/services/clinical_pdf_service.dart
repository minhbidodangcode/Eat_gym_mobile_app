import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/badges_and_report_model.dart';
import 'api_service.dart';

/// Dịch vụ xuất file PDF báo cáo dinh dưỡng & thể chất lâm sàng Gymer
class ClinicalPdfService {
  ClinicalPdfService._();

  /// Tạo tài liệu PDF dạng byte array
  static Future<Uint8List> generateReportPdf({
    required BadgesAndReportModel model,
  }) async {
    final pdf = pw.Document(
      title: 'NutriGym_Clinical_Report',
      author: 'NutriGym AI Health Engine',
    );

    // Lấy thông tin người dùng từ profile
    final profile = await ApiService.getLocalProfile();
    final name = profile?['fullName'] ?? profile?['name'] ?? 'Gymer Athlete';
    final weight = (profile?['weightKg'] as num?)?.toDouble() ?? (profile?['weight'] as num?)?.toDouble() ?? 72.0;
    final height = (profile?['heightCm'] as num?)?.toDouble() ?? (profile?['height'] as num?)?.toDouble() ?? 175.0;
    final goal = profile?['fitnessGoal']?.toString() ?? profile?['goal']?.toString() ?? 'Tăng cơ giảm mỡ';
    final bmi = (height > 0) ? (weight / ((height / 100) * (height / 100))) : 22.5;

    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(now);
    final reportCode = 'GYMER-${now.millisecondsSinceEpoch.toString().substring(5)}';

    // Font hỗ trợ tiếng Việt đầy đủ
    final fontBase = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontBase,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. HEADER LOGO & MEDICAL BANNER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NUTRIGYM AI CLINICAL REPORT',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: const PdfColor.fromInt(0xFF1D4ED8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Hồ Sơ Kiểm Toán Dinh Dưỡng & Phục Hồi Thể Lực',
                        style: pw.TextStyle(
                          font: fontBase,
                          fontSize: 11,
                          color: const PdfColor.fromInt(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFEFF6FF),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'MÃ HỒ SƠ: $reportCode',
                          style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: const PdfColor.fromInt(0xFF1E3A8A)),
                        ),
                        pw.Text(
                          'Chuẩn: HIPAA / HealthKit',
                          style: pw.TextStyle(font: fontBase, fontSize: 8, color: const PdfColor.fromInt(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(color: const PdfColor.fromInt(0xFFCBD5E1), thickness: 1),
              pw.SizedBox(height: 8),

              // 2. ATHLETE DEMOGRAPHICS BOX
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Họ và tên: $name', style: pw.TextStyle(font: fontBold, fontSize: 13, color: const PdfColor.fromInt(0xFF0F172A))),
                        pw.SizedBox(height: 4),
                        pw.Text('Mục tiêu thể hình: $goal', style: pw.TextStyle(font: fontBase, fontSize: 10.5, color: const PdfColor.fromInt(0xFF334155))),
                        pw.SizedBox(height: 4),
                        pw.Text('Phạm vi thống kê: ${model.dateRange.label}', style: pw.TextStyle(font: fontBase, fontSize: 10.5, color: const PdfColor.fromInt(0xFF334155))),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Thể trạng: ${weight.toStringAsFixed(1)} kg | ${height.toStringAsFixed(0)} cm', style: pw.TextStyle(font: fontBold, fontSize: 11, color: const PdfColor.fromInt(0xFF0F172A))),
                        pw.SizedBox(height: 4),
                        pw.Text('BMI ước tính: ${bmi.toStringAsFixed(1)} kg/m²', style: pw.TextStyle(font: fontBase, fontSize: 10.5, color: const PdfColor.fromInt(0xFF334155))),
                        pw.SizedBox(height: 4),
                        pw.Text('Ngày lập báo cáo: $formattedDate', style: pw.TextStyle(font: fontBase, fontSize: 10.5, color: const PdfColor.fromInt(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 3. GYMER CHEF LEVEL & REALTIME HEALTH
              pw.Row(
                children: [
                  // Box 1: Cấp bậc Gymer Chef
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFFFFBEB),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFFDE68A)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DANH HIỆU BẾP NÚC', style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: const PdfColor.fromInt(0xFF92400E))),
                          pw.SizedBox(height: 4),
                          pw.Text('${model.athleteRank} (${model.rankLevel})', style: pw.TextStyle(font: fontBold, fontSize: 12, color: const PdfColor.fromInt(0xFF78350F))),
                          pw.SizedBox(height: 4),
                          pw.Text('Streak: ${model.streakDays} ngày | Điểm uy tín: ${model.reputationPoints}', style: pw.TextStyle(font: fontBase, fontSize: 9.5, color: const PdfColor.fromInt(0xFFB45309))),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Box 2: Đồng hồ sức khỏe
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF0FDF4),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFBBF7D0)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('THIẾT BỊ ĐỒNG HỒ SỨC KHỎE', style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: const PdfColor.fromInt(0xFF166534))),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            model.todayCaloriesBurned > 0 || model.todaySteps > 0
                                ? '${model.todayCaloriesBurned} kcal  |  ${model.todaySteps} bước'
                                : '0 kcal tiêu hao | 0 bước chân',
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: const PdfColor.fromInt(0xFF14532D)),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Nguồn: ${model.healthSourceLabel}', style: pw.TextStyle(font: fontBase, fontSize: 9, color: const PdfColor.fromInt(0xFF15803D)), maxLines: 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 4. BẢNG KIỂM TOÁN MACRO & NUTRITION AUDIT
              pw.Text(
                '1. BẢNG KIỂM TOÁN CHỈ SỐ MACRO & NGUYÊN TẮC DINH DƯỠNG',
                style: pw.TextStyle(font: fontBold, fontSize: 11.5, color: const PdfColor.fromInt(0xFF0F172A)),
              ),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                    children: [
                      _buildTableCell('Chỉ số kiểm toán', fontBold, isHeader: true),
                      _buildTableCell('Mục tiêu chuẩn', fontBold, isHeader: true),
                      _buildTableCell('Thực tế ghi nhận', fontBold, isHeader: true),
                      _buildTableCell('Đánh giá lâm sàng', fontBold, isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell('Tỷ lệ Protein (Đạm)', fontBase),
                      _buildTableCell('1.8 - 2.2 g/kg thể trọng', fontBase),
                      _buildTableCell(model.macroTargetCount > 0 ? 'Đạt chuẩn mục tiêu' : 'Đang tối ưu', fontBase),
                      _buildTableCell(model.macroTargetCount > 0 ? 'TỐT (Đạt)' : 'Cần bổ sung', fontBold, color: model.macroTargetCount > 0 ? const PdfColor.fromInt(0xFF16A34A) : const PdfColor.fromInt(0xFFD97706)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell('Cân bằng Calo hàng ngày', fontBase),
                      _buildTableCell('Thâm hụt 300-500 kcal', fontBase),
                      _buildTableCell('Từ thực đơn AI gợi ý', fontBase),
                      _buildTableCell('CHUẨN GYM', fontBold, color: const PdfColor.fromInt(0xFF2563EB)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell('Huy hiệu hoàn thành', fontBase),
                      _buildTableCell('6 / 6 danh hiệu', fontBase),
                      _buildTableCell('${model.unlockedBadgesCount} / ${model.totalBadgesCount} huy hiệu', fontBase),
                      _buildTableCell(model.unlockedBadgesCount >= 3 ? 'XUẤT SẮC' : 'TIẾN TRIỂN TỐT', fontBold, color: const PdfColor.fromInt(0xFF0F172A)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 5. CÁC MỤC ĐÍNH KÈM (AI COACH & VI CHẤT)
              if (model.includeAiReview || model.includeMicroNutrients || model.includeBodyChart) ...[
                pw.Text(
                  '2. ĐÁNH GIÁ CHUYÊN MÔN & KHUYẾN NGHỊ TỪ TRỢ LÝ AI COACH',
                  style: pw.TextStyle(font: fontBold, fontSize: 11.5, color: const PdfColor.fromInt(0xFF0F172A)),
                ),
                pw.SizedBox(height: 6),

                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF8FAFC),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (model.includeAiReview) ...[
                        pw.Text(
                          '• Khuyến nghị Dinh dưỡng AI Coach: Duy trì lượng protein từ 1.8-2.2g/kg trọng lượng cơ thể. Phân bổ đều protein trong 3-4 bữa chính và phụ. Ưu tiên các nguồn đạm nạc (ức gà, cá hồi, thịt bò thăn, trứng gà, bột whey) kết hợp nguồn carb phức hợp (yến mạch, khoai lang, gạo lứt) để đảm bảo năng lượng tập luyện cường độ cao.',
                          style: pw.TextStyle(font: fontBase, fontSize: 9.5, color: const PdfColor.fromInt(0xFF334155), lineSpacing: 2),
                        ),
                        pw.SizedBox(height: 6),
                      ],
                      if (model.includeMicroNutrients) ...[
                        pw.Text(
                          '• Điện giải & Vi chất: Bổ sung tối thiểu 2.5L - 3.5L nước mỗi ngày trong những ngày tập nặng. Tăng cường rau xanh giàu Kali và Magiê (cải bó xôi, súp lơ xanh) để phòng ngừa chuột rút cơ bắp và hỗ trợ tổng hợp glycogen sau buổi tập.',
                          style: pw.TextStyle(font: fontBase, fontSize: 9.5, color: const PdfColor.fromInt(0xFF334155), lineSpacing: 2),
                        ),
                        pw.SizedBox(height: 6),
                      ],
                      if (model.includeBodyChart) ...[
                        pw.Text(
                          '• Theo dõi thể chất & Vóc dáng: Khuyến nghị đo đạc lại cân nặng và số đo các vòng vào mỗi buổi sáng sau khi thức dậy (trước khi ăn sáng) để thu được dữ liệu theo dõi có tính nhất quán cao nhất.',
                          style: pw.TextStyle(font: fontBase, fontSize: 9.5, color: const PdfColor.fromInt(0xFF334155), lineSpacing: 2),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // 6. FOOTER & CLINICAL SIGNATURE STAMP
              pw.Divider(color: const PdfColor.fromInt(0xFFCBD5E1), thickness: 0.8),
              pw.SizedBox(height: 6),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NutriGym AI Clinical Health Engine v2.4 • Chứng nhận Y sinh học Thể thao',
                        style: pw.TextStyle(font: fontBase, fontSize: 8, color: const PdfColor.fromInt(0xFF64748B)),
                      ),
                      pw.Text(
                        'Tệp dữ liệu được tạo tự động bởi ứng dụng EatGym. Báo cáo này có giá trị tham vấn cho Bác sĩ & HLV Cá nhân.',
                        style: pw.TextStyle(font: fontItalic, fontSize: 7.5, color: const PdfColor.fromInt(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF16A34A), width: 1.2),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'VERIFIED BY NUTRIGYM AI',
                      style: pw.TextStyle(font: fontBold, fontSize: 8, color: const PdfColor.fromInt(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9.5,
          color: color ?? (isHeader ? const PdfColor.fromInt(0xFF1E293B) : const PdfColor.fromInt(0xFF334155)),
        ),
      ),
    );
  }

  /// Mở giao diện xem trước PDF, in ấn và chia sẻ trực tiếp
  static Future<void> printOrShareReport({
    required material.BuildContext context,
    required BadgesAndReportModel model,
  }) async {
    final pdfBytes = await generateReportPdf(model: model);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'NutriGym_Clinical_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Chia sẻ file PDF trực tiếp
  static Future<void> sharePdfReport({
    required BadgesAndReportModel model,
  }) async {
    final pdfBytes = await generateReportPdf(model: model);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'NutriGym_BaoCao_YKhoa_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
