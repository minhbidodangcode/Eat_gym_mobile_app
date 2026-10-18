import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Dịch vụ kết nối trực tiếp với Google Health Connect & Apple Health:
/// - Tự động đọc số bước, calo tiêu hao, nhịp tim từ thiết bị đeo (Nothing X, Garmin, Samsung...)
/// - Cung cấp cơ chế cài đặt Health Connect tự động nếu máy chưa có
/// - Lưu trữ cục bộ SharedPreferences và đồng bộ lên Postgres Database theo chu kỳ ngày (0h - 24h).
class HealthService {
  static final HealthService instance = HealthService._internal();
  factory HealthService() => instance;
  HealthService._internal();

  final Health _health = Health();

  bool _isConfigured = false;
  bool _isAuthorized = false;
  bool get isAuthorized => _isAuthorized;

  bool _isHealthConnectInstalled = true;
  bool get isHealthConnectInstalled => _isHealthConnectInstalled;

  // Khởi tạo mặc định: 0 bước, 0 kcal, 0 bpm khi bắt đầu ngày mới hoặc chưa có dữ liệu
  int _todaySteps = 0;
  int get todaySteps => _todaySteps;

  int _todayCaloriesBurned = 0;
  int get todayCaloriesBurned => _todayCaloriesBurned;

  int _todayHeartRate = 0;
  int get todayHeartRate => _todayHeartRate;

