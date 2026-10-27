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
      return null;
    }
    return token;
  }

  static Future<Map<String, dynamic>?> getJwtPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty || token == 'dummy_token') return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return Map<String, dynamic>.from(json.decode(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getUserId() async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(decoded);
      return data['sub']?.toString() ?? data['userId']?.toString() ?? data['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_email');
    if (cached != null && cached.isNotEmpty) return cached;
    final payload = await getJwtPayload();
    if (payload != null && payload['email'] != null) {
      final email = payload['email'].toString();
      await prefs.setString('user_email', email);
      return email;
    }
    return null;
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
      await prefs.setString('user_email', email);
      if (data['user'] != null) {
        final user = data['user'];
        if (user['email'] != null) await prefs.setString('user_email', user['email'].toString());
        if (user['fullName'] != null) await prefs.setString('user_full_name', user['fullName'].toString());
        if (user['role'] != null) await prefs.setString('user_role', user['role'].toString());
        await prefs.setString('user_data', json.encode(user));
      }
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
      await logout();
      return false;
    }
    return true;
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _getToken();
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: _headers(token),
        ).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final user = Map<String, dynamic>.from(json.decode(response.body)['user']);
          await prefs.setString('user_data', json.encode(user));
          if (user['email'] != null) await prefs.setString('user_email', user['email'].toString());
          if (user['fullName'] != null) await prefs.setString('user_full_name', user['fullName'].toString());
          if (user['role'] != null) await prefs.setString('user_role', user['role'].toString());
          return user;
        }
      } catch (_) {}
    }

    // Fallback 1: cached user_data
    final cachedUserData = prefs.getString('user_data');
    if (cachedUserData != null && cachedUserData.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(json.decode(cachedUserData));
      } catch (_) {}
    }

    // Fallback 2: JWT payload (contains email, role, sub)
    final jwt = await getJwtPayload();
    if (jwt != null) {
      final email = jwt['email']?.toString() ?? prefs.getString('user_email');
      final role = jwt['role']?.toString() ?? prefs.getString('user_role') ?? 'ATHLETE';
      final fullName = prefs.getString('user_full_name');
      return {
        'id': jwt['sub']?.toString(),
        'email': email,
        'fullName': fullName ?? (email != null && email.contains('@') ? email.split('@')[0] : 'Vận động viên'),
        'role': role,
      };
    }

    // Fallback 3: user_email in prefs
    final savedEmail = prefs.getString('user_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      return {
        'email': savedEmail,
        'fullName': prefs.getString('user_full_name') ?? savedEmail.split('@')[0],
        'role': prefs.getString('user_role') ?? 'ATHLETE',
      };
    }

    return null;
  }

  static Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers(token),
      body: json.encode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error']?['message'] ?? data['message'] ?? 'Đổi mật khẩu thất bại.');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await getUserId();
    if (userId != null) {
      await prefs.remove('smart_fridge_items_$userId');
    }
    await prefs.remove('eatgym_smart_fridge_items_v4');
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
    await prefs.remove('user_email');
    await prefs.remove('user_full_name');
    await prefs.remove('user_role');
    await prefs.remove('user_data');
  }

  // ---------------------------------------------------------
  // HỒ SƠ KHỞI TẠO (ONBOARDING PROFILE)
  // ---------------------------------------------------------

  static Future<void> saveLocalProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(profile));
  }

  static Future<Map<String, dynamic>?> getLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_profile');
    if (cached != null && cached.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(json.decode(cached));
      } catch (_) {}
    }
    return null;
  }

  /// Trả về `null` khi tài khoản chưa tạo hồ sơ lần đầu.
  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final profile = Map<String, dynamic>.from(json.decode(response.body)['profile']);
        await saveLocalProfile(profile);
        return profile;
      }
      if (response.statusCode == 404) {
        return await getLocalProfile();
      }
    } catch (_) {
      return await getLocalProfile();
    }
    return await getLocalProfile();
  }

  static String parseApiError(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      if (decoded is Map) {
        String msg = '';
        if (decoded['error'] is Map && (decoded['error'] as Map).containsKey('message')) {
          msg = (decoded['error'] as Map)['message'].toString();
        } else if (decoded.containsKey('message')) {
          msg = decoded['message'].toString();
        }

        if (msg.isNotEmpty) {
          if (msg.contains('dateOfBirth must use YYYY-MM-DD format')) {
            return 'Ngày sinh phải đúng định dạng YYYY-MM-DD.';
          }
          if (msg.contains('between 13 and 120')) {
            return 'Độ tuổi người dùng phải từ 13 đến 120 tuổi.';
          }
          if (msg.contains('sex must be either')) {
            return 'Giới tính không hợp lệ.';
          }
          if (msg.contains('heightCm')) {
            return 'Chiều cao không hợp lệ (50 - 300 cm).';
          }
          if (msg.contains('weightKg')) {
            return 'Cân nặng không hợp lệ (10 - 500 kg).';
          }
          if (msg.contains('activityLevel')) {
            return 'Mức độ vận động không hợp lệ.';
          }
          return msg;
        }
      }
    } catch (_) {}
    return responseBody;
  }

  static Future<Map<String, dynamic>> saveProfile({
    required String sex,
    required String dateOfBirth,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String fitnessGoal,
    List<String>? allergies,
    List<String>? dietaryPreferences,
    Map<String, dynamic>? targetMacros,
  }) async {
    final token = await _getToken();
    final payload = <String, dynamic>{
      'sex': sex,
      'dateOfBirth': dateOfBirth,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel,
      'fitnessGoal': fitnessGoal,
      if (allergies != null) 'allergies': allergies,
      if (dietaryPreferences != null) 'dietaryPreferences': dietaryPreferences,
      if (targetMacros != null) 'targetMacros': targetMacros,
    };
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(token),
      body: json.encode(payload),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    throw Exception(parseApiError(response.body));
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
      await prefs.setString('user_email', email);
      await prefs.setString('user_full_name', fullName);
      if (data['user'] != null) {
        await prefs.setString('user_data', json.encode(data['user']));
      }
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: json.encode({'email': email, 'newPassword': newPassword}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(parseApiError(response.body));
    }
  }

  // ---------------------------------------------------------
  // CHỈ SỐ VÓC DÁNG (BODY STATS & HISTORY)
  // ---------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getBodyStatsHistory() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/profile/stats');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['history'] is List) {
        return List<Map<String, dynamic>>.from(data['history']);
      }
      return [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> addBodyStat({
    required String measuredOn,
    required double weightKg,
    double? heightCm,
    double? bodyFatPercent,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/profile/stats');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({
        'measuredOn': measuredOn,
        'weightKg': weightKg,
        if (heightCm != null) 'heightCm': heightCm,
        if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception(parseApiError(response.body));
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

  static Future<void> deleteInventoryItem(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/inventory/$id');
    try {
      await http.delete(url, headers: _headers(token));
    } catch (_) {}
  }

  static Future<void> clearInventory() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/inventory');
    try {
      await http.delete(url, headers: _headers(token));
    } catch (_) {}
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

