import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class YoloApiService {
  // Địa chỉ AI FastAPI server trên máy ảo
  static const String aiBaseUrl = 'http://192.168.1.54:8000/api/v1';

  /// Gửi ảnh lên FastAPI YOLOv8 để nhận diện món ăn
  static Future<Map<String, dynamic>> detectFood(File imageFile, {double confidence = 0.25}) async {
    final url = Uri.parse('$aiBaseUrl/detect?confidence=$confidence');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['ngrok-skip-browser-warning'] = 'true';
    
    // Thêm file ảnh vào request
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Lỗi nhận diện: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối tới AI Service: $e');
    }
  }
}
