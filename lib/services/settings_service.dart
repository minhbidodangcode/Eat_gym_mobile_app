import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  // ValueNotifiers for reactive UI updates
  static const String defaultAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';
  final ValueNotifier<String> userAvatarNotifier = ValueNotifier<String>(defaultAvatar);
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
  final ValueNotifier<String> accentColorNotifier = ValueNotifier<String>('neon_green');
  final ValueNotifier<double> fontScaleNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<bool> highContrastNotifier = ValueNotifier<bool>(false);

  final ValueNotifier<String> unitSystemNotifier = ValueNotifier<String>('metric'); // metric / imperial
  final ValueNotifier<String> unitWeightNotifier = ValueNotifier<String>('kg');
  final ValueNotifier<String> unitHeightNotifier = ValueNotifier<String>('cm');

  final ValueNotifier<bool> remindersEnabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> waterTimeNotifier = ValueNotifier<String>('08:30');
  final ValueNotifier<String> mealTimeNotifier = ValueNotifier<String>('12:30');
  final ValueNotifier<String> workoutTimeNotifier = ValueNotifier<String>('17:30');

  // Exact Keys specified by user
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyUnitSystem = 'unit_system';
  static const String _keyRemindersEnabled = 'reminders_enabled';
  static const String _keyUserAvatar = 'user_avatar';

  // Additional detail keys
  static const String _keyAccentColor = 'settings_accent_color';
  static const String _keyFontScale = 'settings_font_scale';
  static const String _keyHighContrast = 'settings_high_contrast';
  static const String _keyUnitWeight = 'settings_unit_weight';
  static const String _keyUnitHeight = 'settings_unit_height';
  static const String _keyWaterTime = 'settings_water_time';
  static const String _keyMealTime = 'settings_meal_time';
  static const String _keyWorkoutTime = 'settings_workout_time';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme Mode: theme_mode (dark/light/system)
    final savedTheme = prefs.getString(_keyThemeMode) ?? prefs.getString('settings_theme_mode') ?? 'dark';
    if (savedTheme == 'light') {
      themeModeNotifier.value = ThemeMode.light;
    } else if (savedTheme == 'system') {
      themeModeNotifier.value = ThemeMode.system;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }

    // Accent Color
    accentColorNotifier.value = prefs.getString(_keyAccentColor) ?? 'neon_green';

    // Font Scale
    fontScaleNotifier.value = prefs.getDouble(_keyFontScale) ?? 1.0;

    // High Contrast
    highContrastNotifier.value = prefs.getBool(_keyHighContrast) ?? false;

    // Unit System: unit_system (metric/imperial)
    final savedUnitSystem = prefs.getString(_keyUnitSystem) ?? 'metric';
    unitSystemNotifier.value = savedUnitSystem;

    // Units
    if (savedUnitSystem == 'imperial') {
      unitWeightNotifier.value = prefs.getString(_keyUnitWeight) ?? 'lbs';
      unitHeightNotifier.value = prefs.getString(_keyUnitHeight) ?? 'ft_in';
    } else {
      unitWeightNotifier.value = prefs.getString(_keyUnitWeight) ?? 'kg';
      unitHeightNotifier.value = prefs.getString(_keyUnitHeight) ?? 'cm';
    }

    // Reminders: reminders_enabled
    remindersEnabledNotifier.value = prefs.getBool(_keyRemindersEnabled) ?? prefs.getBool('settings_reminders_enabled') ?? true;
    waterTimeNotifier.value = prefs.getString(_keyWaterTime) ?? '08:30';
    mealTimeNotifier.value = prefs.getString(_keyMealTime) ?? '12:30';
    workoutTimeNotifier.value = prefs.getString(_keyWorkoutTime) ?? '17:30';
    userAvatarNotifier.value = prefs.getString(_keyUserAvatar) ?? defaultAvatar;
  }

  Future<void> setUserAvatar(String avatarPathOrUrl) async {
    userAvatarNotifier.value = avatarPathOrUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserAvatar, avatarPathOrUrl);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    String val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.system) val = 'system';
    await prefs.setString(_keyThemeMode, val);
    await prefs.setString('settings_theme_mode', val);
  }

  Future<void> setAccentColor(String colorKey) async {
    accentColorNotifier.value = colorKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccentColor, colorKey);
  }

  Future<void> setFontScale(double scale) async {
    fontScaleNotifier.value = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, scale);
  }

  Future<void> setHighContrast(bool value) async {
    highContrastNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrast, value);
  }

  Future<void> setUnitSystem(String system) async {
    unitSystemNotifier.value = system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUnitSystem, system);
    if (system == 'imperial') {
      await setUnitWeight('lbs');
      await setUnitHeight('ft_in');
    } else {
      await setUnitWeight('kg');
      await setUnitHeight('cm');
    }
  }

  Future<void> setUnitWeight(String unit) async {
    unitWeightNotifier.value = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUnitWeight, unit);
    // sync unit_system
    if (unit == 'lbs' && unitHeightNotifier.value == 'ft_in') {
      unitSystemNotifier.value = 'imperial';
      await prefs.setString(_keyUnitSystem, 'imperial');
    } else if (unit == 'kg' && unitHeightNotifier.value == 'cm') {
      unitSystemNotifier.value = 'metric';
      await prefs.setString(_keyUnitSystem, 'metric');
    }
  }

  Future<void> setUnitHeight(String unit) async {
    unitHeightNotifier.value = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUnitHeight, unit);
    // sync unit_system
    if (unit == 'ft_in' && unitWeightNotifier.value == 'lbs') {
      unitSystemNotifier.value = 'imperial';
      await prefs.setString(_keyUnitSystem, 'imperial');
    } else if (unit == 'cm' && unitWeightNotifier.value == 'kg') {
      unitSystemNotifier.value = 'metric';
      await prefs.setString(_keyUnitSystem, 'metric');
    }
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    remindersEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemindersEnabled, enabled);
    await prefs.setBool('settings_reminders_enabled', enabled);
  }

  Future<void> setReminderTime(String type, String timeStr) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == 'water') {
      waterTimeNotifier.value = timeStr;
      await prefs.setString(_keyWaterTime, timeStr);
    } else if (type == 'meal') {
      mealTimeNotifier.value = timeStr;
      await prefs.setString(_keyMealTime, timeStr);
    } else if (type == 'workout') {
      workoutTimeNotifier.value = timeStr;
      await prefs.setString(_keyWorkoutTime, timeStr);
    }
  }

  Color get currentColor {
    switch (accentColorNotifier.value) {
      case 'cyan_tech':
        return const Color(0xFF00E5FF);
      case 'fire_amber':
        return const Color(0xFFFFB300);
      case 'neon_green':
      default:
        return const Color(0xFF00E676);
    }
  }
}
