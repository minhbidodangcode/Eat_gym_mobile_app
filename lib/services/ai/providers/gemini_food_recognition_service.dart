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

  static final List<String> apiKeysPool = [
    // Key được nhập động qua giao diện ứng dụng (nhấn giữ badge AI VISION 4.2 • READY để dán key mới)
    // hoặc truyền qua biến môi trường --dart-define=GEMINI_API_KEY=...
  ];
  static int _keyIndex = 0;

  static const List<String> _preferredModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-flash-latest',
  ];
  static const String _prefsKey = 'gemini_api_key';

  /// Lấy danh sách API keys ưu tiên (custom, saved, và pool 4 keys xoay vòng)
  Future<List<String>> getAllApiKeys() async {
    final List<String> keys = [];
    if (customApiKey != null && customApiKey!.trim().isNotEmpty) {
      keys.add(customApiKey!.trim());
    }
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty && !keys.contains(envKey)) {
      keys.add(envKey);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefsKey);
      if (savedKey != null && savedKey.trim().isNotEmpty && !keys.contains(savedKey.trim())) {
        keys.add(savedKey.trim());
      }
    } catch (_) {}

    // Bổ sung 4 keys xoay vòng được cấu hình sẵn
    for (int i = 0; i < apiKeysPool.length; i++) {
      final idx = (_keyIndex + i) % apiKeysPool.length;
      final k = apiKeysPool[idx];
      if (!keys.contains(k)) {
        keys.add(k);
      }
    }
    return keys;
  }

  /// Lấy API key hiện tại
  Future<String?> getApiKey() async {
    final all = await getAllApiKeys();
    return all.isNotEmpty ? all.first : null;
  }

  /// Kiểm tra xem đã có API Key chưa
  Future<bool> hasApiKey() async {
    final keys = await getAllApiKeys();
    return keys.isNotEmpty;
  }

  /// Lưu API key vào bộ nhớ máy để sử dụng lâu dài
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.trim());
  }

  @override
  Future<List<FoodRecognitionResult>> recognizeIngredients(File image, {double confidence = 0.25}) async {
    final allKeys = await getAllApiKeys();

    if (allKeys.isEmpty) {
      debugPrint('⚠️ Chưa cấu hình Gemini API Key. Đang chuyển sang dịch vụ dự phòng...');
      if (fallbackService != null) {
        return fallbackService!.recognizeIngredients(image, confidence: confidence);
      }
      throw Exception('Vui lòng cấu hình Gemini API Key để nhận diện món ăn.');
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
   - Thịt thăn bò nạc, Thịt lợn nạc, Ức gà không da, Ức gà tươi, Phi lê cá hồi, Tôm sú, Trứng gà tươi...
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

      // Xoay vòng qua danh sách API Key và Model
      for (final apiKey in allKeys) {
        for (final modelName in _preferredModels) {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
          );

          try {
            final res = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            ).timeout(const Duration(seconds: 12));

            if (res.statusCode == 200) {
              response = res;
              debugPrint('✅ Gemini AI ($modelName) nhận diện thành công với key: ${apiKey.substring(0, 10)}...');
              break;
            } else {
              debugPrint('⚠️ Model $modelName (Key: ${apiKey.substring(0, 10)}...) trả về mã ${res.statusCode}. Đang thử tiếp...');
            }
          } catch (callErr) {
            debugPrint('⚠️ Lỗi kết nối tới $modelName (Key: ${apiKey.substring(0, 10)}...): $callErr');
          }
        }
        if (response != null && response.statusCode == 200) {
          // Lưu lại key đang hoạt động tốt
          final foundIdx = apiKeysPool.indexOf(apiKey);
          if (foundIdx != -1) {
            _keyIndex = foundIdx;
          }
          break;
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

  @override
  Future<Map<String, dynamic>> recognizeCookedDish(File image) async {
    final allKeys = await getAllApiKeys();

    if (allKeys.isEmpty) {
      debugPrint('⚠️ Chưa cấu hình Gemini API Key. Đang chuyển sang fallback...');
      if (fallbackService != null) {
        return fallbackService!.recognizeCookedDish(image);
      }
      throw Exception('Vui lòng cấu hình Gemini API Key để nhận diện đĩa món ăn.');
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
Bạn là chuyên gia dinh dưỡng và thị giác AI chuyên phân tích đĩa thức ăn đã nấu chín cho gymer (EatGym).
Hãy quan sát kỹ đĩa thức ăn/bữa ăn trong hình và bóc tách thành phần dinh dưỡng:
1. "dishName": Tên món ăn tổng thể chính xác bằng tiếng Việt (ví dụ: "Cơm ức gà áp chảo sốt nấm", "Bò bít tết khoai tây nghiền", "Phở bò tái", "Salad cá hồi trứng luộc", "Cơm sườn nướng"...).
2. "estimatedGrams": Ước lượng tổng khối lượng cả đĩa thức ăn tính theo gram (số nguyên, ví dụ: 450).
3. "calories": Tổng Calo của cả đĩa (kcal, số nguyên).
4. "protein": Tổng Protein (g, số thực hoặc nguyên).
5. "carbs": Tổng Tinh bột (g, số thực hoặc nguyên).
6. "fat": Tổng Chất béo (g, số thực hoặc nguyên).
7. "ingredients": Danh sách 3-5 nguyên liệu chính nhìn thấy trên đĩa kèm ước lượng (ví dụ: ["Ức gà áp chảo (~200g)", "Cơm gạo lứt (~150g)", "Bông cải xanh luộc (~100g)"]).
8. "suggestion": Lời khuyên dinh dưỡng cho gymer (1-2 câu, ví dụ: "Bữa ăn giàu đạm nạc rất tốt cho tăng cơ, lượng carb hợp lý. Chú ý giảm bớt sốt để hạn chế sodium.").

QUY TẮC BẮT BUỘC:
- Trả về DUY NHẤT một chuỗi JSON Object hợp lệ theo các trường trên (không kèm markdown ```json hay văn bản giải thích).
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

      // Xoay vòng qua danh sách API Key và Model
      for (final apiKey in allKeys) {
        for (final modelName in _preferredModels) {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
          );

          try {
            final res = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            ).timeout(const Duration(seconds: 14));

            if (res.statusCode == 200) {
              response = res;
              debugPrint('✅ Gemini AI ($modelName) nhận diện đĩa món ăn thành công với key: ${apiKey.substring(0, 10)}...');
              break;
            } else {
              debugPrint('⚠️ Model $modelName (Key: ${apiKey.substring(0, 10)}...) trả về mã ${res.statusCode}. Đang thử tiếp...');
            }
          } catch (callErr) {
            debugPrint('⚠️ Lỗi kết nối tới $modelName (Key: ${apiKey.substring(0, 10)}...): $callErr');
          }
        }
        if (response != null && response.statusCode == 200) {
          final foundIdx = apiKeysPool.indexOf(apiKey);
          if (foundIdx != -1) {
            _keyIndex = foundIdx;
          }
          break;
        }
      }

      if (response == null || response.statusCode != 200) {
        if (fallbackService != null) {
          return await fallbackService!.recognizeCookedDish(image);
        }
        throw Exception('Lỗi gọi Gemini API: Không kết nối được model nào.');
      }

      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final candidates = responseJson['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini không trả về kết quả nào.');
      }

      final text = candidates[0]['content']['parts'][0]['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Nội dung phân tích đĩa thức ăn rỗng.');
      }

      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleanJson);
      Map<String, dynamic> dishMap;
      if (decoded is Map<String, dynamic>) {
        dishMap = decoded;
      } else if (decoded is Map) {
        dishMap = Map<String, dynamic>.from(decoded);
      } else {
        throw Exception('Kết quả không phải Map JSON');
      }

      // Đảm bảo dữ liệu chuẩn
      return {
        'dishName': dishMap['dishName']?.toString() ?? 'Đĩa món ăn Gymer',
        'estimatedGrams': (dishMap['estimatedGrams'] as num?)?.toInt() ?? 400,
        'calories': (dishMap['calories'] as num?)?.toInt() ?? 550,
        'protein': (dishMap['protein'] as num?)?.toDouble() ?? 40.0,
        'carbs': (dishMap['carbs'] as num?)?.toDouble() ?? 50.0,
        'fat': (dishMap['fat'] as num?)?.toDouble() ?? 12.0,
        'ingredients': dishMap['ingredients'] is List
            ? (dishMap['ingredients'] as List).map((e) => e.toString()).toList()
            : <String>[],
        'suggestion': dishMap['suggestion']?.toString() ?? 'Bữa ăn cân đối Macros hỗ trợ mục tiêu Gymer.',
      };
    } catch (e) {
      debugPrint('Gemini Dish Recognition exception: $e');
      if (fallbackService != null) {
        return await fallbackService!.recognizeCookedDish(image);
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
