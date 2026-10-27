import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/food_recognition_result.dart';
import '../food_recognition_service.dart';
import '../ingredient_normalizer.dart';

/// Dịch vụ nhận diện nguyên liệu và món ăn sử dụng Google Gemini 1.5 Flash Vision API:
/// - Nhận diện chính xác vượt trội giữa các loại thịt (bò, gà, heo, cá...) và rau củ.
/// - Không cần huấn luyện thủ công, trả về trực tiếp tên tiếng Việt chuẩn theo CSDL EatGym.
/// - Tự động dự phòng (fallback) sang Local Docker YOLO nếu mất mạng hoặc lỗi key.
class GeminiFoodRecognitionService implements FoodRecognitionService {
  final String? customApiKey;
  final FoodRecognitionService? fallbackService;

  GeminiFoodRecognitionService({
    this.customApiKey,
    this.fallbackService,
  });

  static const List<String> _preferredModels = [
    'gemini-3.8-flash',
    'gemini-flash-latest',
    'gemini-2.5-flash-lite',
  ];
  static const String _prefsKey = 'gemini_api_key';

  /// Lấy API key từ cấu hình tham số, biến môi trường hoặc SharedPreferences
  Future<String?> getApiKey() async {
    if (customApiKey != null && customApiKey!.trim().isNotEmpty) {
      return customApiKey!.trim();
    }
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefsKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        return savedKey.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Kiểm tra xem đã có API Key chưa
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Lưu API key vào bộ nhớ máy để sử dụng lâu dài
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.trim());
  }

  @override
  Future<List<FoodRecognitionResult>> recognizeIngredients(File image, {double confidence = 0.25}) async {
    final apiKey = await getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('⚠️ Chưa cấu hình Gemini API Key. Đang chuyển sang dịch vụ dự phòng...');
      if (fallbackService != null) {
        return fallbackService!.recognizeIngredients(image, confidence: confidence);
      }
      throw Exception('Vui lòng nhập Google Gemini API Key để nhận diện món ăn.');
    }

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      String mimeType = 'image/jpeg';
      final pathLower = image.path.toLowerCase();
      if (pathLower.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (pathLower.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final prompt = '''
Bạn là hệ thống thị giác AI chuyên nhận diện thực phẩm và nguyên liệu nấu ăn cho ứng dụng dinh dưỡng Gymer (EatGym).
Hãy phân tích hình ảnh này và liệt kê TẤT CẢ các loại nguyên liệu nấu ăn hoặc món ăn có mặt trong hình.

QUY TẮC BẮT BUỘC:
1. Phân biệt chính xác từng loại thịt:
   - Thịt thăn bò nạc, Thịt lợn nạc, Ức gà không da, Phi lê cá hồi, Tôm sú, Trứng gà tươi...
2. Nhận diện các loại rau củ, quả, nấm:
   - Bông cải xanh, Cà chua bi, Cà rốt tươi, Dưa leo, Bắp cải, Măng tây tươi, Nấm kim châm...
3. Nhận diện tinh bột và món ăn kèm:
   - Cơm gạo lứt, Bắp ngọt, Khoai tây, Khoai lang, Bánh mì...
4. Định dạng trả về: Chỉ trả về một JSON Array hợp lệ, mỗi phần tử là 1 object có cấu trúc:
   {
     "name": "Tên tiếng Việt chuẩn",
     "confidence": 0.95,
     "estimatedGrams": 150
   }
TUYỆT ĐỐI KHÔNG xuất văn bản giải thích thừa, chỉ xuất chuỗi JSON array thuần túy.
''';

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'response_mime_type': 'application/json',
        }
      });

      http.Response? response;
      for (final modelName in _preferredModels) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
        );

        try {
          final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          ).timeout(const Duration(seconds: 15));

          if (res.statusCode == 200) {
            response = res;
            debugPrint('✅ Gemini AI ($modelName) nhận diện thành công!');
            break;
          } else {
            debugPrint('⚠️ Model $modelName trả về mã ${res.statusCode}: ${res.body}. Đang thử model tiếp theo...');
          }
        } catch (callErr) {
          debugPrint('⚠️ Lỗi kết nối tới $modelName: $callErr');
        }
      }

      if (response == null || response.statusCode != 200) {
        debugPrint('Gemini API Error: Không có model nào phản hồi thành công.');
        if (fallbackService != null) {
          debugPrint('⚠️ Đang chuyển sang Local Docker AI Service do Gemini không khả dụng...');
          return await fallbackService!.recognizeIngredients(image, confidence: confidence);
        }
        throw Exception('Lỗi gọi Gemini API: Không kết nối được model nào.');
      }

      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final candidates = responseJson['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return [];
      }

      final text = candidates[0]['content']['parts'][0]['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return [];
      }

      final results = parseGeminiResponse(text, confidence: confidence);
      if (results.isEmpty && fallbackService != null) {
        return await fallbackService!.recognizeIngredients(image, confidence: confidence);
      }
      return results;
    } catch (e) {
      debugPrint('Gemini Food Recognition exception: $e');
      if (fallbackService != null) {
        debugPrint('⚠️ Chuyển sang fallback Local Docker AI...');
        return await fallbackService!.recognizeIngredients(image, confidence: confidence);
      }
      rethrow;
    }
  }

  /// Xử lý chuỗi JSON trả về từ Gemini và chuẩn hóa tên nguyên liệu
  static List<FoodRecognitionResult> parseGeminiResponse(String rawJson, {double confidence = 0.25}) {
    try {
      final cleanJson = rawJson
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final dynamic decoded = jsonDecode(cleanJson);
      final List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded.containsKey('ingredients')) {
        list = decoded['ingredients'] as List;
      } else if (decoded is Map && decoded.containsKey('items')) {
        list = decoded['items'] as List;
      } else {
        return [];
      }

      final List<FoodRecognitionResult> results = [];
      for (final item in list) {
        if (item is Map) {
          final rawName = item['name']?.toString().trim() ?? '';
          final conf = (item['confidence'] as num?)?.toDouble() ?? 0.95;
          if (rawName.isNotEmpty && conf >= confidence) {
            // Chuẩn hóa tên món ăn sang danh mục chuẩn của EatGym
            final normalized = IngredientNormalizer.normalizeToVietnamese(rawName);
            results.add(FoodRecognitionResult(
              foodName: normalized.isNotEmpty ? normalized : rawName,
              confidence: conf,
            ));
          }
        }
      }
      return results;
    } catch (e) {
      debugPrint('Lỗi phân tích cú pháp Gemini JSON: $e');
      return [];
    }
  }
}
