import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import 'login_screen.dart';
import 'meal_prep_screen.dart';

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

        final bgColor = isDark ? const Color(0xFF0B0E0D) : const Color(0xFFF9FAFB);
        final cardColor = isDark ? const Color(0xFF151B18) : const Color(0xFFFFFFFF);
        final textColor = isDark ? const Color(0xFFE1E3E1) : const Color(0xFF191C1D);
        final subTextColor = isDark ? const Color(0xFF94A398) : const Color(0xFF747876);
        final borderColor = highContrast
            ? (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.35))
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06));

        return Scaffold(
          backgroundColor: bgColor,
      appBar: AppBar(
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
              style: GoogleFonts.spaceGrotesk(
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
                style: GoogleFonts.spaceGrotesk(
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                    style: GoogleFonts.spaceGrotesk(
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
                                    style: GoogleFonts.spaceGrotesk(
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
                              style: GoogleFonts.manrope(
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
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Cập nhật bảo mật sinh trắc & mã PIN',
                                  style: GoogleFonts.manrope(
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
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isDark ? 'OLED Stealth Active' : 'Luminous Light Active',
                        style: GoogleFonts.spaceGrotesk(
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
                        style: GoogleFonts.spaceGrotesk(
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
                            style: GoogleFonts.spaceGrotesk(
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
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tối ưu trường nhìn khi tập tạ',
                            style: GoogleFonts.manrope(
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
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tăng cường viền OLED và text readouts',
                                style: GoogleFonts.manrope(
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
                            activeThumbColor: primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white,
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
                        style: GoogleFonts.spaceGrotesk(
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
                                    style: GoogleFonts.spaceGrotesk(
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
                                    style: GoogleFonts.spaceGrotesk(
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
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Đồng bộ nhịp sinh học & trao đổi chất',
                                style: GoogleFonts.manrope(
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
                            activeThumbColor: primaryColor.computeLuminance() > 0.4 ? Colors.black : Colors.white,
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
                          _buildReminderRow(
                            icon: Icons.water_drop_outlined,
                            title: 'Giờ nhắc uống nước',
                            timeNotifier: _settings.waterTimeNotifier,
                            type: 'water',
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

                  const SizedBox(height: 12),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 10),

                  // Lối tắt: Kế hoạch Meal Prep & Nhắc nhở rã đông
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealPrepScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F3F4),
                            ),
                            child: Icon(Icons.kitchen_outlined, size: 17, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kế hoạch Meal Prep & Nhắc rã đông',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Chia khẩu phần theo hộp & hẹn giờ rã đông tự động',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: subTextColor),
                        ],
                      ),
                    ),
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
                      style: GoogleFonts.spaceGrotesk(
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
                        style: GoogleFonts.spaceGrotesk(
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
                    style: GoogleFonts.manrope(
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
                        style: GoogleFonts.manrope(
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
          style: GoogleFonts.spaceGrotesk(
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
                style: GoogleFonts.spaceGrotesk(
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
              style: GoogleFonts.spaceGrotesk(
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
                style: GoogleFonts.spaceGrotesk(
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
          style: GoogleFonts.spaceGrotesk(
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
              style: GoogleFonts.spaceGrotesk(
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
              style: GoogleFonts.spaceGrotesk(
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
                      style: GoogleFonts.spaceGrotesk(
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
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mật khẩu mới phải có tối thiểu 6 ký tự để đảm bảo an toàn.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Old Password
                  TextField(
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    style: GoogleFonts.manrope(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      labelStyle: GoogleFonts.manrope(color: subTextColor),
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
                    style: GoogleFonts.manrope(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      labelStyle: GoogleFonts.manrope(color: subTextColor),
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
                    style: GoogleFonts.manrope(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      labelStyle: GoogleFonts.manrope(color: subTextColor),
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
                        foregroundColor: Colors.black,
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
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : Text(
                              'Cập nhật mật khẩu',
                              style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700),
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF151B18) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Xác nhận đăng xuất',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng NutriGym AI không?',
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Hủy',
                style: GoogleFonts.spaceGrotesk(color: Colors.grey),
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
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}
