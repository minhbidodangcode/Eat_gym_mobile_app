import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Tên miền cố định vĩnh viễn (Ngrok Static Domain) - Đổi PC sang Mac không cần sửa IP
  static const String baseUrl = 'https://kindly-absolve-concur.ngrok-free.dev/api';

  static bool isTokenExpired(String? token) {
    if (token == null || token.isEmpty || token == 'dummy_token') return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(decoded);
      if (data.containsKey('exp')) {
        final exp = (data['exp'] as num).toInt();
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return now >= exp;
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null || isTokenExpired(token)) {
      try {
        final data = await login('demo@eatgym.com', '12345678');
        token = data['accessToken']?.toString();
      } catch (_) {}
    }
    return token;
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['accessToken']);
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty || token == 'dummy_token') return false;
    if (isTokenExpired(token)) {
      try {
        final res = await login('demo@eatgym.com', '12345678');
        return res.containsKey('accessToken');
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
  }

  // ---------------------------------------------------------
  // HỒ SƠ KHỞI TẠO (ONBOARDING PROFILE)
  // ---------------------------------------------------------

  /// Trả về `null` khi tài khoản chưa tạo hồ sơ lần đầu.
  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body)['profile']);
    }
    if (response.statusCode == 404) return null;
    throw Exception('Không thể tải hồ sơ: ${response.body}');
  }

  static Future<Map<String, dynamic>> saveProfile({
    required String sex,
    required String dateOfBirth,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String fitnessGoal,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(token),
      body: json.encode({
        'sex': sex,
        'dateOfBirth': dateOfBirth,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel,
        'fitnessGoal': fitnessGoal,
      }),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    throw Exception('Không thể lưu hồ sơ: ${response.body}');
  }

  static Future<void> saveOnboardingPreferences({
    required Iterable<String> allergies,
    required Iterable<String> preferences,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('food_allergies', allergies.toList());
    await prefs.setStringList('food_preferences', preferences.toList());
  }

  static Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: json.encode({'fullName': fullName, 'email': email, 'password': password}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['accessToken']);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // ---------------------------------------------------------
  // KHO NGUYÊN LIỆU (INVENTORY)
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>> getInventory({String? category, String? query, String? sort}) async {
    final token = await _getToken();
    
    var url = Uri.parse('$baseUrl/inventory');
    var queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (query != null) queryParams['q'] = query;
    if (sort != null) queryParams['sort'] = sort;
    
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load inventory: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addInventoryBatch(List<Map<String, dynamic>> items) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/inventory');
    
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({'items': items}),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add inventory batch: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> consumeInventoryItem(String id, double amount, bool deleteIfDepleted) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/inventory/$id/consume');
    
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({
        'amount': amount,
        'deleteIfDepleted': deleteIfDepleted,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to consume inventory: ${response.body}');
    }
  }

  // ---------------------------------------------------------
  // NHẬT KÝ (NUTRITION LOGS)
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>> getNutritionSummary({String? from, String? to}) async {
    final token = await _getToken();
    var url = Uri.parse('$baseUrl/nutrition-logs/summary');
    var queryParams = <String, String>{};
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;
    
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load nutrition summary: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getNutritionLogs(String date) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/nutrition-logs?date=$date');
    
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load nutrition logs: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addNutritionLog(Map<String, dynamic> logData) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/nutrition-logs');
    
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode(logData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add nutrition log: ${response.body}');
    }
  }

  // ---------------------------------------------------------
  // MÓN ĂN & NGUYÊN LIỆU (RECIPES & INGREDIENTS)
  // ---------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getIngredients({String? category, String? query}) async {
    final token = await _getToken();
    var url = Uri.parse('$baseUrl/ingredients');
    var queryParams = <String, String>{};
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (queryParams.isNotEmpty) url = url.replace(queryParameters: queryParams);

    try {
      final response = await http.get(url, headers: _headers(token));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['ingredients'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> getRecipes({String? search, String? tag}) async {
    final token = await _getToken();
    var url = Uri.parse('$baseUrl/recipes');
    var queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['q'] = search;
    if (tag != null && tag.isNotEmpty && tag != 'Tất cả') queryParams['tag'] = tag;
    if (queryParams.isNotEmpty) url = url.replace(queryParameters: queryParams);

    try {
      final response = await http.get(url, headers: _headers(token));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> suggestRecipes(List<String> ingredients, {int? maxTime}) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/recipes/suggest');
    try {
      final response = await http.post(
        url,
        headers: _headers(token),
        body: json.encode({
          'ingredients': ingredients,
          if (maxTime != null) 'maxTime': maxTime,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  // ---------------------------------------------------------
  // GAMIFICATION & STREAK (ACHIEVEMENTS)
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>> getStreak() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/achievements/streak');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get streak: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getBadges() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/achievements/badges');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['badges'] ?? []);
    } else {
      throw Exception('Failed to get badges: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> recordCookingDay({
    required String cookedOn,
    String? note,
    String? mealPrepBatchId,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/achievements/cooking-days');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({
        'cookedOn': cookedOn,
        if (note != null) 'note': note,
        if (mealPrepBatchId != null) 'mealPrepBatchId': mealPrepBatchId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to record cooking day (${response.statusCode}): ${response.body}');
    }
  }

  // ---------------------------------------------------------
  // DAILY HEALTH & SMARTWATCH METRICS
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>> saveDailyHealthMetrics({
    String? logDate,
    required int steps,
    required double caloriesBurned,
    int? heartRateAvg,
    int? activeMinutes,
    String source = 'Nothing X',
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/health/daily');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({
        if (logDate != null) 'logDate': logDate,
        'steps': steps,
        'caloriesBurned': caloriesBurned,
        if (heartRateAvg != null) 'heartRateAvg': heartRateAvg,
        if (activeMinutes != null) 'activeMinutes': activeMinutes,
        'source': source,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Lỗi lưu chỉ số sức khỏe: ${response.body}');
    }
  }

  static Future<List<dynamic>> getDailyHealthMetrics({
    String? startDate,
    String? endDate,
    int limit = 30,
  }) async {
    final token = await _getToken();
    String query = '?limit=$limit';
    if (startDate != null) query += '&startDate=$startDate';
    if (endDate != null) query += '&endDate=$endDate';

    final url = Uri.parse('$baseUrl/health/daily$query');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['metrics'] as List<dynamic>? ?? [];
    } else {
      throw Exception('Lỗi tải lịch sử sức khỏe: ${response.body}');
    }
  }
}

