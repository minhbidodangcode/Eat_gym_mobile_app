import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymer_app/services/ai/providers/gemini_food_recognition_service.dart';
import 'package:gymer_app/services/ai/ai_service_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GeminiFoodRecognitionService - Unit Tests', () {
    test('AIServiceFactory should create GeminiFoodRecognitionService by default', () {
      final service = AIServiceFactory.createFoodRecognitionService();
      expect(service is GeminiFoodRecognitionService, true);
    });

    test('parseGeminiResponse should parse valid JSON array and normalize names', () {
      const mockJson = '''
      [
        {"name": "beef", "confidence": 0.96, "estimatedGrams": 200},
        {"name": "broccoli", "confidence": 0.92, "estimatedGrams": 150},
        {"name": "Cà chua bi", "confidence": 0.88, "estimatedGrams": 80}
      ]
      ''';

      final results = GeminiFoodRecognitionService.parseGeminiResponse(mockJson, confidence: 0.4);

      expect(results.length, 3);
      expect(results[0].foodName, 'Thịt thăn bò nạc');
      expect(results[0].confidence, 0.96);
      expect(results[1].foodName, 'Bông cải xanh (Broccoli)');
      expect(results[1].confidence, 0.92);
      expect(results[2].foodName, 'Cà chua bi');
      expect(results[2].confidence, 0.88);
    });

    test('parseGeminiResponse should strip markdown code fences', () {
      const mockMarkdown = '''
      ```json
      [
        {"name": "chicken breast", "confidence": 0.95},
        {"name": "carrot", "confidence": 0.90}
      ]
      ```
      ''';

      final results = GeminiFoodRecognitionService.parseGeminiResponse(mockMarkdown, confidence: 0.4);

      expect(results.length, 2);
      expect(results[0].foodName, 'Ức gà không da');
      expect(results[1].foodName, 'Cà rốt tươi');
    });

    test('parseGeminiResponse should filter items below confidence threshold', () {
      const mockJson = '''
      [
        {"name": "egg", "confidence": 0.85},
        {"name": "pork", "confidence": 0.30}
      ]
      ''';

      final results = GeminiFoodRecognitionService.parseGeminiResponse(mockJson, confidence: 0.6);

      expect(results.length, 1);
      expect(results.first.foodName, 'Trứng gà tươi');
    });

    test('hasApiKey and saveApiKey should interact properly with SharedPreferences', () async {
      final service = GeminiFoodRecognitionService();
      expect(await service.hasApiKey(), false);

      await GeminiFoodRecognitionService.saveApiKey('AIzaSyTestKey123456');

      expect(await service.hasApiKey(), true);
      expect(await service.getApiKey(), 'AIzaSyTestKey123456');
    });
  });
}
