import 'package:flutter_test/flutter_test.dart';
import 'package:gymer_app/services/ai/providers/roboflow_food_recognition_service.dart';

void main() {
  group('RoboflowFoodRecognitionService - Unit Tests', () {
    test('parsePredictions should correctly map valid Roboflow JSON response', () {
      final mockResponse = {
        "predictions": [
          {
            "x": 262.5,
            "y": 156,
            "width": 223,
            "height": 238,
            "confidence": 0.9148,
            "class": "Yellow Onion",
            "class_id": 60
          },
          {
            "confidence": 0.7041,
            "class": "Tomato"
          }
        ]
      };

      final results = RoboflowFoodRecognitionService.parsePredictions(mockResponse);

      expect(results.length, 2);
      
      expect(results[0].foodName, "Yellow Onion");
      expect(results[0].confidence, 0.9148);
      
      expect(results[1].foodName, "Tomato");
      expect(results[1].confidence, 0.7041);
    });

    test('parsePredictions should return empty list if predictions is missing or not a list', () {
      expect(RoboflowFoodRecognitionService.parsePredictions({}), isEmpty);
      expect(RoboflowFoodRecognitionService.parsePredictions({"predictions": "invalid"}), isEmpty);
    });

    test('parsePredictions should handle missing fields gracefully', () {
      final mockResponse = {
        "predictions": [
          {
            "class": "Garlic"
            // confidence missing
          }
        ]
      };
      
      final results = RoboflowFoodRecognitionService.parsePredictions(mockResponse);
      expect(results.first.foodName, "Garlic");
      expect(results.first.confidence, 0.0);
    });
  });
}
