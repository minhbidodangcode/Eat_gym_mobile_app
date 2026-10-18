import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../models/food_recognition_result.dart';
import '../food_recognition_service.dart';
import '../ingredient_normalizer.dart';

/// Provider nhận diện đồ ăn qua Local Docker AI Server (FastAPI + YOLOv8)
class LocalDockerFoodRecognitionService implements FoodRecognitionService {
  /// Danh sách endpoint dự phòng:
  /// - ngrok: Tên miền cố định
  /// - 127.0.0.1:8000: Dành cho kết nối qua cáp USB (đã reverse port qua adb)
  /// - 10.0.2.2:8000: Dành cho Android Emulator
  /// - 192.168.1.47:8000: Dành cho mạng nội bộ Wi-Fi LAN
  final List<String> endpoints;

  LocalDockerFoodRecognitionService({
    List<String>? endpoints,
  }) : endpoints = endpoints ?? [
          'http://192.168.1.54:8000/api/v1/detect',
          'http://10.0.2.2:8000/api/v1/detect',
          'http://127.0.0.1:8000/api/v1/detect',
          'http://192.168.1.47:8000/api/v1/detect',
          'https://kindly-absolve-concur.ngrok-free.dev/api/v1/detect',
        ];

  /// Chuyển đổi dữ liệu JSON từ eatgym-ai thành danh sách FoodRecognitionResult (Đã dịch sang tiếng Việt)
  static List<FoodRecognitionResult> parseDetections(Map<String, dynamic> data) {
    if (!data.containsKey('detections') || data['detections'] is! List) {
      return [];
    }

    final List detections = data['detections'];

    return detections.map((item) {
      try {
        final englishName = item['english_name']?.toString().trim();
        final className = item['class_name']?.toString().trim();
        final rawFoodName = (englishName != null && englishName.isNotEmpty)
            ? englishName
            : (className ?? 'Unknown');

        // Ánh xạ tự động từ nhãn tiếng Anh của YOLO sang tiếng Việt chuẩn trong CSDL
        final vietnameseName = IngredientNormalizer.normalizeToVietnamese(rawFoodName);

        return FoodRecognitionResult(
          foodName: vietnameseName,
          confidence: (item['confidence'] as num?)?.toDouble() ?? 0.0,
        );
      } catch (e) {
        return null;
      }
    })
    .whereType<FoodRecognitionResult>()
    .toList();
  }

  @override
  Future<List<FoodRecognitionResult>> recognizeIngredients(File image, {double confidence = 0.25}) async {
    Exception? lastError;

    for (final endpoint in endpoints) {
      try {
        // Truyền tham số confidence xuống API AI
        final baseUri = Uri.parse(endpoint);
        final uri = baseUri.replace(queryParameters: {
          ...baseUri.queryParameters,
          'confidence': confidence.toString(),
        });

        final request = http.MultipartRequest('POST', uri);
        request.headers['ngrok-skip-browser-warning'] = 'true';
        request.files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );

        final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
          return parseDetections(data);
        } else {
          lastError = Exception('AI Docker Server lỗi (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        lastError = Exception('Không kết nối được tới $endpoint: $e');
      }
    }

    throw lastError ?? Exception('Không thể kết nối đến AI Server nội bộ Docker.');
  }
}
