import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or localhost for iOS/Web.
  // Adjust this to your backend's actual IP if running on physical device.
  static const String baseUrl = 'http://192.168.1.54:3000/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Fallback to a dummy token if not logged in (for testing purposes)
    return prefs.getString('auth_token') ?? 'dummy_token'; 
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
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
      headers: {'Content-Type': 'application/json'},
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

  static Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
    
    if (response.statusCode == 201) {
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
}
