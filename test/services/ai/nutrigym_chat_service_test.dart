import 'package:flutter_test/flutter_test.dart';
import 'package:gymer_app/models/chat_message.dart';
import 'package:gymer_app/services/ai/nutrigym_chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NutriGymChatService Intent Tests', () {
    test('Greeting intent returns welcome message', () async {
      final response = await NutriGymChatService.processMessage('Xin chào NutriGym');
      expect(response.isUser, isFalse);
      expect(response.type, ChatMessageType.text);
      expect(response.text.toLowerCase(), contains('nutrigym ai assistant'));
    });

    test('Ingredient add intent parses ingredients and returns ingredientsAction message', () async {
      final response = await NutriGymChatService.processMessage('Hôm nay tôi mua 300g ức gà và 3 quả trứng');
      expect(response.isUser, isFalse);
      expect(response.type, ChatMessageType.ingredientsAction);
      expect(response.ingredients, isNotNull);
      expect(response.ingredients!.length, 2);
      expect(response.ingredients![0].name.toLowerCase(), contains('ức gà'));
      expect(response.ingredients![0].weight, 300);
      expect(response.ingredients![1].weight, 150);
    });

    test('Nutrition advice intent: Protein inquiry', () async {
      final response = await NutriGymChatService.processMessage('Cần nạp bao nhiêu protein để tăng cơ?');
      expect(response.isUser, isFalse);
      expect(response.type, ChatMessageType.text);
      expect(response.text.toLowerCase(), contains('protein cho gymer'));
      expect(response.text, contains('1.8 – 2.2g'));
    });

    test('Nutrition advice intent: Pre-workout meal', () async {
      final response = await NutriGymChatService.processMessage('Bữa ăn trước tập gym nên ăn gì?');
      expect(response.isUser, isFalse);
      expect(response.type, ChatMessageType.text);
      expect(response.text.toLowerCase(), contains('trước buổi tập'));
      expect(response.text.toLowerCase(), contains('yến mạch'));
    });

    test('Nutrition advice intent: Creatine guide', () async {
      final response = await NutriGymChatService.processMessage('Uống creatine như thế nào?');
      expect(response.isUser, isFalse);
      expect(response.type, ChatMessageType.text);
      expect(response.text.toLowerCase(), contains('creatine'));
      expect(response.text, contains('3g – 5g'));
    });

    test('Nutrition advice intent: Bulking strategy', () async {
      final response = await NutriGymChatService.processMessage('Chiến lược tăng cơ bulking');
      expect(response.isUser, isFalse);
      expect(response.type, ChatMessageType.text);
      expect(response.text.toLowerCase(), contains('bulking'));
      expect(response.text, contains('300 - 500 kcal'));
    });
  });
}
