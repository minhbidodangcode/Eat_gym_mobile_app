import '../../models/chat_message.dart';
import '../../models/voice_ingredient_result.dart';
import '../api_service.dart';
import 'voice_ingredient_parser.dart';

class NutriGymChatService {
  /// Xử lý tin nhắn người dùng và trả về phản hồi thông minh từ AI Assistant
  static Future<ChatMessage> processMessage(
    String userText, {
    List<Map<String, dynamic>>? availableIngredients,
  }) async {
    final text = userText.trim();
    if (text.isEmpty) {
      return ChatMessage.botText('Xin chào! Tôi có thể giúp gì cho chế độ dinh dưỡng và kho thực phẩm của bạn hôm nay?');
    }

    final lower = text.toLowerCase();

    // 1. INTENT: Lời chào hoặc câu hỏi giới thiệu (Greeting)
    if (_isGreeting(lower)) {
      return ChatMessage.botText(
        'Xin chào Gymer! 💪 Tôi là **NutriGym AI Assistant** — Trợ lý ảo dinh dưỡng thể hình của bạn.\n\n'
        'Tôi có thể giúp bạn:\n'
        '• 🎙️ **Thêm nguyên liệu vào tab Nguyên liệu** qua giọng nói hoặc văn bản (VD: *"Hôm nay có 300g ức gà và 3 quả trứng"*)\n'
        '• 🍲 **Gợi ý món ăn dinh dưỡng** từ các nguyên liệu bạn chọn (VD: *"Nấu món gì với ức gà và trứng?"*)\n'
        '• 🥩 **Tư vấn dinh dưỡng tăng cơ/giảm mỡ** (VD: *"Cần nạp bao nhiêu protein để tăng cơ?"*)'
      );
    }

    // 2. INTENT: Kiểm tra danh sách nguyên liệu đã chọn
    if (_isIngredientsListIntent(lower)) {
      return _handleIngredientsListCheck(availableIngredients);
    }

    // 3. INTENT: Tư vấn dinh dưỡng thể hình (Gym Nutrition Q&A)
    // Ưu tiên cao cho các thắc mắc khoa học thể hình (Protein, Pre/Post-workout, Creatine, Bulking, Cutting)
    final nutritionAdvice = _matchNutritionAdvice(lower);
    if (nutritionAdvice != null) {
      return ChatMessage.botText(nutritionAdvice);
    }

    // 4. INTENT: Thêm nguyên liệu bằng giọng nói/văn bản (Ingredient Extraction & Management)
    final parsedIngredients = VoiceIngredientParser.parseSpokenText(
      text,
      availableIngredients: availableIngredients,
    );
    if (parsedIngredients.isNotEmpty && _isIngredientAddIntent(lower, parsedIngredients)) {
      return _handleIngredientAdd(parsedIngredients);
    }

    // 5. INTENT: Gợi ý công thức món ăn (Recipe Suggestions)
    if (_isRecipeIntent(lower)) {
      return await _handleRecipeSuggestion(text, lower, availableIngredients);
    }

    // Fallback: Trả lời tự nhiên và gợi ý hành động
    return ChatMessage.botText(
      'Tôi đã lắng nghe bạn! Với vai trò là Trợ lý AI NutriGym, bạn có thể:\n\n'
      '1. Nói hoặc gõ danh sách nguyên liệu để thêm trực tiếp vào tab Nguyên liệu.\n'
      '2. Hỏi tôi gợi ý món ăn dinh dưỡng từ các nguyên liệu sẵn có.\n'
      '3. Đặt câu hỏi về cách tính Macro, Protein, bữa ăn trước/sau buổi tập gym.\n\n'
      'Bạn muốn thực hiện điều gì tiếp theo?'
    );
  }

  // ---------------------------------------------------------------------------
  // Xử lý các Intent
  // ---------------------------------------------------------------------------

  static bool _isGreeting(String text) {
    return text == 'hi' ||
        text == 'hello' ||
        text.startsWith('chào') ||
        text.startsWith('xin chào') ||
        text.contains('bạn là ai') ||
        text.contains('giúp gì');
  }

  static bool _isIngredientsListIntent(String text) {
    return text.contains('nguyên liệu đã chọn') ||
        text.contains('danh sách nguyên liệu') ||
        text.contains('đã chọn gì') ||
        text.contains('nguyên liệu hiện có') ||
        text.contains('xem nguyên liệu');
  }

