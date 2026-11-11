import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Backgrounds (from Figma) ──
  static const Color background = Color(0xFFF6FAFF); // Nền xanh nhạt chủ đạo (#F6FAFF)
  static const Color backgroundAlt = Color(0xFFF1F5F9); // Nền xám mát thay thế (#F1F5F9)
  static const Color backgroundLight = Color(0xFFECF5FE); // Nền xanh nhạt cho section/card (#ECF5FE)
  static const Color surface = Color(0xFFFFFFFF); // Nền trắng cho Card (#FFFFFF)
  static const Color surfaceContainer = Color(0xFFE6EFF8); // Container phụ (#E6EFF8)
  static const Color surfaceContainerAlt = Color(0xFFE0E9F2); // Container phụ đậm hơn (#E0E9F2)
  static const Color surfaceContainerHigh = Color(0xFFDBE4ED); // Container đậm (#DBE4ED)
  static const Color surfaceContainerLow = Color(0xFFF1F4F9); // Container nhẹ (#F1F4F9)
  static const Color surfaceContainerLowest = Color(0xFFFCFDFE); // Container nhẹ nhất (#FCFDFE)
  static const Color surfaceMuted = Color(0xFFF0F3F8); // Muted surface (#F0F3F8)
  static const Color surfaceTinted = Color(0xFFF8FAFC); // Tinted surface (#F8FAFC)

  // ── Outlines & Borders ──
  static const Color outline = Color(0xFFE0E9F2); // Viền chính (#E0E9F2)
  static const Color outlineVariant = Color(0xFFDBE4ED); // Viền phụ (#DBE4ED)
  static const Color outlineSubtle = Color(0xFFE6EFF8); // Viền nhẹ (#E6EFF8)

  // ── Primary & Text Colors ──
  static const Color primary = Color(0xFF0F172A); // Nút bấm, active states (#0F172A)
  static const Color onPrimary = Color(0xFFFFFFFF); // Chữ trên primary (#FFFFFF)
  static const Color onSurface = Color(0xFF000000); // Chữ đen chủ đạo (#000000)
  static const Color onSurfaceVariant = Color(0xFF5B5F63); // Chữ xám chủ đạo (#5B5F63)
  static const Color textMuted = Color(0xFF64748B); // Chữ xám mờ (#64748B)
  static const Color textSubtle = Color(0xFF475569); // Label nhẹ (#475569)
  static const Color textDark = Color(0xFF141D23); // Chữ đậm (#141D23)
  static const Color infoDark = Color(0xFF1E293B); // Info/secondary dark (#1E293B)

  // ── Shadows ──
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

  // ── Legacy aliases (backward compatible) ──
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFECF5FE);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF5B5F63);
  static const Color border = Color(0xFFE0E9F2);
  static const Color grey = Color(0xFF64748B);
  static const Color accent = Color(0xFF0F172A);
  static const Color success = Color(0xFF34C759);
  static const Color green = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color fire = Color(0xFFFF6B35);
  static const Color chipBackground = Color(0xFFECF5FE);
  static const Color chipBorder = Color(0xFFE0E9F2);
  static const Color timerRing = Color(0xFF0F172A);
  static const Color tabSelected = Color(0xFF0F172A);
  static const Color tabUnselected = Color(0xFFECF5FE);
  static const Color lightPurple = Color(0xFFECF5FE);
  static const Color cardDark = Color(0xFF4C4546);
  static const Color darkCard = Color(0xFF0F172A);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkTextMuted = Color(0xFF94A398);
}

class AppTypography {
  // ── Figma: Inter 10px/700 (55 occurrences — label chính) ──
  static TextStyle labelBold({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.04,
        color: color,
      );

  // ── Figma: Inter 12px/600 (18 occurrences) ──
  static TextStyle labelSemibold({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Figma: Inter 14px/600 ──
  static TextStyle labelLarge({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Figma: Inter 13px/400 (12 occurrences — body text) ──
  static TextStyle bodyDefault({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // ── Figma: Inter 15px/400 ──
  static TextStyle bodyLarge({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // ── Figma: Inter 17px/600 (14 occurrences — small title) ──
  static TextStyle titleSmall({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Figma: Inter 17px/700 ──
  static TextStyle titleSmallBold({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // ── Figma: Inter 20px/600 ──
  static TextStyle headlineMedium({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: color,
      );

  // ── Figma: Inter 24px/700 ──
  static TextStyle headlineLarge({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        color: color,
      );

  // ── Figma: Inter 48px/800 (metric display) ──
  static TextStyle displayMetric({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.03,
        color: color,
      );

  // ── Figma: Be Vietnam Pro 11px/700 (badge) ──
  static TextStyle badgeBold({Color color = AppColors.onSurface}) =>
      GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06,
        color: color,
      );

  // ── Figma: Be Vietnam Pro 13px/500 ──
  static TextStyle subtitleBody({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ── Figma: Be Vietnam Pro 17px/800 ──
  static TextStyle metricBold({Color color = AppColors.onSurface}) =>
      GoogleFonts.beVietnamPro(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: color,
      );

  // ── Figma: Plus Jakarta Sans 12px/600 ──
  static TextStyle chipLabel({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Figma: Plus Jakarta Sans 13px/600 ──
  static TextStyle chipLabelMedium({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Figma: Plus Jakarta Sans 14px/700 ──
  static TextStyle chipLabelBold({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // ── Legacy backward-compatible aliases ──
  static TextStyle displayLarge({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03,
        color: color,
      );

  static TextStyle metricValue({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        color: color,
      );

  static TextStyle headline({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: color,
      );

  static TextStyle badge({Color color = AppColors.onSurface}) =>
      badgeBold(color: color);

  static TextStyle titleMedium({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: color,
      );

  static TextStyle bodyMedium({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.01,
        color: color,
      );

  static TextStyle labelCaption({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
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
    final bg = isDark ? const Color(0xFF0B0E0D) : const Color(0xFFF6FAFF);
    final surface = isDark ? const Color(0xFF151B18) : Colors.white;
    final text = isDark ? const Color(0xFFE1E3E1) : const Color(0xFF000000);
    final border = highContrast
        ? (isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF475569))
        : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE0E9F2));

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
              primary: const Color(0xFF0F172A),
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
          ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          : GoogleFonts.interTextTheme(ThemeData.light().textTheme),
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