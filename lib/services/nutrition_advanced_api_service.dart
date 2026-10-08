import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // import để dùng chung baseUrl và logic token nếu cần

class NutritionAdvancedApiService {
  // Hàm lấy token, tương tự như ApiService
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? 'dummy_token'; 
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // NHÓM 1: MEAL PREP SỐNG - CHÍN (meal-prep.js)
  // ==========================================

  /// Lấy danh sách hệ số chuyển đổi sống/chín
  static Future<Map<String, dynamic>> getYieldFactors({String search = ''}) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiService.baseUrl}/yield-factors?search=$search');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to get yield factors: ${response.body}');
  }

  /// Quy đổi khối lượng sống <-> chín (gọi API /convert)
  static Future<Map<String, dynamic>> convertIngredientWeight({
    required String yieldFactorId,
    required double inputWeightG,
    required String inputState, // 'raw' hoặc 'cooked'
    required int servings,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiService.baseUrl}/convert');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({
        'yieldFactorId': yieldFactorId,
        'inputWeightG': inputWeightG,
        'inputState': inputState,
        'servings': servings,
      }),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to convert weight: ${response.body}');
  }

  /// Lưu một mẻ Meal Prep
  static Future<Map<String, dynamic>> createMealPrepBatch({
    required String name,
    required int servings,
    String? notes,
    required List<Map<String, dynamic>> items, 
    // items item format: { 'yieldFactorId': '...', 'inputWeightG': 500, 'inputState': 'raw' }
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiService.baseUrl}/batches');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({
        'name': name,
        'servings': servings,
        'notes': notes,
        'items': items,
      }),
    );
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Failed to create meal prep batch: ${response.body}');
  }


  // ==========================================
  // NHÓM 2: BÙ TRỪ CALO ĐỘNG (compensation.js)
  // ==========================================

  /// Cập nhật mục tiêu Calo cho 1 bữa ăn (mealSlot: breakfast, lunch, dinner, ...)
  static Future<Map<String, dynamic>> setMealTarget({
    required String targetDate, // YYYY-MM-DD
    required String mealSlot,
    required double plannedKcal,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiService.baseUrl}/meal-targets/$targetDate/$mealSlot');
    final response = await http.put(
      url,
      headers: _headers(token),
      body: json.encode({'plannedKcal': plannedKcal}),
    );
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Failed to set meal target: ${response.body}');
  }

  /// Ghi nhận sai lệch Calo (ăn lố / ăn thiếu)
  static Future<Map<String, dynamic>> recordDeviation({
    required String occurredOn, // YYYY-MM-DD
    required double targetKcal,
    required double actualKcal,
    String? note,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiService.baseUrl}/deviations');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({
        'occurredOn': occurredOn,
        'targetKcal': targetKcal,
        'actualKcal': actualKcal,
        'note': note,
      }),
    );
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Failed to record deviation: ${response.body}');
  }

  /// Phân bổ tự động Calo dư (bù trừ) vào 1-2 ngày tới
  static Future<Map<String, dynamic>> allocateCompensation({
    required String deviationId,
    required int horizonDays, // 1 hoặc 2
    double minKcalPerMeal = 0,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiService.baseUrl}/compensations');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: json.encode({
        'deviationId': deviationId,
        'horizonDays': horizonDays,
        'minKcalPerMeal': minKcalPerMeal,
      }),
    );
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Failed to allocate compensation: ${response.body}');
  }
}
