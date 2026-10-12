import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../models/food_recognition_result.dart';
import '../food_recognition_service.dart';

class RoboflowFoodRecognitionService implements FoodRecognitionService {
  final String _apiKey;
  final String _baseUrl = "https://serverless.roboflow.com/food-ingredient-recognition-ml/1";

  RoboflowFoodRecognitionService({
    required String apiKey,
  }) : _apiKey = apiKey;

  /// Parsers the Roboflow JSON response into a list of [FoodRecognitionResult].
  /// This is internal and exposed for testing purposes.
  static List<FoodRecognitionResult> parsePredictions(Map<String, dynamic> data) {
    if (!data.containsKey('predictions') || data['predictions'] is! List) {
      return [];
    }

    final List predictions = data['predictions'];
    
    return predictions.map((item) {
      try {
        return FoodRecognitionResult(
          foodName: item['class']?.toString() ?? 'Unknown',
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
  Future<List<FoodRecognitionResult>> recognizeIngredients(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: base64Image,
      );

      if (response.statusCode != 200) {
        throw Exception("Roboflow API error: ${response.statusCode} - ${response.body}");
      }

      final Map<String, dynamic> data = json.decode(response.body);
      return parsePredictions(data);

    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Failed to recognize ingredients: $e");
    }
  }
}