  static ChatMessage _handleIngredientsListCheck(List<Map<String, dynamic>>? ingredients) {
    final items = ingredients ?? [];
    if (items.isEmpty) {
      return ChatMessage.botText(
        'Danh sách nguyên liệu của bạn hiện đang trống! 🥗\n\n'
        'Bạn có thể nói hoặc gõ nguyên liệu bạn muốn thêm (ví dụ: *"Thêm 300g ức gà, 4 quả trứng và 2 củ khoai tây"*), tôi sẽ thêm ngay vào tab Nguyên liệu cho bạn.'
      );
    }

    int totalCalories = 0;
    double totalProtein = 0;
    for (final item in items) {
      final kcal = (item['kcalPer100g'] ?? 100) as num;
      final w = (item['weight'] ?? 100) as num;
      totalCalories += (kcal * w / 100).round();
      totalProtein += (((item['protein'] as num?) ?? 10) * w / 100);
    }

    final summary = 'Tab Nguyên liệu của bạn hiện có **${items.length} món**:\n'
        '🔥 Tổng năng lượng: **$totalCalories kcal**\n'
        '💪 Tổng Protein: **${totalProtein.round()}g đạm**\n\n'
        'Dưới đây là các thực phẩm sẵn sàng để bạn chế biến hoặc gợi ý món ăn:';

    return ChatMessage.botIngredients(
      text: summary,
      ingredients: items.map((i) => VoiceIngredientResult(
        name: i['name']?.toString() ?? '',
        rawSpokenText: '',
        icon: i['icon']?.toString() ?? '🥗',
        weight: (i['weight'] as num?)?.toInt() ?? 100,
        kcalPer100g: (i['kcalPer100g'] as num?)?.toInt() ?? 100,
        protein: ((i['protein'] as num?) ?? 10).toDouble(),
        carbs: ((i['carbs'] as num?) ?? 5).toDouble(),
        fat: ((i['fat'] as num?) ?? 3).toDouble(),
      )).toList(),
    );
  }

  static bool _isRecipeIntent(String text) {
    final keywords = [
      'nấu món gì',
      'gợi ý món',
      'công thức',
      'món ngon',
      'ăn gì',
      'chế biến',
      'cách làm',
      'thực đơn',
      'món ăn',
      'nấu gì',
      'làm món gì'
    ];
    return keywords.any((k) => text.contains(k));
  }

