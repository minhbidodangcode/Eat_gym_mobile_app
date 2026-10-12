import 'package:flutter_test/flutter_test.dart';
import 'package:gymer_app/services/ai/providers/local_docker_food_recognition_service.dart';

void main() {
  group('LocalDockerFoodRecognitionService - Unit Tests', () {
    test('parseDetections should correctly map valid eatgym-ai response', () {
      final mockResponse = {
        "filename": "meal.jpg",
        "detections": [
          {
            "class_id": 24,
            "class_name": "Trứng gà tươi",
            "english_name": "egg",
            "confidence": 0.942,
            "bbox": [10.0, 20.0, 100.0, 200.0]
          },
          {
            "class_id": 73,
            "class_name": "Cà chua",
            "english_name": "tomato",
            "confidence": 0.885,
            "bbox": [50.0, 60.0, 120.0, 180.0]
          }
        ],
        "count": 2,
        "inference_ms": 42.5
      };

      final results = LocalDockerFoodRecognitionService.parseDetections(mockResponse);

      expect(results.length, 2);
      expect(results[0].foodName, "egg");
      expect(results[0].confidence, 0.942);
      expect(results[1].foodName, "tomato");
      expect(results[1].confidence, 0.885);
    });

    test('parseDetections should fallback to class_name if english_name is missing', () {
      final mockResponse = {
        "detections": [
          {
            "class_id": 1,
            "class_name": "Phở bò",
            "confidence": 0.85
          }
        ]
      };

      final results = LocalDockerFoodRecognitionService.parseDetections(mockResponse);
      expect(results.length, 1);
      expect(results.first.foodName, "Phở bò");
      expect(results.first.confidence, 0.85);
    });

    test('parseDetections should return empty list if detections is missing or not a list', () {
      expect(LocalDockerFoodRecognitionService.parseDetections({}), isEmpty);
      expect(LocalDockerFoodRecognitionService.parseDetections({"detections": "invalid"}), isEmpty);
    });
  });
}
