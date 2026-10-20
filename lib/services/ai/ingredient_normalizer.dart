class IngredientNormalizer {
  static final Map<String, Map<String, dynamic>> _dictionary = {
    // Thịt, Cá, Hải sản & Đạm (Proteins)
    "chicken": {"vi": "Ức gà không da", "icon": "🍗", "kcal": 120, "protein": 26, "carbs": 0, "fat": 1.5, "cat": "protein"},
    "chicken duck": {"vi": "Ức gà không da", "icon": "🍗", "kcal": 120, "protein": 26, "carbs": 0, "fat": 1.5, "cat": "protein"},
    "chicken breast": {"vi": "Ức gà không da", "icon": "🍗", "kcal": 120, "protein": 26, "carbs": 0, "fat": 1.5, "cat": "protein"},
    "steak": {"vi": "Thịt thăn bò nạc", "icon": "🥩", "kcal": 142, "protein": 26, "carbs": 0, "fat": 4.0, "cat": "protein"},
    "beef": {"vi": "Thịt thăn bò nạc", "icon": "🥩", "kcal": 142, "protein": 26, "carbs": 0, "fat": 4.0, "cat": "protein"},
    "pork": {"vi": "Thịt heo nạc băm", "icon": "🥩", "kcal": 145, "protein": 21, "carbs": 0, "fat": 6.5, "cat": "protein"},
    "fried meat": {"vi": "Thịt nạc vai", "icon": "🥩", "kcal": 180, "protein": 20, "carbs": 0, "fat": 11.0, "cat": "protein"},
    "fresh meat": {"vi": "Thịt thăn bò nạc", "icon": "🥩", "kcal": 142, "protein": 26, "carbs": 0, "fat": 4.0, "cat": "protein"},
    "lamb": {"vi": "Thịt thăn bò nạc", "icon": "🥩", "kcal": 150, "protein": 25, "carbs": 0, "fat": 5.0, "cat": "protein"},
    "sausage": {"vi": "Xúc xích ức gà", "icon": "🌭", "kcal": 160, "protein": 18, "carbs": 4, "fat": 8.0, "cat": "protein"},
    "fish": {"vi": "Phi lê cá hồi", "icon": "🐟", "kcal": 208, "protein": 22, "carbs": 0, "fat": 13.0, "cat": "protein"},
    "shrimp": {"vi": "Tôm sú bóc vỏ", "icon": "🦐", "kcal": 92, "protein": 21, "carbs": 0.5, "fat": 0.5, "cat": "protein"},
    "crab": {"vi": "Cua biển tươi", "icon": "🦀", "kcal": 87, "protein": 18, "carbs": 0, "fat": 1.0, "cat": "protein"},
    "shellfish": {"vi": "Nghêu / Sò", "icon": "🦪", "kcal": 74, "protein": 12, "carbs": 3, "fat": 1.0, "cat": "protein"},
    "egg": {"vi": "Trứng gà tươi", "icon": "🥚", "kcal": 143, "protein": 13, "carbs": 0.7, "fat": 9.5, "cat": "protein"},
    "tofu": {"vi": "Đậu hũ chiên non", "icon": "🧈", "kcal": 150, "protein": 12, "carbs": 3, "fat": 10.0, "cat": "protein"},

    // Tinh bột (Carbs)
    "rice": {"vi": "Cơm gạo lứt", "icon": "🍚", "kcal": 111, "protein": 2.6, "carbs": 23, "fat": 0.9, "cat": "carb"},
    "corn": {"vi": "Bắp ngọt tươi (Ngô)", "icon": "🌽", "kcal": 86, "protein": 3.2, "carbs": 19, "fat": 1.2, "cat": "carb"},
    "potato": {"vi": "Khoai tây", "icon": "🥔", "kcal": 77, "protein": 2.0, "carbs": 17, "fat": 0.1, "cat": "carb"},
    "pumpkin": {"vi": "Bí đỏ (Bí ngô)", "icon": "🎃", "kcal": 26, "protein": 1.0, "carbs": 6.5, "fat": 0.1, "cat": "carb"},
    "bread": {"vi": "Bánh mì baguette giòn", "icon": "🥖", "kcal": 265, "protein": 9.0, "carbs": 50, "fat": 3.2, "cat": "carb"},
    "pasta": {"vi": "Mì Ý nguyên cám Spaghetti", "icon": "🍝", "kcal": 350, "protein": 13.0, "carbs": 71, "fat": 1.5, "cat": "carb"},
    "noodles": {"vi": "Bún nưa Konjac", "icon": "🍜", "kcal": 15, "protein": 0.5, "carbs": 3.5, "fat": 0.1, "cat": "carb"},
    "wonton dumplings": {"vi": "Há cảo nhân tôm thịt", "icon": "🥟", "kcal": 180, "protein": 10, "carbs": 22, "fat": 5.0, "cat": "carb"},
    " hanamaki baozi": {"vi": "Bánh bao nguyên cám", "icon": "🥟", "kcal": 210, "protein": 8, "carbs": 38, "fat": 2.0, "cat": "carb"},
    "pie": {"vi": "Bánh nướng ngũ cốc", "icon": "🥧", "kcal": 250, "protein": 6, "carbs": 42, "fat": 6.0, "cat": "carb"},
    "biscuit": {"vi": "Bánh quy yến mạch", "icon": "🍪", "kcal": 380, "protein": 8, "carbs": 60, "fat": 12.0, "cat": "carb"},
    "french fries": {"vi": "Khoai lang nướng", "icon": "🍟", "kcal": 140, "protein": 2, "carbs": 30, "fat": 1.0, "cat": "carb"},
    "popcorn": {"vi": "Bỏng ngô nguyên vị", "icon": "🍿", "kcal": 380, "protein": 12, "carbs": 70, "fat": 4.0, "cat": "carb"},

    // Rau củ & Nấm (Vegetables & Mushrooms)
    "broccoli": {"vi": "Bông cải xanh (Broccoli)", "icon": "🥦", "kcal": 34, "protein": 2.8, "carbs": 7, "fat": 0.4, "cat": "vegetable"},
    "cauliflower": {"vi": "Súp lơ trắng", "icon": "🥦", "kcal": 25, "protein": 1.9, "carbs": 5, "fat": 0.3, "cat": "vegetable"},
    "tomato": {"vi": "Cà chua bi", "icon": "🍅", "kcal": 18, "protein": 0.9, "carbs": 3.9, "fat": 0.2, "cat": "vegetable"},
    "cucumber": {"vi": "Dưa leo (Dưa chuột)", "icon": "🥒", "kcal": 15, "protein": 0.7, "carbs": 3.6, "fat": 0.1, "cat": "vegetable"},
    "carrot": {"vi": "Cà rốt tươi", "icon": "🥕", "kcal": 41, "protein": 0.9, "carbs": 10, "fat": 0.2, "cat": "vegetable"},
    "asparagus": {"vi": "Măng tây tươi", "icon": "🌱", "kcal": 20, "protein": 2.2, "carbs": 3.9, "fat": 0.1, "cat": "vegetable"},
    "eggplant": {"vi": "Cà tím", "icon": "🍆", "kcal": 25, "protein": 1.0, "carbs": 6, "fat": 0.2, "cat": "vegetable"},
    "lettuce": {"vi": "Rau xà lách", "icon": "🥗", "kcal": 15, "protein": 1.4, "carbs": 2.9, "fat": 0.2, "cat": "vegetable"},
    "salad": {"vi": "Rau xà lách", "icon": "🥗", "kcal": 15, "protein": 1.4, "carbs": 2.9, "fat": 0.2, "cat": "vegetable"},
    "leafy greens": {"vi": "Rau xà lách", "icon": "🥗", "kcal": 15, "protein": 1.4, "carbs": 2.9, "fat": 0.2, "cat": "vegetable"},
    "cabbage": {"vi": "Bắp cải", "icon": "🥬", "kcal": 25, "protein": 1.3, "carbs": 5.8, "fat": 0.1, "cat": "vegetable"},
    " cabbage": {"vi": "Bắp cải", "icon": "🥬", "kcal": 25, "protein": 1.3, "carbs": 5.8, "fat": 0.1, "cat": "vegetable"},
    "rape": {"vi": "Cải thìa (Cải chíp)", "icon": "🥬", "kcal": 16, "protein": 1.5, "carbs": 2.2, "fat": 0.2, "cat": "vegetable"},
    "celery stick": {"vi": "Cần tây", "icon": "🥬", "kcal": 16, "protein": 0.7, "carbs": 3, "fat": 0.2, "cat": "vegetable"},
    "white radish": {"vi": "Củ cải trắng", "icon": "🥕", "kcal": 18, "protein": 0.7, "carbs": 4.1, "fat": 0.1, "cat": "vegetable"},
    "bamboo shoots": {"vi": "Măng tươi", "icon": "🎋", "kcal": 27, "protein": 2.6, "carbs": 5.2, "fat": 0.3, "cat": "vegetable"},
    "okra": {"vi": "Đậu bắp", "icon": "🫛", "kcal": 33, "protein": 1.9, "carbs": 7.5, "fat": 0.2, "cat": "vegetable"},
    "snow peas": {"vi": "Đậu Hà lan (hạt)", "icon": "🫛", "kcal": 42, "protein": 2.8, "carbs": 7.6, "fat": 0.2, "cat": "vegetable"},
    "green beans": {"vi": "Đậu cove tươi", "icon": "🫘", "kcal": 31, "protein": 1.8, "carbs": 7, "fat": 0.2, "cat": "vegetable"},
    "french beans": {"vi": "Đậu cove tươi", "icon": "🫘", "kcal": 31, "protein": 1.8, "carbs": 7, "fat": 0.2, "cat": "vegetable"},
    "bean sprouts": {"vi": "Giá đỗ tươi", "icon": "🌱", "kcal": 30, "protein": 3.0, "carbs": 4, "fat": 0.2, "cat": "vegetable"},
    "kelp": {"vi": "Rong biển Kombu", "icon": "🌿", "kcal": 43, "protein": 1.7, "carbs": 9.6, "fat": 0.6, "cat": "vegetable"},
    "seaweed": {"vi": "Rong biển tươi", "icon": "🌿", "kcal": 45, "protein": 2.0, "carbs": 9.0, "fat": 0.6, "cat": "vegetable"},
    "enoki mushroom": {"vi": "Nấm kim châm", "icon": "🍄", "kcal": 37, "protein": 2.7, "carbs": 7.8, "fat": 0.3, "cat": "vegetable"},
    "shiitake": {"vi": "Nấm hương (Đông cô)", "icon": "🍄", "kcal": 34, "protein": 2.2, "carbs": 6.8, "fat": 0.5, "cat": "vegetable"},
    "king oyster mushroom": {"vi": "Nấm đùi gà", "icon": "🍄", "kcal": 35, "protein": 3.0, "carbs": 5, "fat": 0.3, "cat": "vegetable"},
    "oyster mushroom": {"vi": "Nấm bào ngư (Nấm sò)", "icon": "🍄", "kcal": 33, "protein": 3.3, "carbs": 6, "fat": 0.4, "cat": "vegetable"},
    "white button mushroom": {"vi": "Nấm mỡ trắng", "icon": "🍄", "kcal": 22, "protein": 3.1, "carbs": 3.3, "fat": 0.3, "cat": "vegetable"},
    "button mushroom": {"vi": "Nấm mỡ trắng", "icon": "🍄", "kcal": 22, "protein": 3.1, "carbs": 3.3, "fat": 0.3, "cat": "vegetable"},

    // Gia vị & Rau thơm (Condiments & Herbs)
    "garlic": {"vi": "Tỏi băm tươi", "icon": "🧄", "kcal": 149, "protein": 6.4, "carbs": 33, "fat": 0.5, "cat": "condiment"},
    "ginger": {"vi": "Gừng tươi băm", "icon": "🫚", "kcal": 80, "protein": 1.8, "carbs": 18, "fat": 0.8, "cat": "condiment"},
    "onion": {"vi": "Hành tây", "icon": "🧅", "kcal": 40, "protein": 1.1, "carbs": 9.3, "fat": 0.1, "cat": "condiment"},
    "yellow onion": {"vi": "Hành tây", "icon": "🧅", "kcal": 40, "protein": 1.1, "carbs": 9.3, "fat": 0.1, "cat": "condiment"},
    "red onion": {"vi": "Hành tím khô", "icon": "🧅", "kcal": 40, "protein": 1.2, "carbs": 9.0, "fat": 0.1, "cat": "condiment"},
    "white onion": {"vi": "Hành tây", "icon": "🧅", "kcal": 40, "protein": 1.1, "carbs": 9.3, "fat": 0.1, "cat": "condiment"},
    "spring onion": {"vi": "Hành lá", "icon": "🌿", "kcal": 32, "protein": 1.8, "carbs": 7.3, "fat": 0.2, "cat": "condiment"},
    "cilantro mint": {"vi": "Rau mùi (Ngò rí)", "icon": "🌿", "kcal": 23, "protein": 2.1, "carbs": 3.7, "fat": 0.5, "cat": "condiment"},
    "pepper": {"vi": "Tiêu đen Phú Quốc xay", "icon": "🧂", "kcal": 251, "protein": 10.4, "carbs": 64, "fat": 3.3, "cat": "condiment"},
    "sauce": {"vi": "Nước tương đậu nành thanh vị", "icon": "🥢", "kcal": 53, "protein": 8.0, "carbs": 5, "fat": 0.1, "cat": "condiment"},
    "soup": {"vi": "Nước dùng hầm xương", "icon": "🍲", "kcal": 35, "protein": 3.5, "carbs": 1, "fat": 1.5, "cat": "condiment"},

    // Trái cây (Fruits)
    "apple": {"vi": "Táo tươi", "icon": "🍎", "kcal": 52, "protein": 0.3, "carbs": 14, "fat": 0.2, "cat": "fruit"},
    "banana": {"vi": "Chuối chín", "icon": "🍌", "kcal": 89, "protein": 1.1, "carbs": 23, "fat": 0.3, "cat": "fruit"},
    "avocado": {"vi": "Bơ sáp", "icon": "🥑", "kcal": 160, "protein": 2.0, "carbs": 8.5, "fat": 14.7, "cat": "fruit"},
    "orange": {"vi": "Cam tươi", "icon": "🍊", "kcal": 47, "protein": 0.9, "carbs": 12, "fat": 0.1, "cat": "fruit"},
    "lemon": {"vi": "Nước cốt chanh tươi", "icon": "🍋", "kcal": 25, "protein": 0.4, "carbs": 8, "fat": 0.1, "cat": "fruit"},
    "watermelon": {"vi": "Dưa hấu", "icon": "🍉", "kcal": 30, "protein": 0.6, "carbs": 7.6, "fat": 0.2, "cat": "fruit"},
    "mango": {"vi": "Xoài cát chín", "icon": "🥭", "kcal": 60, "protein": 0.8, "carbs": 15, "fat": 0.4, "cat": "fruit"},
    "grape": {"vi": "Nho tươi", "icon": "🍇", "kcal": 69, "protein": 0.7, "carbs": 18, "fat": 0.2, "cat": "fruit"},
    "strawberry": {"vi": "Dâu tây", "icon": "🍓", "kcal": 32, "protein": 0.7, "carbs": 7.7, "fat": 0.3, "cat": "fruit"},
    "blueberry": {"vi": "Việt quất", "icon": "🫐", "kcal": 57, "protein": 0.7, "carbs": 14.5, "fat": 0.3, "cat": "fruit"},
    "pineapple": {"vi": "Dứa (Thơm)", "icon": "🍍", "kcal": 50, "protein": 0.5, "carbs": 13, "fat": 0.1, "cat": "fruit"},
    "kiwi": {"vi": "Kiwi tươi", "icon": "🥝", "kcal": 61, "protein": 1.1, "carbs": 15, "fat": 0.5, "cat": "fruit"},
    "peach": {"vi": "Đào tươi", "icon": "🍑", "kcal": 39, "protein": 0.9, "carbs": 9.5, "fat": 0.3, "cat": "fruit"},
    "pear": {"vi": "Lê tươi", "icon": "🍐", "kcal": 57, "protein": 0.4, "carbs": 15, "fat": 0.1, "cat": "fruit"},
    "cherry": {"vi": "Anh đào (Cherry)", "icon": "🍒", "kcal": 63, "protein": 1.1, "carbs": 16, "fat": 0.2, "cat": "fruit"},
    "raspberry": {"vi": "Mâm xôi", "icon": "🍇", "kcal": 52, "protein": 1.2, "carbs": 12, "fat": 0.7, "cat": "fruit"},
    "melon": {"vi": "Dưa lưới", "icon": "🍈", "kcal": 34, "protein": 0.8, "carbs": 8.2, "fat": 0.2, "cat": "fruit"},
    "date": {"vi": "Táo tàu / Chà là", "icon": "🫒", "kcal": 282, "protein": 2.5, "carbs": 75, "fat": 0.4, "cat": "fruit"},
    "apricot": {"vi": "Mơ tươi", "icon": "🍑", "kcal": 48, "protein": 1.4, "carbs": 11, "fat": 0.4, "cat": "fruit"},
    "fig": {"vi": "Quả sung / Quả vả", "icon": "🫐", "kcal": 74, "protein": 0.8, "carbs": 19, "fat": 0.3, "cat": "fruit"},
    "olives": {"vi": "Quả ô liu", "icon": "🫒", "kcal": 115, "protein": 0.8, "carbs": 6.3, "fat": 10.7, "cat": "fat"},

    // Hạt & Sữa (Nuts & Dairy)
    "milk": {"vi": "Sữa tươi không đường", "icon": "🥛", "kcal": 60, "protein": 3.2, "carbs": 4.8, "fat": 3.3, "cat": "dairy"},
    "cheese butter": {"vi": "Phô mai / Bơ", "icon": "🧀", "kcal": 350, "protein": 20, "carbs": 2.0, "fat": 30.0, "cat": "dairy"},
    "almond": {"vi": "Hạnh nhân", "icon": "🌰", "kcal": 579, "protein": 21, "carbs": 22, "fat": 50.0, "cat": "fat"},
    "cashew": {"vi": "Hạt điều", "icon": "🌰", "kcal": 553, "protein": 18, "carbs": 30, "fat": 44.0, "cat": "fat"},
    "walnut": {"vi": "Quả óc chó", "icon": "🌰", "kcal": 654, "protein": 15, "carbs": 14, "fat": 65.0, "cat": "fat"},
    "peanut": {"vi": "Đậu phộng (Lạc)", "icon": "🥜", "kcal": 567, "protein": 25.8, "carbs": 16, "fat": 49.0, "cat": "fat"},
    "soy": {"vi": "Đậu nành (hạt)", "icon": "🫘", "kcal": 446, "protein": 36, "carbs": 30, "fat": 20.0, "cat": "protein"},
    "red beans": {"vi": "Đậu đỏ (hạt)", "icon": "🫘", "kcal": 333, "protein": 24, "carbs": 60, "fat": 1.0, "cat": "carb"},
    "dried cranberries": {"vi": "Nam việt quất sấy", "icon": "🫐", "kcal": 308, "protein": 0.5, "carbs": 82, "fat": 1.4, "cat": "fruit"},
  };

  /// Ánh xạ tên tiếng Anh hoặc nhãn của YOLO về tên nguyên liệu tiếng Việt chuẩn trong CSDL EatGym
  static String normalizeToVietnamese(String rawName) {
    final key = rawName.toLowerCase().trim();
    if (_dictionary.containsKey(key)) {
      return _dictionary[key]!["vi"] as String;
    }
    // Tìm kiếm một phần (partial match)
    for (final entry in _dictionary.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value["vi"] as String;
      }
    }
    return rawName;
  }

  /// Lấy toàn bộ thông tin dinh dưỡng, icon của nguyên liệu
  static Map<String, dynamic> getIngredientDetails(String rawName) {
    final key = rawName.toLowerCase().trim();
    if (_dictionary.containsKey(key)) {
      return Map<String, dynamic>.from(_dictionary[key]!);
    }
    // 1. Khớp theo tên tiếng Việt
    for (final entry in _dictionary.entries) {
      final vi = (entry.value["vi"] as String? ?? '').toLowerCase();
      if (vi == key || vi.contains(key) || key.contains(vi)) {
        return Map<String, dynamic>.from(entry.value);
      }
    }
    // 2. Khớp theo key tiếng Anh
    for (final entry in _dictionary.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return Map<String, dynamic>.from(entry.value);
      }
    }
    return {
      "vi": rawName,
      "icon": "🥗",
      "kcal": 100,
      "protein": 10,
      "carbs": 10,
      "fat": 2,
      "cat": "other"
    };
  }

  /// Kiểm tra xem một chuỗi có phải là nguyên liệu thực phẩm hợp lệ trong từ điển không
  static bool isKnownIngredient(String rawName) {
    final key = rawName.toLowerCase().trim();
    if (key.isEmpty) return false;
    if (_dictionary.containsKey(key)) return true;

    for (final entry in _dictionary.entries) {
      final vi = (entry.value["vi"] as String? ?? '').toLowerCase();
      if (vi == key || vi.contains(key) || key.contains(vi)) {
        return true;
      }
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return true;
      }
    }
    return false;
  }

  /// Tương thích ngược với code cũ
  static String normalize(String ingredient) {
    return normalizeToVietnamese(ingredient);
  }
}