  static Future<ChatMessage> _handleRecipeSuggestion(
    String rawText,
    String lower,
    List<Map<String, dynamic>>? availableIngredients,
  ) async {
    List<String> queryIngredients = [];

    // Kiểm tra xem người dùng có nhắc đến nguyên liệu cụ thể trong câu không
    final parsed = VoiceIngredientParser.parseSpokenText(
      rawText,
      availableIngredients: availableIngredients,
    );
    if (parsed.isNotEmpty) {
      queryIngredients = parsed.map((p) => p.name).toList();
    }

    // Nếu không chỉ định nguyên liệu cụ thể, lấy từ danh sách nguyên liệu đã chọn
    if (queryIngredients.isEmpty && availableIngredients != null && availableIngredients.isNotEmpty) {
      queryIngredients = availableIngredients.map((i) => i['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
    }

    try {
      final recipes = await ApiService.suggestRecipes(queryIngredients);

      if (recipes.isEmpty) {
        return ChatMessage.botText(
          'Tôi chưa tìm thấy món ăn phù hợp với danh sách nguyên liệu hiện có. '
          'Bạn thử thêm các nguyên liệu phổ biến như **ức gà, trứng, thịt bò, súp lơ xanh** vào tab Nguyên liệu nhé!'
        );
      }

      final intro = queryIngredients.isNotEmpty
          ? 'Dựa trên nguyên liệu (${queryIngredients.take(4).join(', ')}...), đây là các món ăn giàu dinh dưỡng nhất gợi ý cho bạn:'
          : 'Dưới đây là các công thức món ăn thể hình giàu đạm hàng đầu gợi ý cho bạn:';

      return ChatMessage.botRecipes(
        text: intro,
        recipes: recipes.take(4).toList(),
      );
    } catch (e) {
      return ChatMessage.botText('Có lỗi khi tìm kiếm công thức gợi ý: $e');
    }
  }

  static bool _isIngredientAddIntent(String text, List<VoiceIngredientResult> ingredients) {
    if (ingredients.isEmpty) return false;

    // Các cụm từ chỉ hành động thêm/khai báo nguyên liệu
    final actionKeywords = [
      'thêm',
      'mua',
      'vừa mua',
      'mới mua',
      'tôi có',
      'mình có',
      'có sẵn',
      'chọn',
      'lấy',
      'nhập',
      'bổ sung',
      'cho vào',
      'cho tôi',
    ];

    if (actionKeywords.any((k) => text.contains(k))) return true;

    // Hoặc câu chứa số lượng đơn vị đo lường/đếm cụ thể (VD: "200g ức gà và 3 quả trứng")
    final hasUnitQuantity = RegExp(
      r'\b\d+(?:[\.,]\d+)?\s*(g|gam|gram|kg|kí|ký|lạng|cân|quả|trái|củ|bắp|hộp|bịch)\b',
      caseSensitive: false,
    ).hasMatch(text);

    final hasWordQuantity = RegExp(
      r'(?:nửa|một|hai|ba|bốn|năm|sáu|bảy|tám|chín|mười|chục|trăm)\s+(?:gam|gram|kg|kí|ký|lạng|cân|quả|trái|củ|bắp|hộp|bịch)',
      caseSensitive: false,
    ).hasMatch(text);

    return hasUnitQuantity || hasWordQuantity;
  }

  static ChatMessage _handleIngredientAdd(List<VoiceIngredientResult> ingredients) {
    int totalKcal = ingredients.fold(0, (sum, i) => sum + i.totalCalories);
    double totalP = ingredients.fold(0.0, (sum, i) => sum + i.totalProtein);

    final summary = 'Tôi đã nhận diện được **${ingredients.length} nguyên liệu** từ yêu cầu của bạn:\n'
        '• Năng lượng: **$totalKcal kcal**\n'
        '• Protein: **${totalP.round()}g đạm**\n\n'
        'Nhấn nút bên dưới để thêm trực tiếp vào tab Nguyên liệu:';

    return ChatMessage.botIngredients(
      text: summary,
      ingredients: ingredients,
    );
  }

  // ---------------------------------------------------------------------------
  // Cơ sở tri thức dinh dưỡng thể hình (Gym Nutrition Knowledge Base)
  // ---------------------------------------------------------------------------

  static String? _matchNutritionAdvice(String text) {
    // 1. Nhu cầu Protein
    if (text.contains('bao nhiêu protein') ||
        text.contains('bao nhiêu đạm') ||
        text.contains('lượng protein') ||
        text.contains('nạp đạm')) {
      return '💪 **Khuyến nghị Protein cho Gymer:**\n\n'
          '• **Tăng cơ (Bulking / Lean Body):** 1.8 – 2.2g protein / kg trọng lượng cơ thể mỗi ngày.\n'
          '  *(Ví dụ: Bạn nặng 70kg thì cần khoảng 130g – 150g protein/ngày)*\n'
          '• **Giảm mỡ giữ cơ (Cutting):** 2.0 – 2.4g protein / kg để chống dị hóa cơ bắp.\n'
          '• **Người tập duy trì sức khỏe:** 1.2 – 1.6g protein / kg.\n\n'
          '💡 *Mẹo:* Hãy chia đều lượng protein thành 4-5 bữa trong ngày (mỗi bữa 25-40g) để cơ thể hấp thu tối đa quá trình tổng hợp protein cơ bắp (MPS).';
    }

    // 2. Bữa ăn trước tập (Pre-workout)
    if (text.contains('trước tập') || text.contains('pre-workout') || text.contains('ăn trước khi tập')) {
      return '⚡ **Bữa ăn lý tưởng trước buổi tập gym:**\n\n'
          '• **Thời điểm:** Ăn trước khi tập từ 1 đến 2 tiếng.\n'
          '• **Nguyên tắc:** Tập trung vào **Carbs phức hợp** (giải phóng năng lượng bền bỉ) + **Protein nạc dễ tiêu** + ít chất béo.\n\n'
          '🥗 **Gợi ý thực đơn nhanh:**\n'
          '1. 1 bát yến mạch nấu sữa chua + 1 quả chuối chín.\n'
          '2. 2 lát bánh mì nguyên cám + 2 quả trứng luộc (hoặc 100g ức gà áp chảo).\n'
          '3. 1 củ khoai lang luộc + 1 muỗng Whey Isolate.\n\n'
          '💧 *Uống đủ 300-500ml nước trước buổi tập 30 phút!*';
    }

    // 3. Bữa ăn sau tập (Post-workout)
    if (text.contains('sau tập') || text.contains('post-workout') || text.contains('ăn sau khi tập')) {
      return '🏆 **Bữa ăn phục hồi sau buổi tập gym:**\n\n'
          '• **Thời điểm vàng:** Trong vòng 30 - 60 phút sau khi kết thúc buổi tập.\n'
          '• **Mục tiêu:** Bù đắp Glycogen cạn kiệt và cung cấp Amino Acids để sửa chữa sợi cơ tổn thương.\n\n'
          '🍗 **Thực đơn vàng:**\n'
          '• **Protein hấp thu nhanh:** 1 muỗng Whey Protein hoặc 150-200g Ức gà / Phi lê cá hồi / Thăn bò.\n'
          '• **Tinh bột hấp thu nhanh:** Cơm trắng, chuối chín, khoai tây nghiền.\n'
          '• **Khoáng chất:** Bổ sung điện giải và nước lọc để chống chuột rút.';
    }

    // 4. Creatine
    if (text.contains('creatine')) {
      return '🧪 **Hướng dẫn sử dụng Creatine Monohydrate chuẩn khoa học:**\n\n'
          '• **Liều lượng:** 3g – 5g mỗi ngày (1 muỗng gạt).\n'
          '• **Thời điểm uống:** Tốt nhất là ngay **sau buổi tập** cùng với bữa ăn có carbs và protein để tăng hấp thu vào cơ bắp.\n'
          '• **Có cần giai đoạn nạp (Loading Phase) không?** Không bắt buộc. Bạn chỉ cần duy trì đều đặn 5g/ngày trong 3-4 tuần là lượng creatine trong cơ sẽ bão hòa.\n'
          '⚠️ *Lưu ý quan trọng:* Creatine hút nước vào tế bào cơ, hãy uống tối thiểu 2.5 - 3 lít nước mỗi ngày!';
    }

    // 5. Tăng cơ (Bulking)
    if (text.contains('tăng cơ') || text.contains('bulk') || text.contains('tăng cân')) {
      return '📈 **Chiến lược Bulking (Tăng cơ nạc) hiệu quả:**\n\n'
          '1. **Thặng dư Calo nhẹ:** Nạp nhiều hơn mức tiêu thụ TDEE khoảng **300 - 500 kcal/ngày** (Clean Bulk) để hạn chế tích mỡ thừa.\n'
          '2. **Tỷ lệ Macro chuẩn:**\n'
          '   • Protein: 2.0g / kg thể trọng.\n'
          '   • Carbs: 4 - 6g / kg thể trọng (Nguồn năng lượng chính để nâng tạ nặng).\n'
          '   • Chất béo tốt: 0.8 - 1g / kg thể trọng (Từ bơ sáp, dầu ô liu, các loại hạt).\n'
          '3. **Ngủ đủ 7-8 tiếng:** Cơ bắp thực sự phát triển trong giấc ngủ sâu!';
    }

    // 6. Giảm mỡ (Cutting)
    if (text.contains('giảm mỡ') || text.contains('cut') || text.contains('giảm cân') || text.contains('siết cơ')) {
      return '🔥 **Chiến lược Cutting (Giảm mỡ giữ cơ) khoa học:**\n\n'
          '1. **Thâm hụt Calo hợp lý:** Giảm **300 - 500 kcal/ngày** so với mức TDEE. Giảm cân bền vững từ 0.5 - 0.7kg/tuần.\n'
          '2. **Tăng cường Protein:** Giữ protein ở mức cao **2.0 - 2.4g / kg** để chống mất cơ khi thâm hụt năng lượng.\n'
          '3. **Chọn thực phẩm thể tích lớn (High Volume):** Tăng cường rau xanh (súp lơ, dưa leo, bắp cải) và trái cây mọng nước để no lâu mà ít calo.\n'
          '4. **Duy trì mức tạ:** Tiếp tục tập tạ nặng để ra tín hiệu cho não bộ giữ lại cơ bắp.';
    }

    // 7. Thực phẩm giàu đạm
    if (text.contains('thực phẩm giàu đạm') || text.contains('nhiều protein') || text.contains('thức ăn tăng cơ')) {
      return '🥩 **Bảng nguyên liệu giàu Protein hàng đầu cho Gymer:**\n\n'
          '• **Ức gà không da:** 31g protein / 100g (165 kcal) — Siêu nạc, tiết kiệm nhất.\n'
          '• **Thăn bò nạc:** 26g protein / 100g (142 kcal) — Giàu sắt, kẽm, creatine tự nhiên.\n'
          '• **Phi lê cá hồi:** 22g protein / 100g (208 kcal) — Giàu Omega-3 kháng viêm.\n'
          '• **Trứng gà:** 6-7g protein / quả (70 kcal) — Giá trị sinh học cao nhất.\n'
          '• **Tôm sú:** 21g protein / 100g (92 kcal) — Cực kỳ ít calo và chất béo.\n'
          '• **Đậu hũ / Đậu nành:** 12-16g protein / 100g — Nguồn đạm thực vật tuyệt vời.';
    }

    return null;
  }
}