  String _currentSource = 'Nothing X';
  String get currentSource => _currentSource;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  static final List<HealthDataType> _healthTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.HEART_RATE,
  ];

  String get healthSourceLabel {
    if (kIsWeb) return 'Web Health Hub';
    if (_currentSource.isNotEmpty && _currentSource != 'Smartwatch') {
      return '$_currentSource (Smartwatch)';
    }
    if (Platform.isAndroid) {
      return 'Google Health Connect (Garmin, Samsung, Xiaomi...)';
    } else if (Platform.isIOS) {
      return 'Apple Health / HealthKit (Apple Watch, Garmin...)';
    }
    return 'Smartwatch Health Hub';
  }

  /// Trả về chuỗi ngày theo định dạng YYYY-MM-DD
  static String getTodayDateString([DateTime? date]) {
    final d = date ?? DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Khởi tạo cấu hình và tải dữ liệu đã lưu gần nhất
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthorized = prefs.getBool('health_authorized') ?? false;
      _currentSource = prefs.getString('health_source') ?? 'Nothing X';

      final syncStr = prefs.getString('health_last_sync');
      DateTime? parsedSyncTime;
      if (syncStr != null) {
        parsedSyncTime = DateTime.tryParse(syncStr);
        _lastSyncTime = parsedSyncTime;
      }

      final todayStr = getTodayDateString(DateTime.now());
      final lastSyncDateStr = parsedSyncTime != null ? getTodayDateString(parsedSyncTime) : null;

      if (lastSyncDateStr != null && lastSyncDateStr == todayStr) {
        // Cùng ngày: Khôi phục dữ liệu đã lưu trong ngày hôm nay
        _todaySteps = prefs.getInt('health_today_steps') ?? 0;
        _todayCaloriesBurned = prefs.getInt('health_today_calories') ?? 0;
        _todayHeartRate = prefs.getInt('health_today_heart_rate') ?? 0;
      } else {
        // Sang ngày mới (hoặc chưa từng đồng bộ): Reset toàn bộ về 0 để đếm lại từ đầu ngày
        _todaySteps = 0;
        _todayCaloriesBurned = 0;
        _todayHeartRate = 0;
        await prefs.setInt('health_today_steps', 0);
        await prefs.setInt('health_today_calories', 0);
        await prefs.setInt('health_today_heart_rate', 0);
      }

      await _configurePlugin();
    } catch (_) {}
  }

  Future<void> _configurePlugin() async {
    if (_isConfigured) return;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await _health.configure();
        _isConfigured = true;

        if (Platform.isAndroid) {
          final status = await _health.getHealthConnectSdkStatus();
          _isHealthConnectInstalled = (status == HealthConnectSdkStatus.sdkAvailable);
        }
      } catch (e) {
        debugPrint('Health configure error: $e');
      }
    }
  }

  /// Mở Google Play Store để cài đặt Health Connect nếu máy chưa có
  Future<void> installHealthConnect() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _health.installHealthConnect();
      }
    } catch (e) {
      debugPrint('Install Health Connect error: $e');
    }
  }

  /// Yêu cầu cấp quyền truy cập Health Connect / Apple Health
  Future<bool> requestAuthorization() async {
    try {
      await _configurePlugin();

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (Platform.isAndroid) {
          final status = await _health.getHealthConnectSdkStatus();
          if (status != HealthConnectSdkStatus.sdkAvailable) {
            _isHealthConnectInstalled = false;
            return false;
          }
          _isHealthConnectInstalled = true;
        }

        final bool? hasPerms = await _health.hasPermissions(_healthTypes);
        if (hasPerms == true) {
          _isAuthorized = true;
        } else {
          _isAuthorized = await _health.requestAuthorization(_healthTypes);
        }
      } else {
        _isAuthorized = true;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('health_authorized', _isAuthorized);
      return _isAuthorized;
    } catch (e) {
      debugPrint('Lỗi xin quyền Health: $e');
      _isAuthorized = false;
      return false;
    }
  }

  /// Đồng bộ tự động 100% từ Google Health Connect / Apple Health vào Database
  Future<Map<String, dynamic>> fetchRealtimeHealthData({bool syncToBackend = true}) async {
    try {
      await _configurePlugin();

      // Kiểm tra tình trạng Health Connect trên Android
      if (!kIsWeb && Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          _isHealthConnectInstalled = false;
          // Thông báo cho người dùng biết cần cài đặt Health Connect
          return {
            'success': false,
            'healthConnectNeeded': true,
            'message': 'Điện thoại chưa cài ứng dụng Google Health Connect.',
            'steps': _todaySteps,
            'caloriesBurned': _todayCaloriesBurned,
            'heartRate': _todayHeartRate,
          };
        }
        _isHealthConnectInstalled = true;
      }

      // Xin cấp quyền nếu chưa có
      if (!_isAuthorized) {
        final granted = await requestAuthorization();
        if (!granted) {
          return {
            'success': false,
            'permissionDenied': true,
            'message': 'Chưa được cấp quyền truy cập Health Connect.',
            'steps': _todaySteps,
            'caloriesBurned': _todayCaloriesBurned,
            'heartRate': _todayHeartRate,
          };
        }
      }

      // Đọc chỉ số thực tế từ 00:00 hôm nay đến hiện tại
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final todayStr = getTodayDateString(now);
      final lastSyncDateStr = _lastSyncTime != null ? getTodayDateString(_lastSyncTime) : null;

      // Nếu chuyển sang ngày mới so với lần đồng bộ trước, chủ động reset về 0
      if (lastSyncDateStr != todayStr) {
        _todaySteps = 0;
        _todayCaloriesBurned = 0;
        _todayHeartRate = 0;
      }

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          // 1. Đọc tổng số bước chân hôm nay (từ 00:00 đến hiện tại)
          final int? stepsFromConnect = await _health.getTotalStepsInInterval(midnight, now);
          if (stepsFromConnect != null) {
            // Cập nhật số bước thực tế (kể cả 0 bước khi mới bắt đầu ngày)
            _todaySteps = stepsFromConnect;
          }

          // 2. Đọc calo và nhịp tim từ các điểm dữ liệu Health Connect
          final dataPoints = await _health.getHealthDataFromTypes(
            types: _healthTypes,
            startTime: midnight,
            endTime: now,
          );

          double activeCal = 0;
          double totalCal = 0;
          int latestHr = 0;
          DateTime? latestHrTime;

          for (final point in dataPoints) {
            final val = point.value;
            if (val is NumericHealthValue) {
              if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
                activeCal += val.numericValue;
              } else if (point.type == HealthDataType.TOTAL_CALORIES_BURNED) {
                totalCal += val.numericValue;
              } else if (point.type == HealthDataType.HEART_RATE) {
                if (latestHrTime == null || point.dateTo.isAfter(latestHrTime)) {
                  latestHr = val.numericValue.round();
                  latestHrTime = point.dateTo;
                }
              }
            }
          }

          final effectiveCal = (activeCal > 0) ? activeCal : totalCal;
          // Cập nhật calo hôm nay: nếu có calo hoặc là ngày mới / có dữ liệu đọc về thì cập nhật
          if (effectiveCal > 0 || lastSyncDateStr != todayStr || dataPoints.isNotEmpty) {
            _todayCaloriesBurned = effectiveCal.round();
          }
          if (latestHr > 0) {
            _todayHeartRate = latestHr;
          }

          _currentSource = 'Google Health Connect (Nothing X)';
        } catch (e) {
          debugPrint('Lỗi đọc Health Connect data: $e');
        }
      }

      final syncNow = DateTime.now();
      _lastSyncTime = syncNow;

      // Lưu trữ cục bộ
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('health_today_steps', _todaySteps);
      await prefs.setInt('health_today_calories', _todayCaloriesBurned);
      await prefs.setInt('health_today_heart_rate', _todayHeartRate);
      await prefs.setString('health_last_sync', syncNow.toIso8601String());
      await prefs.setString('health_source', _currentSource);

      await _saveLocalDailyRecord(
        date: getTodayDateString(syncNow),
        steps: _todaySteps,
        calories: _todayCaloriesBurned,
        heartRate: _todayHeartRate,
      );

      // Đẩy lên Postgres Database
      bool backendSaved = false;
      if (syncToBackend) {
        try {
          await ApiService.saveDailyHealthMetrics(
            logDate: getTodayDateString(_lastSyncTime),
            steps: _todaySteps,
            caloriesBurned: _todayCaloriesBurned.toDouble(),
            heartRateAvg: _todayHeartRate,
            source: _currentSource,
          );
          backendSaved = true;
        } catch (e) {
          debugPrint('Backend sync error (offline fallback used): $e');
        }
      }

      return {
        'success': true,
        'source': healthSourceLabel,
        'steps': _todaySteps,
        'caloriesBurned': _todayCaloriesBurned,
        'heartRate': _todayHeartRate,
        'syncTime': _lastSyncTime,
        'backendSaved': backendSaved,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'steps': _todaySteps,
        'caloriesBurned': _todayCaloriesBurned,
        'heartRate': _todayHeartRate,
      };
    }
  }

  /// Cập nhật thủ công hoặc từ sự kiện đồng bộ ngoài
  Future<void> updateCustomHealthMetrics({
    required int steps,
    required int caloriesBurned,
    int? heartRate,
    String? source,
    String? logDate,
    bool syncBackend = true,
  }) async {
    _todaySteps = steps;
    _todayCaloriesBurned = caloriesBurned;
    if (heartRate != null) {
      _todayHeartRate = heartRate;
    }
    if (source != null) {
      _currentSource = source;
    }
    final syncNow = DateTime.now();
    _lastSyncTime = syncNow;
    _isAuthorized = true;

    final targetDate = logDate ?? getTodayDateString(syncNow);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_authorized', true);
    await prefs.setInt('health_today_steps', _todaySteps);
    await prefs.setInt('health_today_calories', _todayCaloriesBurned);
    await prefs.setInt('health_today_heart_rate', _todayHeartRate);
    await prefs.setString('health_last_sync', syncNow.toIso8601String());
    await prefs.setString('health_source', _currentSource);

    await _saveLocalDailyRecord(
      date: targetDate,
      steps: _todaySteps,
      calories: _todayCaloriesBurned,
      heartRate: _todayHeartRate,
    );

    if (syncBackend) {
      try {
        await ApiService.saveDailyHealthMetrics(
          logDate: targetDate,
          steps: _todaySteps,
          caloriesBurned: _todayCaloriesBurned.toDouble(),
          heartRateAvg: _todayHeartRate,
          source: _currentSource,
        );
      } catch (e) {
        debugPrint('Lỗi lưu Database Backend: $e');
      }
    }
  }

  Future<void> _saveLocalDailyRecord({
    required String date,
    required int steps,
    required int calories,
    required int heartRate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('health_daily_history') ?? '{}';
      final Map<String, dynamic> history = json.decode(historyStr);

      history[date] = {
        'date': date,
        'steps': steps,
        'calories': calories,
        'heartRate': heartRate,
        'updatedAt': DateTime.now().toIso8601String(),
        'source': _currentSource,
      };

      await prefs.setString('health_daily_history', json.encode(history));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getLocalDailyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('health_daily_history') ?? '{}';
      return json.decode(historyStr);
    } catch (_) {
      return {};
    }
  }
}
