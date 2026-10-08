import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF9FAFB); // Nền xám cực nhạt (gần trắng) cho Scaffold
  static const Color surface = Color(0xFFFFFFFF); // Màu nền trắng tinh cho các khối Card
  static const Color surfaceContainer = Color(0xFFF3F4F6); // Xám nhạt cho vùng chứa phụ
  static const Color surfaceContainerHigh = Color(0xFFE5E7EB);
  static const Color surfaceContainerLow = Color(0xFFF9FAFB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Outlines & Borders
  static const Color outline = Color(0xFFA1A1AA); // Viền xám nhạt
  static const Color outlineVariant = Color(0xFFE4E4E7);
  static const Color outlineSubtle = Color(0xFFF4F4F5);

  // Monochrome Accents
  static const Color primary = Color(0xFF0F172A); // Đen ánh xanh (dùng cho các nút bấm đang chọn)
  static const Color onPrimary = Color(0xFFFFFFFF); // Chữ trắng trên nền primary đen
  static const Color onSurface = Color(0xFF09090B); // Chữ màu đen đậm nhất cho tiêu đề
  static const Color onSurfaceVariant = Color(0xFF52525B); // Chữ xám đậm cho phần mô tả

  // Shadows
  static List<BoxShadow> buttonGlow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> activeChipGlow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> dotPulseGlow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  // ── Legacy aliases (merged from app_colors.dart) ──
  static const Color darkNavy = Color(0xFF1B2438);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF5F6FA);
  static const Color textPrimary = Color(0xFF1B2438);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color border = Color(0xFFE5E5EA);
  static const Color grey = Color(0xFF8E8E93);
  static const Color accent = Color(0xFF1B2438);
  static const Color success = Color(0xFF34C759);
  static const Color green = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color fire = Color(0xFFFF6B35);
  static const Color chipBackground = Color(0xFFF2F2F7);
  static const Color chipBorder = Color(0xFFD1D1D6);
  static const Color timerRing = Color(0xFF1B2438);
  static const Color tabSelected = Color(0xFF1B2438);
  static const Color tabUnselected = Color(0xFFF2F2F7);
  static const Color lightPurple = Color(0xFFEDE8F5);
}

class AppTypography {
  // Đổi mặc định color = Colors.white thành color = AppColors.onSurface (Màu đen)
  static TextStyle displayLarge({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03,
        color: color,
      );

  static TextStyle metricValue({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        color: color,
      );

  static TextStyle headline({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: color,
      );

  static TextStyle badge({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06,
        color: color,
      );

  static TextStyle titleMedium({Color color = AppColors.onSurface}) =>
      GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: color,
      );

  static TextStyle bodyMedium({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.01,
        color: color,
      );

  static TextStyle labelCaption({Color color = AppColors.outline}) =>
      GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.04,
        color: color,
      );
}

class AppTheme {
  // Đổi tên thành lightTheme để đúng chuẩn
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light, // Set Brightness sáng
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
    );
  }
}