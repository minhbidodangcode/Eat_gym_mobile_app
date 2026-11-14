import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import 'login_screen.dart';
import 'smart_fridge_screen.dart';
import 'body_stats_screen.dart';
import 'badges_and_report_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;

  String _userName = 'Vận động viên';
  String _userEmail = 'athlete@eatgym.com';
  String _userRole = 'PRO ATHLETE';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // 1. Ưu tiên nạp ngay từ bộ nhớ cục bộ (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString('user_email');
      final cachedName = prefs.getString('user_full_name');
      final cachedRole = prefs.getString('user_role');
      if (mounted && (cachedEmail != null || cachedName != null)) {
        setState(() {
          if (cachedEmail != null && cachedEmail.isNotEmpty) _userEmail = cachedEmail;
          if (cachedName != null && cachedName.isNotEmpty) _userName = cachedName;
          if (cachedRole != null && cachedRole.isNotEmpty) _userRole = cachedRole.toUpperCase();
        });
      }

      // 2. Nạp trực tiếp từ JWT payload (luôn có email và role trong token)
      final jwt = await ApiService.getJwtPayload();
      if (jwt != null && mounted) {
        final email = jwt['email']?.toString();
        final role = jwt['role']?.toString();
        if (email != null && email.isNotEmpty) {
          setState(() {
            _userEmail = email;
            if (_userName == 'Vận động viên') {
              _userName = email.contains('@') ? email.split('@')[0] : email;
            }
            if (role != null) {
              _userRole = role.toUpperCase();
            }
          });
        }
      }

      // 3. Truy vấn backend /auth/me để cập nhật dữ liệu tài khoản mới nhất
      final user = await ApiService.getUserInfo();
      if (user != null && mounted) {
        setState(() {
          _userName = user['fullName'] ?? user['name'] ?? user['email']?.split('@')[0] ?? _userName;
          if (user['email'] != null && user['email'].toString().isNotEmpty) {
            _userEmail = user['email'].toString();
          }
          if (user['role'] != null) {
            _userRole = (user['role'] ?? 'ATHLETE').toString().toUpperCase();
          }
        });
        return;
      }

      // 4. Đồng bộ thêm họ tên từ profile nếu có
      final profile = await ApiService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          if (profile['full_name'] != null) {
            _userName = profile['full_name'];
          }
        });
      }
    } catch (_) {}
  }

  void _changeThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == ThemeMode.light
                ? '✨ Đã chuyển sang chế độ Giao diện Sáng'
                : mode == ThemeMode.dark
                    ? '🌙 Đã chuyển sang chế độ Giao diện Tối'
                    : '⚙️ Đã đồng bộ giao diện theo Hệ thống thiết bị',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeAccentColor(String key) async {
    await _settings.setAccentColor(key);
    if (mounted) {
      setState(() {});
      final name = key == 'cyan_tech' ? 'Cyan Tech' : key == 'fire_amber' ? 'Fire Amber' : 'Neon Green';
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎨 Đã kích hoạt bảng màu nhấn: $name'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeFontScale(double scale) async {
    await _settings.setFontScale(scale);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scale > 1.0 ? '🔍 Đã chuyển sang kích thước chữ: Lớn' : '🔍 Đã chuyển sang kích thước chữ: Tiêu chuẩn'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeHighContrast(bool val) async {
    await _settings.setHighContrast(val);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? '👁️ Đã bật chế độ Tương phản cao' : '👁️ Đã tắt chế độ Tương phản cao'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeUnitSystem(String sys) async {
    await _settings.setUnitSystem(sys);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sys == 'imperial' ? '📏 Đã chuyển hệ đo: Imperial (lbs, ft-in)' : '📏 Đã chuyển hệ đo: Metric (kg, cm)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeUnitWeight(String w) async {
    await _settings.setUnitWeight(w);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚖️ Đã chọn đơn vị cân nặng: $w'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeUnitHeight(String h) async {
    await _settings.setUnitHeight(h);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📐 Đã chọn đơn vị chiều cao: $h'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _settings.themeModeNotifier,
        _settings.accentColorNotifier,
        _settings.fontScaleNotifier,
        _settings.highContrastNotifier,
        _settings.unitSystemNotifier,
        _settings.unitWeightNotifier,
        _settings.unitHeightNotifier,
        _settings.remindersEnabledNotifier,
        _settings.waterTimeNotifier,
        _settings.mealTimeNotifier,
        _settings.workoutTimeNotifier,
      ]),
      builder: (context, _) {
        final mode = _settings.themeModeNotifier.value;
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                (Theme.of(context).brightness == Brightness.dark ||
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark));
        final primaryColor = _settings.currentColor;
        final highContrast = _settings.highContrastNotifier.value;

        final bgColor = isDark ? const Color(0xFF0B0E0D) : AppColors.background;
        final cardColor = isDark ? const Color(0xFF151B18) : AppColors.surface;
        final textColor = isDark ? const Color(0xFFE1E3E1) : AppColors.onSurface;
        final subTextColor = isDark ? const Color(0xFF94A398) : AppColors.textMuted;
        final borderColor = highContrast
            ? (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.35))
            : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outline);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
          backgroundColor: bgColor,
          appBar: Navigator.canPop(context)
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1E2420) : Colors.white,
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cài đặt hệ thống',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          'CONFIG & PREFERENCES',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E2420) : Colors.white,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: subTextColor,
                      ),
                    ),
                  ],
                )
              : null,
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------------
                // FEATURED SPOTLIGHT BENTO: KHO NGUYÊN LIỆU (SMART FRIDGE)
                // Chuẩn theo settings_inventory.json Figma
                // ---------------------------------------------------------
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECF5FE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFF000000),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.kitchen_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KHO NGUYÊN LIỆU THÔNG MINH',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                                    ),
                                  ),
                                  Text(
                                    'Tủ Lạnh & Thực Phẩm',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ĐANG THEO DÕI',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Quản lý thực phẩm trong ngăn mát và ngăn đông. AI tự động cảnh báo hạn dùng và gợi ý món nấu ăn Eat Clean.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SmartFridgeScreen()),
                                );
                              },
                              icon: const Icon(Icons.inventory_2_outlined, size: 16),
                              label: Text(
                                'Mở Kho Nguyên Liệu',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : const Color(0xFF000000),
                                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---------------------------------------------------------
                // SHORTCUTS GYMER: VÓC DÁNG & BÁO CÁO THÀNH TỰU
                // ---------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BodyStatsScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.monitor_weight_outlined, size: 22, color: Color(0xFF3B82F6)),
                              const SizedBox(height: 6),
                              Text(
                                'Chỉ số vóc dáng',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'InBody & Cân nặng',
                                style: GoogleFonts.inter(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BadgesAndReportScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.military_tech_outlined, size: 22, color: Color(0xFFF59E0B)),
                              const SizedBox(height: 6),
                              Text(
                                'Thành tựu & PDF',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Huy hiệu & Báo cáo',
                                style: GoogleFonts.inter(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---------------------------------------------------------
                // KHỐI 1: TÀI KHOẢN & BẢO MẬT
                // ---------------------------------------------------------
            _buildSectionHeader('HỒ SƠ VẬN ĐỘNG VIÊN', hasActiveSync: true, primaryColor: primaryColor),
            const SizedBox(height: 8),
            _buildCard(
              cardColor: cardColor,
              borderColor: borderColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [primaryColor.withValues(alpha: 0.8), const Color(0xFF111413)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: primaryColor, width: 1.5),
                            ),
                            child: ClipOval(
                              child: ValueListenableBuilder<String>(
                                valueListenable: SettingsService.instance.userAvatarNotifier,
                                builder: (context, avatarUrl, _) {
                                  if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
                                    return Image.network(
                                      avatarUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.person, color: Colors.white, size: 28),
                                      ),
                                    );
                                  }
                                  final file = File(avatarUrl);
                                  if (file.existsSync()) {
                                    return Image.file(
                                      file,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.person, color: Colors.white, size: 28),
                                      ),
                                    );
                                  }
                                  return const Center(
                                    child: Icon(Icons.person, color: Colors.white, size: 28),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 10, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _userName,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    _userRole,
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 8),

                  // Nút Bệnh lí và dị ứng
                  InkWell(
                    onTap: () => _showMedicalAndAllergiesDialog(context, primaryColor, cardColor, textColor, subTextColor, borderColor, isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                            ),
                            child: Icon(Icons.health_and_safety_outlined, size: 18, color: const Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bệnh lí và dị ứng',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Cập nhật bệnh lý kiêng cữ & dị ứng thực phẩm',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: subTextColor, size: 20),
                        ],
                      ),
                    ),
                  ),

                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 8),

                  // Nút Ứng dụng liên kết (Đồng hồ thông minh & Chợ online)
                  InkWell(
                    onTap: () => _showConnectedAppsDialog(context, primaryColor, cardColor, textColor, subTextColor, borderColor, isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                            ),
                            child: const Icon(Icons.hub_outlined, size: 18, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ứng dụng liên kết',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Đồng hồ thông minh & Ứng dụng chợ online',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: subTextColor, size: 20),
                        ],
                      ),
                    ),
                  ),

                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showChangePasswordDialog(context, primaryColor, cardColor, textColor, subTextColor, borderColor),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                            ),
                            child: Icon(Icons.lock_reset_rounded, size: 18, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đổi mật khẩu',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Cập nhật bảo mật sinh trắc & mã PIN',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: subTextColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------------------
            // KHỐI 2: CÁ NHÂN HÓA GIAO DIỆN (THEME & DISPLAY)
            // ---------------------------------------------------------
            _buildSectionHeader('GIAO DIỆN & HIỂN THỊ', primaryColor: primaryColor),
            const SizedBox(height: 8),
            _buildCard(
              cardColor: cardColor,
              borderColor: borderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_outlined, size: 18, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Chế độ hiển thị',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isDark ? 'OLED Stealth Active' : 'Luminous Light Active',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: _settings.themeModeNotifier,
                    builder: (context, currentMode, _) {
                      return Row(
                        children: [
                          _buildThemeOption(
                            title: 'Sáng',
                            selected: currentMode == ThemeMode.light,
                            onTap: () => _changeThemeMode(ThemeMode.light),
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildThemeOption(
                            title: '• Tối',
                            selected: currentMode == ThemeMode.dark,
                            onTap: () => _changeThemeMode(ThemeMode.dark),
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildThemeOption(
                            title: 'Hệ thống',
                            selected: currentMode == ThemeMode.system,
                            onTap: () => _changeThemeMode(ThemeMode.system),
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),

                  // Màu nhấn chủ đạo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Màu nhấn chủ đạo (Telemetry Accent)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: _settings.accentColorNotifier,
                        builder: (context, colorKey, _) {
                          String label = 'NEON GREEN';
                          if (colorKey == 'cyan_tech') label = 'CYAN TECH';
                          if (colorKey == 'fire_amber') label = 'FIRE AMBER';
                          return Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: _settings.accentColorNotifier,
                    builder: (context, currentColorKey, _) {
                      return Row(
                        children: [
                          _buildAccentColorOption(
                            keyName: 'neon_green',
                            label: 'Neon\nGreen',
                            color: const Color(0xFF00E676),
                            selected: currentColorKey == 'neon_green',
                            onTap: () => _changeAccentColor('neon_green'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildAccentColorOption(
                            keyName: 'cyan_tech',
                            label: 'Cyan\nTech',
                            color: const Color(0xFF00E5FF),
                            selected: currentColorKey == 'cyan_tech',
                            onTap: () => _changeAccentColor('cyan_tech'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildAccentColorOption(
                            keyName: 'fire_amber',
                            label: 'Fire\nAmber',
                            color: const Color(0xFFFFB300),
                            selected: currentColorKey == 'fire_amber',
                            onTap: () => _changeAccentColor('fire_amber'),
                            isDark: isDark,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),

                  // Kích thước chữ hệ thống
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kích thước chữ hệ thống',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tối ưu trường nhìn khi tập tạ',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                      ValueListenableBuilder<double>(
                        valueListenable: _settings.fontScaleNotifier,
                        builder: (context, scale, _) {
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                _buildPillChoice(
                                  text: 'Tiêu chuẩn',
                                  active: scale <= 1.0,
                                  onTap: () => _changeFontScale(1.0),
                                  primaryColor: primaryColor,
                                ),
                                _buildPillChoice(
                                  text: 'Lớn',
                                  active: scale > 1.0,
                                  onTap: () => _changeFontScale(1.15),
                                  primaryColor: primaryColor,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Độ tương phản cao
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                            ),
                            child: Icon(Icons.contrast_rounded, size: 16, color: primaryColor),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Độ tương phản cao (High Contrast)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tăng cường viền OLED và text readouts',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _settings.highContrastNotifier,
                        builder: (context, highContrast, _) {
                          return Switch(
                            value: highContrast,
                            onChanged: (val) => _changeHighContrast(val),
                            activeColor: primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white,
                            activeTrackColor: primaryColor,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------------------
            // KHỐI 3: TÙY CHỌN ĐƠN VỊ & SINH HOẠT
            // ---------------------------------------------------------
            _buildSectionHeader('ĐƠN VỊ & NHẮC NHỞ', primaryColor: primaryColor),
            const SizedBox(height: 8),
            _buildCard(
              cardColor: cardColor,
              borderColor: borderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hệ thống đo lường chung (unit_system: metric / imperial)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hệ thống chuẩn (Unit System)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: _settings.unitSystemNotifier,
                        builder: (context, sys, _) {
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                _buildPillChoice(
                                  text: 'Metric',
                                  active: sys == 'metric',
                                  onTap: () => _changeUnitSystem('metric'),
                                  primaryColor: primaryColor,
                                ),
                                _buildPillChoice(
                                  text: 'Imperial',
                                  active: sys == 'imperial',
                                  onTap: () => _changeUnitSystem('imperial'),
                                  primaryColor: primaryColor,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2 Bộ chọn đơn vị Cân nặng & Chiều cao
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111613) : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cân nặng',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: subTextColor,
                                    ),
                                  ),
                                  Icon(Icons.scale_outlined, size: 14, color: primaryColor),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ValueListenableBuilder<String>(
                                valueListenable: _settings.unitWeightNotifier,
                                builder: (context, unitWeight, _) {
                                  return Row(
                                    children: [
                                      _buildUnitButton('kg', unitWeight == 'kg', () => _changeUnitWeight('kg'), primaryColor),
                                      const SizedBox(width: 6),
                                      _buildUnitButton('lbs', unitWeight == 'lbs', () => _changeUnitWeight('lbs'), primaryColor),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111613) : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Chiều cao',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: subTextColor,
                                    ),
                                  ),
                                  Icon(Icons.height_rounded, size: 16, color: primaryColor),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ValueListenableBuilder<String>(
                                valueListenable: _settings.unitHeightNotifier,
                                builder: (context, unitHeight, _) {
                                  return Row(
                                    children: [
                                      _buildUnitButton('cm', unitHeight == 'cm', () => _changeUnitHeight('cm'), primaryColor),
                                      const SizedBox(width: 6),
                                      _buildUnitButton('ft-in', unitHeight == 'ft_in', () => _changeUnitHeight('ft_in'), primaryColor),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),

                  // Cài đặt Nhắc nhở thông minh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                            ),
                            child: Icon(Icons.notifications_active_outlined, size: 18, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bật nhắc nhở thông minh',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Đồng bộ nhịp sinh học & trao đổi chất',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _settings.remindersEnabledNotifier,
                        builder: (context, enabled, _) {
                          return Switch(
                            value: enabled,
                            onChanged: (val) => _settings.setRemindersEnabled(val),
                            activeColor: primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white,
                            activeTrackColor: primaryColor,
                          );
                        },
                      ),
                    ],
                  ),

                  // Các mốc giờ nhắc
                  ValueListenableBuilder<bool>(
                    valueListenable: _settings.remindersEnabledNotifier,
                    builder: (context, enabled, _) {
                      if (!enabled) return const SizedBox.shrink();
                      return Column(
                        children: [
                          const SizedBox(height: 14),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 12),
                          _buildWaterReminderRow(
                            primaryColor: primaryColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildReminderRow(
                            icon: Icons.restaurant_menu_rounded,
                            title: 'Giờ nhắc ghi nhật ký bữa ăn',
                            timeNotifier: _settings.mealTimeNotifier,
                            type: 'meal',
                            primaryColor: primaryColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildReminderRow(
                            icon: Icons.fitness_center_rounded,
                            title: 'Giờ nhắc tập luyện',
                            timeNotifier: _settings.workoutTimeNotifier,
                            type: 'workout',
                            primaryColor: primaryColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            isDark: isDark,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ---------------------------------------------------------
            // KHỐI 4: NÚT ĐĂNG XUẤT (LOGOUT / DANGER ZONE)
            // ---------------------------------------------------------
            InkWell(
              onTap: () => _confirmLogout(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1416) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF4B4B).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFFF4B4B), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Đăng xuất tài khoản',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF4B4B),
                        letterSpacing: -0.01,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ---------------------------------------------------------
            // FOOTER & THÔNG TIN PHIÊN BẢN
            // ---------------------------------------------------------
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, size: 18, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'NutriGym AI',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NutriGym AI v1.2.0 • Build 2026',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 12, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(
                        'Mã hóa sinh trắc học chuẩn HIPAA & Apple HealthKit',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    );
  },
);
  }

  // --- Sub-widgets & Builders ---

  Widget _buildSectionHeader(String title, {bool hasActiveSync = false, required Color primaryColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
            color: const Color(0xFF767B79),
          ),
        ),
        if (hasActiveSync)
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Active Sync',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCard({
    required Widget child,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildThemeOption({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    required Color primaryColor,
    required bool isDark,
  }) {
    final activeTextColor = primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor
                : (isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? primaryColor
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
              width: selected ? 1.5 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? activeTextColor
                    : (isDark ? const Color(0xFF94A398) : const Color(0xFF52525B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccentColorOption({
    required String keyName,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF1E2420) : Colors.white)
                : (isDark ? const Color(0xFF111413) : const Color(0xFFF8F9FA)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? (isDark ? Colors.white : Colors.black) : (isDark ? const Color(0xFF94A398) : const Color(0xFF767B79)),
                  height: 1.1,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillChoice({
    required String text,
    required bool active,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    final activeTextColor = primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? activeTextColor : const Color(0xFF767B79),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitButton(String label, bool active, VoidCallback onTap, Color primaryColor) {
    final activeTextColor = primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? activeTextColor : const Color(0xFF767B79),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterReminderRow({
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _settings.waterIntervalNotifier,
        _settings.waterStartHourNotifier,
        _settings.waterEndHourNotifier,
      ]),
      builder: (context, _) {
        final interval = _settings.waterIntervalNotifier.value;
        final startHour = _settings.waterStartHourNotifier.value;
        final endHour = _settings.waterEndHourNotifier.value;
        final startStr = '${startHour.toString().padLeft(2, '0')}:00';
        final endStr = '${endHour.toString().padLeft(2, '0')}:00';

        void showEditWaterDialog() {
          int tempInterval = interval;
          int tempStartHour = startHour;
          int tempEndHour = endHour;
          final customCtrl = TextEditingController(text: '$tempInterval');

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: isDark ? const Color(0xFF1E2420) : Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (ctx) => StatefulBuilder(
              builder: (ctx, setModalState) {
                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                      left: 20,
                      right: 20,
                      top: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.water_drop, color: primaryColor, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Cài đặt nhắc nhở uống nước',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tùy chỉnh tần suất lặp lại và khung giờ nhắc nhở phù hợp với lịch trình của bạn.',
                          style: TextStyle(color: subTextColor, fontSize: 12.5),
                        ),
                        const SizedBox(height: 18),

                        // Phần 1: Tần suất nhắc
                        Text(
                          '1. Khoảng cách nhắc nhở (Tần suất):',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [15, 30, 45, 60, 90, 120].map((mins) {
                            final isSel = tempInterval == mins;
                            return ChoiceChip(
                              label: Text('$mins phút'),
                              selected: isSel,
                              selectedColor: primaryColor,
                              backgroundColor: isDark ? const Color(0xFF262E2A) : const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : textColor,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12.5,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    tempInterval = mins;
                                    customCtrl.text = '$mins';
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Hoặc tự nhập số phút: ', style: TextStyle(fontSize: 12, color: subTextColor)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              height: 36,
                              child: TextField(
                                controller: customCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF262E2A) : const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  suffixText: 'p',
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val.trim());
                                  if (parsed != null && parsed > 0 && parsed <= 360) {
                                    setModalState(() => tempInterval = parsed);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Phần 2: Khung giờ nhắc trong ngày
                        Text(
                          '2. Khung giờ nhắc nhở trong ngày:',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bắt đầu từ:', style: TextStyle(fontSize: 11.5, color: subTextColor)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF262E2A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: tempStartHour,
                                        isExpanded: true,
                                        dropdownColor: isDark ? const Color(0xFF1E2420) : Colors.white,
                                        items: List.generate(11, (i) => i + 5).map((h) => DropdownMenuItem(
                                          value: h,
                                          child: Text('${h.toString().padLeft(2, '0')}:00 sáng', style: TextStyle(color: textColor, fontSize: 13)),
                                        )).toList(),
                                        onChanged: (val) {
                                          if (val != null) setModalState(() => tempStartHour = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kết thúc lúc:', style: TextStyle(fontSize: 11.5, color: subTextColor)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF262E2A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: tempEndHour,
                                        isExpanded: true,
                                        dropdownColor: isDark ? const Color(0xFF1E2420) : Colors.white,
                                        items: List.generate(8, (i) => i + 17).map((h) => DropdownMenuItem(
                                          value: h,
                                          child: Text('${h.toString().padLeft(2, '0')}:00 tối', style: TextStyle(color: textColor, fontSize: 13)),
                                        )).toList(),
                                        onChanged: (val) {
                                          if (val != null) setModalState(() => tempEndHour = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Nút Xác nhận lưu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('LƯU CÀI ĐẶT NHẮC UỐNG NƯỚC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () {
                              _settings.setWaterReminderSchedule(
                                interval: tempInterval,
                                startHour: tempStartHour,
                                endHour: tempEndHour,
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('💧 Đã cài đặt nhắc uống nước mỗi $tempInterval phút (từ ${tempStartHour}h00 đến ${tempEndHour}h00)!'),
                                  backgroundColor: primaryColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

          return InkWell(
          onTap: showEditWaterDialog,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.water_drop_outlined, size: 18, color: primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhắc uống nước ($interval phút / lần)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Khung giờ: Từ $startStr đến $endStr',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      '$interval phút',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 12, color: primaryColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReminderRow({
    required IconData icon,
    required String title,
    required ValueNotifier<String> timeNotifier,
    required String type,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: subTextColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
        ValueListenableBuilder<String>(
          valueListenable: timeNotifier,
          builder: (context, timeStr, _) {
            return InkWell(
              onTap: () => _pickReminderTime(context, type, timeStr),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 12, color: primaryColor),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickReminderTime(BuildContext context, String type, String currentTime) async {
    final parts = currentTime.split(':');
    final initialHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 30 : 30;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      final newTime = '$hourStr:$minuteStr';
      await _settings.setReminderTime(type, newTime);
    }
  }

  void _showChangePasswordDialog(
    BuildContext context,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final onPrimaryColor = primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: subTextColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đổi mật khẩu tài khoản',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mật khẩu mới phải có tối thiểu 6 ký tự để đảm bảo an toàn.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Old Password
                  TextField(
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    style: GoogleFonts.inter(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      labelStyle: GoogleFonts.inter(color: subTextColor),
                      prefixIcon: Icon(Icons.lock_outline, color: primaryColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, color: subTextColor, size: 18),
                        onPressed: () => setModalState(() => obscureOld = !obscureOld),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // New Password
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style: GoogleFonts.inter(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      labelStyle: GoogleFonts.inter(color: subTextColor),
                      prefixIcon: Icon(Icons.vpn_key_outlined, color: primaryColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: subTextColor, size: 18),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Confirm New Password
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    style: GoogleFonts.inter(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      labelStyle: GoogleFonts.inter(color: subTextColor),
                      prefixIcon: Icon(Icons.check_circle_outline, color: primaryColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: subTextColor, size: 18),
                        onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: onPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final oldPw = oldPasswordController.text.trim();
                              final newPw = newPasswordController.text.trim();
                              final confirmPw = confirmPasswordController.text.trim();

                              if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng điền đầy đủ các thông tin')),
                                );
                                return;
                              }
                              if (newPw.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mật khẩu mới phải có tối thiểu 6 ký tự')),
                                );
                                return;
                              }
                              if (newPw != confirmPw) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                await ApiService.changePassword(oldPw, newPw);
                                if (modalContext.mounted) {
                                  Navigator.of(modalContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đổi mật khẩu thành công!'),
                                      backgroundColor: Color(0xFF00E676),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: onPrimaryColor, strokeWidth: 2.5),
                            )
                          : Text(
                              'Cập nhật mật khẩu',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: onPrimaryColor,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HỘP THOẠI: ỨNG DỤNG LIÊN KẾT (ĐỒNG HỒ THÔNG MINH & CHỢ ONLINE)
  // ---------------------------------------------------------------------------
  void _showConnectedAppsDialog(
    BuildContext context,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
    bool isDark,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    bool connectAppleHealth = prefs.getBool('connect_apple_health') ?? true;
    bool connectGarmin = prefs.getBool('connect_garmin') ?? false;
    bool connectStrava = prefs.getBool('connect_strava') ?? true;
    bool connectSamsung = prefs.getBool('connect_samsung_health') ?? false;
    bool connectGoogleFit = prefs.getBool('connect_google_fit') ?? true;
    bool connectNothingX = prefs.getBool('connect_nothing_x') ?? true;

    bool connectGrabMart = prefs.getBool('connect_grabmart') ?? true;
    bool connectShopeeFood = prefs.getBool('connect_shopeefood') ?? true;
    bool connectCoopmart = prefs.getBool('connect_coopmart') ?? false;
    bool connectWinmart = prefs.getBool('connect_winmart') ?? false;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return SafeArea(
            child: Container(
              height: MediaQuery.of(modalCtx).size.height * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.hub_rounded, color: Color(0xFF8B5CF6), size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ứng dụng liên kết',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kết nối thiết bị & dịch vụ ngoại vi để tự động hóa dinh dưỡng EatGym:',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      children: [
                        // PHẦN 1: ĐỒNG HỒ THÔNG MINH
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.watch_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Text(
                                'ĐỒNG HỒ THÔNG MINH & WEARABLE',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildAppTile(
                          icon: Icons.apple_rounded,
                          title: 'Apple Health / Apple Watch',
                          subtitle: 'Đồng bộ nhịp tim, bước chân & Calo đốt cháy theo thời gian thực',
                          color: const Color(0xFF0F172A),
                          isConnected: connectAppleHealth,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectAppleHealth = val);
                            prefs.setBool('connect_apple_health', val);
                          },
                        ),
                        _buildAppTile(
                          icon: Icons.directions_run_rounded,
                          title: 'Garmin Connect',
                          subtitle: 'Đồng bộ cường độ tập tạ kháng lực & phục hồi cơ bắp',
                          color: const Color(0xFF007CC3),
                          isConnected: connectGarmin,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectGarmin = val);
                            prefs.setBool('connect_garmin', val);
                          },
                        ),
                        _buildAppTile(
                          icon: Icons.directions_bike_rounded,
                          title: 'Strava',
                          subtitle: 'Tự động tính năng lượng bù đắp sau mỗi buổi đạp xe & chạy bộ',
                          color: const Color(0xFFFC4C02),
                          isConnected: connectStrava,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectStrava = val);
                            prefs.setBool('connect_strava', val);
                          },
                        ),
                                                _buildAppTile(
                          icon: Icons.monitor_heart_outlined,
                          title: 'Samsung Health',
                          subtitle: 'Đồng bộ năng lượng tiêu hao & dữ liệu giấc ngủ phục hồi',
                          color: const Color(0xFF1428A0),
                          isConnected: connectSamsung,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectSamsung = val);
                            prefs.setBool('connect_samsung_health', val);
                          },
                        ),
                        _buildAppTile(
                          icon: Icons.favorite_rounded,
                          title: 'Google Fit / Wear OS',
                          subtitle: 'Đồng bộ dữ liệu sức khỏe thể hình trên Android Wear',
                          color: const Color(0xFFEA4335),
                          isConnected: connectGoogleFit,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectGoogleFit = val);
                            prefs.setBool('connect_google_fit', val);
                          },
                        ),
                        _buildAppTile(
                          icon: Icons.watch_outlined,
                          title: 'Nothing X / CMF Watch',
                          subtitle: 'Đồng bộ nhịp tim, bước chân & Calo tiêu hao từ đồng hồ Nothing qua Health Connect',
                          color: const Color(0xFFD71920),
                          isConnected: connectNothingX,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectNothingX = val);
                            prefs.setBool('connect_nothing_x', val);
                          },
                        ),

                        const SizedBox(height: 16),

                        // PHẦN 2: ỨNG DỤNG CHỢ ONLINE
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart_outlined, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Text(
                                'ỨNG DỤNG ĐI CHỢ & MUA SẮM ONLINE',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildAppTile(
                          icon: Icons.delivery_dining_rounded,
                          title: 'GrabMart (Giao siêu tốc 30p)',
                          subtitle: 'Tự động xuất danh sách thiếu hụt trong Tủ Lạnh sang giỏ hàng Grab',
                          color: const Color(0xFF00B14F),
                          isConnected: connectGrabMart,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectGrabMart = val);
                            prefs.setBool('connect_grabmart', val);
                          },
                        ),
                        _buildAppTile(
                          icon: Icons.shopping_bag_outlined,
                          title: 'ShopeeFood / Shopee Mart',
                          subtitle: 'So sánh giá thực phẩm tươi sống rẻ nhất & áp mã giảm giá Gymer',
                          color: const Color(0xFFEE4D2D),
                          isConnected: connectShopeeFood,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectShopeeFood = val);
                            prefs.setBool('connect_shopeefood', val);
                          },
                        ),
                        _buildAppTile(
                          icon: Icons.storefront_rounded,
                          title: 'WinMart / Bách Hóa Xanh',
                          subtitle: 'Liên kết thẻ thành viên tích điểm khi mua ức gà, thịt bò & rau xanh',
                          color: const Color(0xFFDC2626),
                          isConnected: connectWinmart,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectWinmart = val);
                            prefs.setBool('connect_winmart', val);
                          },
                        ),
                        _buildAppTile(
                          icon: Icons.eco_rounded,
                          title: 'Co.opmart Online',
                          subtitle: 'Ưu tiên nguồn nông sản sạch chuẩn VietGAP cho bữa ăn Eat Clean',
                          color: const Color(0xFF2563EB),
                          isConnected: connectCoopmart,
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onChanged: (val) {
                            setModalState(() => connectCoopmart = val);
                            prefs.setBool('connect_coopmart', val);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Nút Lưu
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('LƯU CẤU HÌNH LIÊN KẾT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✨ Đã lưu cấu hình liên kết thiết bị & chợ online thành công!'),
                            backgroundColor: Color(0xFF8B5CF6),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isConnected,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? color.withValues(alpha: 0.4) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: isConnected ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: subTextColor, height: 1.25)),
              ],
            ),
          ),
          Switch(
            value: isConnected,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HỘP THOẠI: BỆNH LÍ & DỊ ỨNG (GIAO DIỆN HIỆN ĐẠI, ĐỒNG BỘ APP)
  // ---------------------------------------------------------------------------
  void _showMedicalAndAllergiesDialog(
    BuildContext context,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
    bool isDark,
  ) async {
    final prefsInstance = await SharedPreferences.getInstance();
    final profile = await ApiService.getLocalProfile();

    final rawMedical = prefsInstance.getStringList('medical_history') ??
        (profile?['medicalHistory'] != null ? List<String>.from(profile!['medicalHistory']) : <String>[]);
    final rawAllergies = prefsInstance.getStringList('food_allergies') ??
        prefsInstance.getStringList('user_allergies') ??
        (profile?['allergies'] != null ? List<String>.from(profile!['allergies']) : <String>[]);

    final Set<String> selectedMedical = Set<String>.from(rawMedical);
    if (selectedMedical.isEmpty) selectedMedical.add('Không có tiền sử bệnh');

    final Set<String> selectedAllergies = Set<String>.from(rawAllergies);
    if (selectedAllergies.isEmpty) selectedAllergies.add('Không có dị ứng');

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return SafeArea(
            child: Container(
              height: MediaQuery.of(modalCtx).size.height * 0.88,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header cố định
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.health_and_safety_outlined, color: Color(0xFF0284C7), size: 22),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bệnh lí & Dị ứng thực phẩm',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Banner giải thích bảo vệ AI
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI NutriGym sẽ tự động phân tích và loại trừ các nguyên liệu kiêng cữ khỏi thực đơn của bạn.',
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF0369A1), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      children: [
                        // PHẦN 1: BỆNH LÝ MẮC PHẢI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '🩺 Bệnh lý mắc phải & Chế độ ăn kiêng:',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Kiêng & Hạn chế', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Bắt buộc chọn ít nhất 1 mục (Chọn "Không có..." nếu cơ thể hoàn toàn khỏe mạnh):', style: TextStyle(fontSize: 11, color: subTextColor)),
                        const SizedBox(height: 8),

                        Column(
                          children: [
                            {'name': 'Gout (Kiêng purin/thịt đỏ/hải sản)', 'icon': '🥩'},
                            {'name': 'Tiểu đường (Hạn chế đường nhanh)', 'icon': '🍬'},
                            {'name': 'Huyết áp cao (Hạn chế muối natri)', 'icon': '🧂'},
                            {'name': 'Đau dạ dày / Trào ngược (Kiêng chua cay/gas)', 'icon': '🌶️'},
                            {'name': 'Mỡ máu cao (Hạn chế mỡ xấu)', 'icon': '🥑'},
                            {'name': 'Bệnh lý thận (Hạn chế thừa đạm)', 'icon': '🫘'},
                            {'name': 'Không có tiền sử bệnh', 'icon': '🛡️'},
                          ].map((item) {
                            final med = item['name']!;
                            final icon = item['icon']!;
                            final isSel = selectedMedical.contains(med);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    if (med == 'Không có tiền sử bệnh') {
                                      selectedMedical.clear();
                                      selectedMedical.add('Không có tiền sử bệnh');
                                    } else {
                                      if (isSel) {
                                        selectedMedical.remove(med);
                                        if (selectedMedical.isEmpty) selectedMedical.add('Không có tiền sử bệnh');
                                      } else {
                                        selectedMedical.remove('Không có tiền sử bệnh');
                                        selectedMedical.add(med);
                                      }
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? (isDark ? const Color(0xFF0284C7).withValues(alpha: 0.25) : const Color(0xFFE0F2FE))
                                        : (isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF0284C7) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      width: isSel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(icon, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          med,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                            color: isSel ? (isDark ? Colors.white : const Color(0xFF0369A1)) : textColor,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                        size: 18,
                                        color: isSel ? const Color(0xFF0284C7) : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // PHẦN 2: DỊ ỨNG THỰC PHẨM
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '⚠️ Dị ứng thực phẩm (Food Allergies):',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Cảnh báo dị ứng', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Các chất hoặc món gây dị ứng, ngứa, khó tiêu (Bắt buộc chọn ít nhất 1 mục):', style: TextStyle(fontSize: 11, color: subTextColor)),
                        const SizedBox(height: 8),

                        Column(
                          children: [
                            {'name': 'Hải sản (Tôm, Cua, Mực)', 'icon': '🦐'},
                            {'name': 'Đậu phộng / Lạc', 'icon': '🥜'},
                            {'name': 'Sữa bò / Bất dung nạp Lactose', 'icon': '🥛'},
                            {'name': 'Trứng gà', 'icon': '🥚'},
                            {'name': 'Gluten / Bột mì', 'icon': '🌾'},
                            {'name': 'Đậu nành', 'icon': '🫘'},
                            {'name': 'Không có dị ứng', 'icon': '🛡️'},
                          ].map((item) {
                            final alg = item['name']!;
                            final icon = item['icon']!;
                            final isSel = selectedAllergies.contains(alg);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    if (alg == 'Không có dị ứng') {
                                      selectedAllergies.clear();
                                      selectedAllergies.add('Không có dị ứng');
                                    } else {
                                      if (isSel) {
                                        selectedAllergies.remove(alg);
                                        if (selectedAllergies.isEmpty) selectedAllergies.add('Không có dị ứng');
                                      } else {
                                        selectedAllergies.remove('Không có dị ứng');
                                        selectedAllergies.add(alg);
                                      }
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? (isDark ? const Color(0xFFD97706).withValues(alpha: 0.25) : const Color(0xFFFEF3C7))
                                        : (isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFFD97706) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      width: isSel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(icon, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          alg,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                            color: isSel ? (isDark ? Colors.white : const Color(0xFFB45309)) : textColor,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                        size: 18,
                                        color: isSel ? const Color(0xFFD97706) : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Nút Lưu thay đổi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('LƯU BỆNH LÍ & DỊ ỨNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList('medical_history', selectedMedical.toList());
                        await prefs.setStringList('food_allergies', selectedAllergies.toList());
                        await prefs.setStringList('user_allergies', selectedAllergies.toList());

                        final currentProf = Map<String, dynamic>.from(await ApiService.getLocalProfile() ?? {});
                        currentProf['medicalHistory'] = selectedMedical.toList();
                        currentProf['allergies'] = selectedAllergies.toList();
                        await ApiService.saveLocalProfile(currentProf);

                        if (modalCtx.mounted) {
                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🩺 Đã lưu Bệnh lí & Dị ứng thành công! Toàn bộ hệ thống và Chatbot AI sẽ tự động đồng bộ.'),
                              backgroundColor: Color(0xFF0284C7),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF151B18) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Xác nhận đăng xuất',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng NutriGym AI không?',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Hủy',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text(
                'Đăng xuất',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}
