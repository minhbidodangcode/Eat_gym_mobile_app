import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badges_and_report_model.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smartwatch_health_card.dart';
import 'update_body_stats_screen.dart';

class BodyStatsScreen extends StatefulWidget {
  const BodyStatsScreen({super.key});

  @override
  State<BodyStatsScreen> createState() => _BodyStatsScreenState();
}

class _BodyStatsScreenState extends State<BodyStatsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Cân nặng', '% Mỡ', 'Số đo'];

  double _weight = 70.0;
  double _initialWeight = 72.0;
  double _targetWeight = 68.0;
  double _bodyFat = 17.5;
  double _targetFat = 15.0;
  String _fitnessGoal = 'Giảm mỡ';
  int _goalTimelineDays = 60;
  String _lastMeasuredDate = 'Hôm nay';
  Map<String, int> _measurements = {
    'Vòng ngực': 96,
    'Vòng eo': 78,
    'Vòng mông': 94,
    'Bắp tay': 32,
    'Đùi': 54,
  };
  List<String> _weightLabels = ['T1', 'T3', 'T5', 'T7', 'Hôm nay'];
  List<double> _weightValues = [72.0, 71.5, 71.0, 70.5, 70.0];
  List<String> _fatLabels = ['T1', 'T3', 'T5', 'T7', 'Hôm nay'];
  List<double> _fatValues = [19.0, 18.5, 18.2, 17.8, 17.5];

  double get _leanMass => _weight * (1 - (_bodyFat / 100));
  double get _fatMass => _weight * (_bodyFat / 100);

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BadgesAndReportModel.instance.fetchAchievementsData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profile = await ApiService.getLocalProfile() ?? await ApiService.getProfile();

      // 1. Fitness goal
      final savedGoal = prefs.getString('fitness_goal');
      if (savedGoal != null && savedGoal.isNotEmpty) {
        _fitnessGoal = savedGoal;
      } else if (profile != null && profile['fitnessGoal'] != null) {
        final g = profile['fitnessGoal'].toString();
        if (g == 'bulking') {
          _fitnessGoal = 'Tăng cơ';
        } else if (g == 'cutting') {
          _fitnessGoal = 'Giảm mỡ';
        } else {
          _fitnessGoal = 'Duy trì vóc dáng';
        }
      }

      // 2. Current weight
      final savedWeight = prefs.getDouble('body_weight_kg');
      if (savedWeight != null && savedWeight > 0) {
        _weight = savedWeight;
      } else if (profile != null) {
        final w = (profile['weightKg'] as num?)?.toDouble();
        if (w != null && w > 0) _weight = w;
      }

      // 3. Initial weight (to track journey)
      final savedInitWeight = prefs.getDouble('initial_weight_kg');
      if (savedInitWeight != null && savedInitWeight > 0) {
        _initialWeight = savedInitWeight;
      } else {
        _initialWeight = _weight;
        await prefs.setDouble('initial_weight_kg', _initialWeight);
      }

      // 4. Target weight
      final savedTargetWeight = prefs.getDouble('target_weight_kg');
      if (savedTargetWeight != null && savedTargetWeight > 0) {
        _targetWeight = savedTargetWeight;
      } else if (profile != null && profile['targetWeightKg'] != null) {
        _targetWeight = (profile['targetWeightKg'] as num).toDouble();
      } else {
        if (_fitnessGoal == 'Tăng cơ') {
          _targetWeight = _weight + 3.0;
        } else if (_fitnessGoal == 'Giảm mỡ') {
          _targetWeight = _weight - 3.0;
        } else {
          _targetWeight = _weight;
        }
      }

      // 5. Current body fat & Target body fat
      final savedFat = prefs.getDouble('body_fat_percent');
      if (savedFat != null && savedFat > 0) {
        _bodyFat = savedFat;
      }
      final savedTargetFat = prefs.getDouble('target_fat_percent');
      if (savedTargetFat != null && savedTargetFat > 0) {
        _targetFat = savedTargetFat;
      } else {
        _targetFat = _fitnessGoal == 'Tăng cơ' ? 16.0 : (_fitnessGoal == 'Giảm mỡ' ? 14.0 : 15.0);
      }

      _goalTimelineDays = prefs.getInt('goal_timeline_days') ?? 60;

      // 6. Body measurements
      final savedMeas = prefs.getString('body_measurements');
      if (savedMeas != null && savedMeas.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(savedMeas);
        for (final k in _measurements.keys) {
          if (decoded.containsKey(k)) {
            _measurements[k] = (decoded[k] as num).toInt();
          }
        }
      }

      // 7. Load Combined History (Local + Backend)
      final List<Map<String, dynamic>> combinedHistory = [];
      final localHistoryStr = prefs.getString('local_body_stats_history');
      if (localHistoryStr != null && localHistoryStr.isNotEmpty) {
        try {
          final List<dynamic> localList = jsonDecode(localHistoryStr);
          for (final item in localList) {
            if (item is Map) combinedHistory.add(Map<String, dynamic>.from(item));
          }
        } catch (_) {}
      }

      try {
        final remoteHistory = await ApiService.getBodyStatsHistory();
        for (final rh in remoteHistory) {
          final date = rh['measuredOn']?.toString();
          if (!combinedHistory.any((item) => item['measuredOn']?.toString() == date)) {
            combinedHistory.add(rh);
          }
        }
      } catch (_) {}

      combinedHistory.sort((a, b) {
        final da = a['measuredOn']?.toString() ?? '';
        final db = b['measuredOn']?.toString() ?? '';
        return da.compareTo(db);
      });

      if (combinedHistory.isNotEmpty) {
        final latest = combinedHistory.last;
        final lw = (latest['weightKg'] as num?)?.toDouble();
        if (lw != null && lw > 0) _weight = lw;
        final lfat = (latest['bodyFatPercent'] as num?)?.toDouble();
        if (lfat != null && lfat > 0) _bodyFat = lfat;
        if (latest['measuredOn'] != null) {
          _lastMeasuredDate = latest['measuredOn'].toString();
        }

        if (combinedHistory.length >= 2) {
          final recent = combinedHistory.length > 7
              ? combinedHistory.sublist(combinedHistory.length - 7)
              : combinedHistory;
          _weightLabels = recent.map((h) {
            final parts = (h['measuredOn']?.toString() ?? '').split('-');
            return parts.length >= 2 ? '${parts[parts.length - 1]}/${parts[parts.length - 2]}' : (parts.last.isEmpty ? 'Nay' : parts.last);
          }).toList();
          _weightValues = recent.map((h) => ((h['weightKg'] as num?)?.toDouble() ?? _weight)).toList();
          _fatLabels = List<String>.from(_weightLabels);
          _fatValues = recent.map((h) => ((h['bodyFatPercent'] as num?)?.toDouble() ?? _bodyFat)).toList();
        } else {
          // Exactly 1 entry: build realistic trend leading to this single real point
          _weightLabels = ['T1', 'T3', 'T5', 'T7', 'Hôm nay'];
          final startW = _initialWeight;
          _weightValues = [
            startW,
            startW + (_weight - startW) * 0.25,
            startW + (_weight - startW) * 0.5,
            startW + (_weight - startW) * 0.75,
            _weight,
          ];
          _fatLabels = ['T1', 'T3', 'T5', 'T7', 'Hôm nay'];
          _fatValues = [
            _bodyFat + 1.2,
            _bodyFat + 0.9,
            _bodyFat + 0.6,
            _bodyFat + 0.3,
            _bodyFat,
          ];
        }
      } else {
        _weightLabels = ['T1', 'T3', 'T5', 'T7', 'Hôm nay'];
        _weightValues = [_weight + 1.2, _weight + 0.9, _weight + 0.6, _weight + 0.3, _weight];
        _fatLabels = ['T1', 'T3', 'T5', 'T7', 'Hôm nay'];
        _fatValues = [_bodyFat + 1.0, _bodyFat + 0.8, _bodyFat + 0.5, _bodyFat + 0.2, _bodyFat];
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: BadgesAndReportModel.instance,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryAccent = SettingsService.instance.currentColor;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0E0D) : AppColors.surfaceContainerLow,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Header
                        Text(
                          'Biểu đồ vóc dáng',
                          style: AppTypography.displayLarge(
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ).copyWith(
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tab Bar
                        _buildTabBar(isDark, primaryAccent),
                        const SizedBox(height: 20),

                        // Tab Content - each tab builds its own full content
                        if (_selectedTabIndex == 0) ..._buildWeightTabContent(isDark, primaryAccent),
                        if (_selectedTabIndex == 1) ..._buildFatTabContent(isDark, primaryAccent),
                        if (_selectedTabIndex == 2) ..._buildMeasurementsTabContent(isDark, primaryAccent),
                      ],
                    ),
                  ),
                ),

                // Bottom Button
                _buildBottomButton(isDark, primaryAccent),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab Bar
  // ═══════════════════════════════════════════════════

  Widget _buildTabBar(bool isDark, Color primaryAccent) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? primaryAccent : AppColors.primary) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[index],
                  style: AppTypography.headline(
                    color: isSelected
                        ? (isDark ? Colors.black : AppColors.onPrimary)
                        : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                  ).copyWith(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 1: Cân nặng
  // ═══════════════════════════════════════════════════

  List<Widget> _buildWeightTabContent(bool isDark, Color primaryAccent) {
    return [
      _buildWeightChart(isDark, primaryAccent),
      const SizedBox(height: 16),
      _buildGoalRoadmapCard(isDark, primaryAccent),
      const SizedBox(height: 16),
      _buildWeightStatsRow(isDark),
      const SizedBox(height: 16),
      SmartwatchHealthCard(model: BadgesAndReportModel.instance),
      const SizedBox(height: 20),
      _buildBadgesSection(isDark, primaryAccent),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildWeightChart(bool isDark, Color primaryAccent) {
    final diff = (_weight - _targetWeight).abs();
    final isDown = _weight >= _targetWeight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight value and target
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _weight.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'kg',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _showEditGoalModal,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark ? primaryAccent : AppColors.primary).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isDark ? primaryAccent : AppColors.primary).withValues(alpha: isDark ? 0.35 : 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.track_changes, size: 14, color: isDark ? primaryAccent : AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Mục tiêu: ${_targetWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? primaryAccent : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_outlined, size: 13, color: isDark ? primaryAccent : AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Change indicator
          Row(
            children: [
              Icon(
                diff < 0.2 ? Icons.check_circle : (isDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
                size: 18,
                color: diff < 0.2 ? const Color(0xFF00E676) : (isDark ? const Color(0xFF60A5FA) : Colors.blue[600]),
              ),
              const SizedBox(width: 4),
              Text(
                diff < 0.2 ? 'Đạt chuẩn mục tiêu vóc dáng' : '${diff.toStringAsFixed(1)} kg đến mục tiêu',
                style: TextStyle(
                  fontSize: 14,
                  color: diff < 0.2 ? const Color(0xFF00E676) : (isDark ? const Color(0xFF60A5FA) : Colors.blue[600]),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _WeightChartPainter(
                labels: _weightLabels,
                values: _weightValues,
                isDark: isDark,
                primaryAccent: primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStatsRow(bool isDark) {
    return Row(
      children: [
        // Fat percentage card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151B18) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_bodyFat.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tỷ lệ mỡ',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Cooking streak card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151B18) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 6),
                    Text(
                      '${BadgesAndReportModel.instance.streakDays > 0 ? BadgesAndReportModel.instance.streakDays : 12}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày tự nấu',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 2: % Mỡ
  // ═══════════════════════════════════════════════════

  List<Widget> _buildFatTabContent(bool isDark, Color primaryAccent) {
    return [
      _buildFatChart(isDark, primaryAccent),
      const SizedBox(height: 16),
      _buildGoalRoadmapCard(isDark, primaryAccent),
      const SizedBox(height: 16),
      _buildBodyCompositionRow(isDark),
      const SizedBox(height: 16),
      _buildNhanXetCard(isDark),
      const SizedBox(height: 16),
      SmartwatchHealthCard(model: BadgesAndReportModel.instance),
      const SizedBox(height: 20),
      _buildBadgesSection(isDark, primaryAccent),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildFatChart(bool isDark, Color primaryAccent) {
    final fatDiff = (_bodyFat - _targetFat).abs();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fat value and target
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _bodyFat.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _showEditGoalModal,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark ? primaryAccent : AppColors.primary).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isDark ? primaryAccent : AppColors.primary).withValues(alpha: isDark ? 0.35 : 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.track_changes, size: 14, color: isDark ? primaryAccent : AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Mục tiêu: ${_targetFat.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? primaryAccent : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_outlined, size: 13, color: isDark ? primaryAccent : AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Change indicator
          Row(
            children: [
              Icon(
                fatDiff < 0.2 ? Icons.check_circle : Icons.trending_down,
                size: 18,
                color: fatDiff < 0.2 ? const Color(0xFF00E676) : (isDark ? const Color(0xFF60A5FA) : Colors.blue[600]),
              ),
              const SizedBox(width: 4),
              Text(
                fatDiff < 0.2 ? 'Đang ở tỷ lệ % mỡ chuẩn gymer' : '${fatDiff.toStringAsFixed(1)}% đến mục tiêu',
                style: TextStyle(
                  fontSize: 14,
                  color: fatDiff < 0.2 ? const Color(0xFF00E676) : (isDark ? const Color(0xFF60A5FA) : Colors.blue[600]),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _FatChartPainter(
                labels: _fatLabels,
                values: _fatValues,
                isDark: isDark,
                primaryAccent: primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCompositionRow(bool isDark) {
    return Row(
      children: [
        // Lean mass card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151B18) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_leanMass.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khối lượng nạc',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Fat mass card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151B18) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fatMass.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khối lượng mỡ',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNhanXetCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhận xét tiến độ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mục tiêu: $_fitnessGoal. Cân nặng hiện tại ${_weight.toStringAsFixed(1)}kg, tỷ lệ mỡ ${_bodyFat.toStringAsFixed(1)}%, khối lượng cơ nạc ${_leanMass.toStringAsFixed(1)}kg. Đang vận hành đúng tiến độ giáo án thể hình.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 3: Số đo
  // ═══════════════════════════════════════════════════

  List<Widget> _buildMeasurementsTabContent(bool isDark, Color primaryAccent) {
    return [
      _buildMeasurementsCard(isDark),
      const SizedBox(height: 16),
      _buildLastMeasurementDate(isDark),
      const SizedBox(height: 16),
      SmartwatchHealthCard(model: BadgesAndReportModel.instance),
      const SizedBox(height: 20),
      _buildBadgesSection(isDark, primaryAccent),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildMeasurementsCard(bool isDark) {
    final measurementsList = _measurements.entries.map((e) {
      return _MeasurementData(e.key, e.value, e.value, 0);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số đo cơ thể (cm)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...measurementsList.map((m) => _buildMeasurementRow(m, isDark)),
        ],
      ),
    );
  }

  Widget _buildLastMeasurementDate(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lần ghi nhận gần nhất',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thời gian: $_lastMeasuredDate · Cập nhật từ đồng hồ & số đo tay',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(_MeasurementData data, bool isDark) {
    // Determine change badge color and icon
    Color badgeColor;
    IconData? badgeIcon;

    if (data.change < 0) {
      badgeColor = isDark ? const Color(0xFF60A5FA) : Colors.blue[600]!;
      badgeIcon = Icons.arrow_downward;
    } else if (data.change > 0) {
      badgeColor = isDark ? const Color(0xFFF87171) : Colors.red[500]!;
      badgeIcon = Icons.arrow_upward;
    } else {
      badgeColor = isDark ? const Color(0xFF94A3B8) : AppColors.outline;
      badgeIcon = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Left: label + previous value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Lần trước: ${data.previousValue} cm',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                  ),
                ),
              ],
            ),
          ),

          // Right: current value + change badge
          Row(
            children: [
              Text(
                '${data.currentValue}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              // Change badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeIcon != null) ...[
                      Icon(badgeIcon, size: 12, color: badgeColor),
                    ],
                    Text(
                      data.change == 0 ? '—0' : '${data.change.abs()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Shared: Badges Section
  // ═══════════════════════════════════════════════════

  Widget _buildBadgesSection(bool isDark, Color primaryAccent) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Huy hiệu Gymer Chef',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Badge icons row
          Row(
            children: [
              _buildBadge(Icons.emoji_events, true, isDark, primaryAccent),
              const SizedBox(width: 12),
              _buildBadge(Icons.workspace_premium, true, isDark, primaryAccent),
              const SizedBox(width: 12),
              _buildBadge(Icons.military_tech, false, isDark, primaryAccent),
              const SizedBox(width: 12),
              _buildBadge(Icons.star, false, isDark, primaryAccent),
            ],
          ),
          const SizedBox(height: 16),

          // Unlock text
          Text(
            'Còn 18 ngày nữa để mở khóa huy hiệu Vàng (30 ngày)',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, bool earned, bool isDark, Color primaryAccent) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: earned
            ? (isDark ? primaryAccent : AppColors.primary)
            : (isDark ? const Color(0xFF26322C) : AppColors.surfaceContainerHigh),
        shape: BoxShape.circle,
        border: earned
            ? null
            : Border.all(
                color: isDark ? Colors.white12 : AppColors.outlineVariant,
                width: 1.5,
              ),
      ),
      child: Icon(
        icon,
        size: 24,
        color: earned
            ? (isDark ? Colors.black : AppColors.surface)
            : (isDark ? const Color(0xFF64748B) : AppColors.outlineVariant),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Goal Roadmap & Modal Setting
  // ═══════════════════════════════════════════════════

  Widget _buildGoalRoadmapCard(bool isDark, Color primaryAccent) {
    final diff = (_weight - _targetWeight).abs();

    double progress = 0.0;
    if (_initialWeight != _targetWeight) {
      final totalChange = (_initialWeight - _targetWeight).abs();
      final currentChange = (_initialWeight - _weight).abs();
      progress = (currentChange / totalChange).clamp(0.0, 1.0);
    } else {
      progress = diff < 0.2 ? 1.0 : 0.8;
    }
    final progressPercent = (progress * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? primaryAccent : AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flag_rounded, color: isDark ? primaryAccent : AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kế hoạch: $_fitnessGoal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hạn định $_goalTimelineDays ngày · ${_targetWeight.toStringAsFixed(1)} kg (${_targetFat.toStringAsFixed(1)}% mỡ)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showEditGoalModal,
                icon: Icon(Icons.tune_rounded, size: 16, color: isDark ? primaryAccent : AppColors.primary),
                label: Text(
                  'Đổi mục tiêu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? primaryAccent : AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: (isDark ? primaryAccent : AppColors.primary).withValues(alpha: isDark ? 0.15 : 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF26322C) : AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(isDark ? primaryAccent : AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bắt đầu: ${_initialWeight.toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
              ),
              Text(
                'Tiến độ: $progressPercent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? primaryAccent : AppColors.primary,
                ),
              ),
              Text(
                'Đích: ${_targetWeight.toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditGoalModal() {
    double tempTargetWeight = _targetWeight;
    double tempTargetFat = _targetFat;
    String tempGoal = _fitnessGoal;
    int tempDays = _goalTimelineDays;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191C1B) : AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: isDark ? Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))) : null,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mục tiêu vóc dáng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: isDark ? Colors.white : AppColors.outline),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tùy chỉnh định hướng tập luyện và mục tiêu cân nặng theo ý bạn.',
                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),

                    // Goal selector
                    Text(
                      'Định hướng thể hình',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildGoalOptionChip(
                          title: 'Giảm mỡ',
                          icon: '📉',
                          isSelected: tempGoal == 'Giảm mỡ',
                          isDark: isDark,
                          primaryAccent: primaryAccent,
                          onTap: () {
                            setModalState(() {
                              tempGoal = 'Giảm mỡ';
                              if (tempTargetWeight >= _weight) {
                                tempTargetWeight = double.parse((_weight - 3.0).toStringAsFixed(1));
                              }
                              tempTargetFat = 14.0;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildGoalOptionChip(
                          title: 'Tăng cơ',
                          icon: '💪',
                          isSelected: tempGoal == 'Tăng cơ',
                          isDark: isDark,
                          primaryAccent: primaryAccent,
                          onTap: () {
                            setModalState(() {
                              tempGoal = 'Tăng cơ';
                              if (tempTargetWeight <= _weight) {
                                tempTargetWeight = double.parse((_weight + 3.0).toStringAsFixed(1));
                              }
                              tempTargetFat = 16.0;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildGoalOptionChip(
                          title: 'Duy trì',
                          icon: '⚖️',
                          isSelected: tempGoal == 'Duy trì vóc dáng' || tempGoal == 'Duy trì',
                          isDark: isDark,
                          primaryAccent: primaryAccent,
                          onTap: () {
                            setModalState(() {
                              tempGoal = 'Duy trì vóc dáng';
                              tempTargetWeight = _weight;
                              tempTargetFat = _bodyFat;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Target weight adjustment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cân nặng mục tiêu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Hiện tại: ${_weight.toStringAsFixed(1)} kg',
                          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                tempTargetWeight = double.parse((tempTargetWeight - 0.5).clamp(35.0, 200.0).toStringAsFixed(1));
                              });
                            },
                            icon: Icon(Icons.remove_circle_outline, size: 28, color: isDark ? primaryAccent : AppColors.primary),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                tempTargetWeight.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'kg',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                tempTargetWeight = double.parse((tempTargetWeight + 0.5).clamp(35.0, 200.0).toStringAsFixed(1));
                              });
                            },
                            icon: Icon(Icons.add_circle_outline, size: 28, color: isDark ? primaryAccent : AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Target body fat adjustment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tỷ lệ mỡ mục tiêu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Hiện tại: ${_bodyFat.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                tempTargetFat = double.parse((tempTargetFat - 0.5).clamp(5.0, 50.0).toStringAsFixed(1));
                              });
                            },
                            icon: Icon(Icons.remove_circle_outline, size: 28, color: isDark ? primaryAccent : AppColors.primary),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                tempTargetFat.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                tempTargetFat = double.parse((tempTargetFat + 0.5).clamp(5.0, 50.0).toStringAsFixed(1));
                              });
                            },
                            icon: Icon(Icons.add_circle_outline, size: 28, color: isDark ? primaryAccent : AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Timeline selection
                    Text(
                      'Thời gian hoàn thành mục tiêu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [30, 60, 90].map((days) {
                        final isSel = tempDays == days;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() => tempDays = days);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (isDark ? primaryAccent : AppColors.primary)
                                    : (isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerHigh),
                                borderRadius: BorderRadius.circular(12),
                                border: isDark && !isSel
                                    ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$days ngày',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? (isDark ? Colors.black : AppColors.onPrimary)
                                      : (isDark ? Colors.white : AppColors.onSurface),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setDouble('target_weight_kg', tempTargetWeight);
                          await prefs.setDouble('target_fat_percent', tempTargetFat);
                          await prefs.setString('fitness_goal', tempGoal);
                          await prefs.setInt('goal_timeline_days', tempDays);

                          final profile = await ApiService.getLocalProfile();
                          if (profile != null) {
                            profile['targetWeightKg'] = tempTargetWeight;
                            profile['fitnessGoal'] = tempGoal == 'Tăng cơ'
                                ? 'bulking'
                                : (tempGoal == 'Giảm mỡ' ? 'cutting' : 'maintenance');
                            await ApiService.saveLocalProfile(profile);
                          }

                          setState(() {
                            _targetWeight = tempTargetWeight;
                            _targetFat = tempTargetFat;
                            _fitnessGoal = tempGoal;
                            _goalTimelineDays = tempDays;
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật mục tiêu vóc dáng thành công! 🎯'),
                                backgroundColor: Color(0xFF00E676),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? primaryAccent : AppColors.primary,
                          foregroundColor: isDark ? Colors.black : AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Lưu mục tiêu mới',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalOptionChip({
    required String title,
    required String icon,
    required bool isSelected,
    required bool isDark,
    required Color primaryAccent,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? primaryAccent : AppColors.primary)
                : (isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? primaryAccent : AppColors.primary)
                  : (isDark ? Colors.white12 : AppColors.outlineVariant),
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.black : AppColors.onPrimary)
                      : (isDark ? Colors.white : AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Bottom Button
  // ═══════════════════════════════════════════════════

  Widget _buildBottomButton(bool isDark, Color primaryAccent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0E0D) : AppColors.surfaceContainerLow,
        border: isDark ? Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))) : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UpdateBodyStatsScreen(),
              ),
            );
            if (res == true) {
              _loadData();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? primaryAccent : AppColors.primary,
            foregroundColor: isDark ? Colors.black : AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            '+ Cập nhật cân nặng / số đo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Data Model
// ══════════════════════════════════════════════════════

class _MeasurementData {
  final String name;
  final int currentValue;
  final int previousValue;
  final int change;

  _MeasurementData(this.name, this.currentValue, this.previousValue, this.change);
}

// ══════════════════════════════════════════════════════
// Weight Chart Painter
// ══════════════════════════════════════════════════════

class _WeightChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final bool isDark;
  final Color primaryAccent;

  const _WeightChartPainter({
    required this.labels,
    required this.values,
    this.isDark = false,
    this.primaryAccent = AppColors.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    double minV = values.reduce((a, b) => a < b ? a : b) - 1.0;
    double maxV = values.reduce((a, b) => a > b ? a : b) + 1.0;
    if (minV >= maxV) { minV -= 1; maxV += 1; }
    _drawChart(canvas, size, labels, values, minV, maxV, isDark, primaryAccent);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.labels != labels ||
      oldDelegate.isDark != isDark ||
      oldDelegate.primaryAccent != primaryAccent;
}

class _FatChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final bool isDark;
  final Color primaryAccent;

  const _FatChartPainter({
    required this.labels,
    required this.values,
    this.isDark = false,
    this.primaryAccent = AppColors.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    double minV = values.reduce((a, b) => a < b ? a : b) - 1.0;
    double maxV = values.reduce((a, b) => a > b ? a : b) + 1.0;
    if (minV >= maxV) { minV -= 1; maxV += 1; }
    _drawChart(canvas, size, labels, values, minV, maxV, isDark, primaryAccent);
  }

  @override
  bool shouldRepaint(covariant _FatChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.labels != labels ||
      oldDelegate.isDark != isDark ||
      oldDelegate.primaryAccent != primaryAccent;
}

// ══════════════════════════════════════════════════════
// Shared Chart Drawing
// ══════════════════════════════════════════════════════

void _drawChart(
  Canvas canvas,
  Size size,
  List<String> labels,
  List<double> values,
  double minVal,
  double maxVal, [
  bool isDark = false,
  Color primaryAccent = AppColors.primary,
]) {
  const double chartLeft = 0;
  final double chartRight = size.width;
  const double chartTop = 0;
  final double chartBottom = size.height - 28;
  final double valRange = maxVal - minVal;

  // Grid lines
  final gridPaint = Paint()
    ..color = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.surfaceContainerHigh
    ..strokeWidth = 1;

  for (int i = 0; i < 4; i++) {
    final y = chartTop + (chartBottom - chartTop) * i / 3;
    canvas.drawLine(
      Offset(chartLeft, y),
      Offset(chartRight, y),
      gridPaint,
    );
  }

  // Calculate points
  final points = <Offset>[];
  for (int i = 0; i < values.length; i++) {
    final x = chartLeft + (chartRight - chartLeft) * i / (values.length - 1);
    final y = chartBottom -
        ((values[i] - minVal) / valRange) * (chartBottom - chartTop);
    points.add(Offset(x, y));
  }

  // Draw line
  final linePaint = Paint()
    ..color = primaryAccent
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final path = Path();
  path.moveTo(points[0].dx, points[0].dy);

  for (int i = 0; i < points.length - 1; i++) {
    final current = points[i];
    final next = points[i + 1];
    final controlX1 = current.dx + (next.dx - current.dx) * 0.4;
    final controlX2 = current.dx + (next.dx - current.dx) * 0.6;
    path.cubicTo(
      controlX1, current.dy,
      controlX2, next.dy,
      next.dx, next.dy,
    );
  }

  canvas.drawPath(path, linePaint);

  // Draw gradient fill below the line
  final fillPath = Path.from(path);
  fillPath.lineTo(points.last.dx, chartBottom);
  fillPath.lineTo(points.first.dx, chartBottom);
  fillPath.close();

  final fillPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryAccent.withValues(alpha: isDark ? 0.25 : 0.15),
        primaryAccent.withValues(alpha: 0.01),
      ],
    ).createShader(Rect.fromLTRB(0, chartTop, size.width, chartBottom));

  canvas.drawPath(fillPath, fillPaint);

  // Draw dots
  final dotPaint = Paint()
    ..color = primaryAccent
    ..style = PaintingStyle.fill;

  final dotBorderPaint = Paint()
    ..color = isDark ? const Color(0xFF151B18) : AppColors.surface
    ..style = PaintingStyle.fill;

  for (int i = 0; i < points.length; i++) {
    if (i == points.length - 1) {
      canvas.drawCircle(points[i], 7, dotBorderPaint);
      canvas.drawCircle(points[i], 5, dotPaint);
    } else {
      canvas.drawCircle(points[i], 3.5, dotPaint);
    }
  }

  // Draw X-axis labels
  final textStyle = TextStyle(
    color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  for (int i = 0; i < labels.length; i++) {
    final textSpan = TextSpan(text: labels[i], style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final x = points[i].dx - textPainter.width / 2;
    final y = chartBottom + 8;
    textPainter.paint(canvas, Offset(x, y));
  }
}

