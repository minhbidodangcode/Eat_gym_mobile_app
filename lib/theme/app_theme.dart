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

class AppColorsDark {
  static const Color background = Color(0xFF0B0E0D); // Nền đen OLED thuần
  static const Color surface = Color(0xFF111413); // Khối Card surface
  static const Color surfaceContainer = Color(0xFF151B18); // Container
  static const Color surfaceContainerHigh = Color(0xFF1A221E);
  static const Color surfaceContainerLow = Color(0xFF191C1B);
  static const Color surfaceContainerLowest = Color(0xFF0C0F0E);

  static const Color outline = Color(0xFF859585);
  static const Color outlineVariant = Color(0xFF3B4A3D);

  static const Color primary = Color(0xFF00E676); // Neon Green
  static const Color onPrimary = Color(0xFF003918);
  static const Color onSurface = Color(0xFFE1E3E1); // Chữ trắng sáng
  static const Color onSurfaceVariant = Color(0xFFBACBB9); // Chữ xám xanh nhẹ
}

class AppTheme {
  // Dynamic theme supporting real-time telemetry accent color & high contrast
  static ThemeData getDynamicTheme({
    required Brightness brightness,
    required Color primaryColor,
    bool highContrast = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0E0D) : const Color(0xFFF9FAFB);
    final surface = isDark ? const Color(0xFF151B18) : Colors.white;
    final text = isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A);
    final border = highContrast
        ? (isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF64748B))
        : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0));

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryColor,
              onPrimary: Colors.black,
              surface: surface,
              onSurface: text,
              outline: border,
            )
          : ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: surface,
              onSurface: text,
              outline: border,
            ),
      useMaterial3: true,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF0F172A),
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      textTheme: isDark
          ? GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme)
          : GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return getDynamicTheme(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0F172A),
    );
  }

  // Dark Theme (Kinetic Bio-Dark)
  static ThemeData get darkTheme {
    return getDynamicTheme(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF00E676),
    );
  }
}