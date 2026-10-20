import 'package:flutter_test/flutter_test.dart';
import 'package:gymer_app/services/ai/voice_ingredient_parser.dart';

void main() {
  group('VoiceIngredientParser Tests', () {
    test('Parse numbers with g/gram unit', () {
      final results = VoiceIngredientParser.parseSpokenText('200g ức gà');
      expect(results.length, 1);
      expect(results[0].name.toLowerCase(), contains('ức gà'));
      expect(results[0].weight, 200);
    });

    test('Parse compound sentence with "và" and counting units', () {
      final results = VoiceIngredientParser.parseSpokenText('300 gam ức gà và 3 quả trứng');
      expect(results.length, 2);
      expect(results[0].weight, 300);
      expect(results[1].weight, 150); // 3 quả x 50g = 150g
    });

    test('Parse Vietnamese special phrases: nửa ký, lạng', () {
      final results = VoiceIngredientParser.parseSpokenText('Thêm nửa ký thịt bò và 2 lạng tôm');
      expect(results.length, 2);
      expect(results[0].weight, 500); // Nửa ký = 500g
      expect(results[1].weight, 200); // 2 lạng = 200g
    });

    test('Parse Vietnamese word numbers: hai trăm gam, ba quả', () {
      final results = VoiceIngredientParser.parseSpokenText('hai trăm gam cá hồi và ba quả chuối');
      expect(results.length, 2);
      expect(results[0].weight, 200);
      expect(results[1].weight, 360); // 3 quả chuối x 120g = 360g
    });

    test('Parse comma-separated ingredients with decimal kg', () {
      final results = VoiceIngredientParser.parseSpokenText('0.5 kg khoai tây, 200g súp lơ xanh');
      expect(results.length, 2);
      expect(results[0].weight, 500);
      expect(results[1].weight, 200);
    });

    test('Parse items without explicit "và" delimiter', () {
      final results = VoiceIngredientParser.parseSpokenText('200g ức gà 3 quả trứng');
      expect(results.length, 2);
      expect(results[0].weight, 200);
      expect(results[1].weight, 150);
    });
  });
}
