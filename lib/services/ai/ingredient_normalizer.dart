class IngredientNormalizer {
  static final Map<String, Map<String, dynamic>> _dictionary = {
    // Thịt, Cá, Hải sản & Đạm (Proteins)
    "chicken": {"vi": "Ức gà không da", "icon": "🍗", "kcal": 120, "protein": 26, "carbs": 0, "fat": 1.5, "cat": "protein"},
    "chicken duck": {"vi": "Ức gà không da", "icon": "🍗", "kcal": 120, "protein": 26, "carbs": 0, "fat": 1.5, "cat": "protein"},
    "chicken breast": {"vi": "Ức gà không da", "icon": "🍗", "kcal": 120, "protein": 26, "carbs": 0, "fat": 1.5, "cat": "protein"},
    "steak": {"vi": "Thịt thăn bò nạc", "icon": "🥩", "kcal": 142, "protein": 26, "carbs": 0, "fat": 4.0, "cat": "protein"},
    "beef": {"vi": "Thịt thăn bò nạc", "icon": "🥩", "kcal": 142, "protein": 26, "carbs": 0, "fat": 4.0, "cat": "protein"},
    "pork": {"vi": "Thịt lợn nạc băm", "icon": "🥩", "kcal": 145, "protein": 21, "carbs": 0, "fat": 6.5, "cat": "protein"},
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
    "french fries": {"vi": "Khoai tây chiên giòn", "icon": "🍟", "kcal": 312, "protein": 3.4, "carbs": 41, "fat": 15.0, "cat": "carb"},
    "sweet potato": {"vi": "Khoai lang nướng", "icon": "🍠", "kcal": 140, "protein": 2.0, "carbs": 30, "fat": 1.0, "cat": "carb"},
    "coca": {"vi": "CocaCola", "icon": "🥤", "kcal": 42, "protein": 0, "carbs": 10.6, "fat": 0, "cat": "condiment"},
    "coconut water": {"vi": "Nước dừa tươi", "icon": "🥥", "kcal": 19, "protein": 0.7, "carbs": 3.7, "fat": 0.2, "cat": "carb"},
    "tomato sauce": {"vi": "Sốt cà chua", "icon": "🥫", "kcal": 29, "protein": 1.3, "carbs": 5.5, "fat": 0.2, "cat": "condiment"},
    "tomato paste": {"vi": "Tương cà chua Cholimex", "icon": "🥫", "kcal": 102, "protein": 1.2, "carbs": 24, "fat": 0.2, "cat": "condiment"},
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
    "honey": {"vi": "Mật ong nguyên chất", "icon": "🍯", "kcal": 304, "protein": 0.3, "carbs": 82.4, "fat": 0.0, "cat": "condiment"},
    "sauce": {"vi": "Nước sốt", "icon": "🥣", "kcal": 120, "protein": 1.0, "carbs": 15, "fat": 5.0, "cat": "condiment"},
    "soy sauce": {"vi": "Nước tương đậu nành thanh vị", "icon": "🥢", "kcal": 53, "protein": 8.0, "carbs": 5, "fat": 0.1, "cat": "condiment"},
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
    "pineapple": {"vi": "Dứa tươi", "icon": "🍍", "kcal": 50, "protein": 0.5, "carbs": 13, "fat": 0.1, "cat": "fruit"},
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

  /// Nhận diện emoji icon chính xác theo tên tiếng Việt của nguyên liệu
  static String detectIcon(String rawName) {
    final n = rawName.toLowerCase().trim();

    // 1. Thịt hộp các loại & Hoa quả đóng hộp
    if (n.contains('thịt bò hộp') || (n.contains('bò') && n.contains('hộp'))) return '🥫🐮';
    if (n.contains('thịt lợn hộp') || n.contains('thịt heo hộp') || (n.contains('lợn') && n.contains('hộp')) || (n.contains('heo') && n.contains('hộp'))) return '🥫🐷';
    if (n.contains('thịt gà hộp') || (n.contains('gà') && n.contains('hộp'))) return 'assets/icons/thit_lon_hop.png';
    if (n.contains('cá') && n.contains('hộp')) return '🥫🐟';
    if (n.contains('dứa đóng hộp') || n.contains('thơm hộp') || (n.contains('dứa') && n.contains('hộp'))) return '🥫🍍';
    if (n.contains('vải hộp') || (n.contains('vải') && n.contains('hộp'))) return '🥫🍒';

    // 2. Nội tạng, tim, óc, huyết, đầu
    if (n.contains('tim')) return '🫀';
    if (n.contains('óc') && !n.contains('lóc') && !n.contains('bóc') && !n.contains('chó')) return '🧠';
    if (n.contains('huyết')) return '🩸';
    if (n.contains('đầu lợn') || n.contains('đầu heo') || n.contains('tai lợn') || n.contains('tai heo')) return '🐷';
    if (n.contains('lòng') && !n.contains('trứng') && !n.contains('xanh lòng')) return '➰';
    if (n.contains('phèo') || n.contains('bao tử')) return '➰';

    // 3. Nem chua, chả, lạp xưởng, xúc xích, pate, nhộng
    if (n.contains('nem chua')) return '🫔';
    if (n.contains('chả lụa')) return '🍥';
    if (n.contains('chả quế')) return '🥮';
    if (n.contains('xúc xích')) return 'assets/icons/xuc_xich.png';
    if (n.contains('lạp xưởng') || n.contains('sausage')) return '🍢';
    if (n.contains('pa-tê') || n.contains('pate')) return '🫙';
    if (n.contains('nhộng')) return '🐛';

    // 4. Gia vị & Nước sốt
    if (n.contains('mứt đu đủ')) return 'assets/icons/mut_du_du.png';
    if (n.contains('mật ong') || n.contains('honey')) return '🍯';
    if (n.contains('tương cà') || n.contains('sốt cà chua') || n.contains('ketchup')) return 'assets/icons/tuong_ca.png';
    if (n.contains('tương ớt') || n.contains('chili sauce') || n.contains('sriracha')) return 'assets/icons/tuong_ot.png';
    if (n.contains('tương đen') || n.contains('hoisin')) return 'assets/icons/tuong_den.png';
    if (n.contains('nước tương') || n.contains('xì dầu') || n.contains('soy sauce')) return 'assets/icons/xi_dau.png';
    if (n.contains('nước mắm') || n.contains('fish sauce')) return 'assets/icons/nuoc_mam.png';
    if (n.contains('mắm tôm') || n.contains('shrimp paste')) return 'assets/icons/mam_tom.png';
    if (n.contains('giấm táo') || n.contains('apple cider')) return 'assets/icons/giam_tao.png';
    if (n.contains('cari') || n.contains('cà ri') || n.contains('curry')) return 'assets/icons/cari_bot.png';
    if (n.contains('ba khía')) return 'assets/icons/ba_khia.png';
    if (n.contains('mắm') || n.contains('muối') || n.contains('tiêu')) return '🧂';
    if (n.contains('dầu hào')) return 'assets/icons/dau_hao.png';
    if (n.contains('dầu mè')) return 'assets/icons/dau_an.png';
    if (n.contains('dầu ô liu') || n.contains('olive oil') || n.contains('dầu olive')) return 'assets/icons/dau_o_liu.png';

    if (n.contains('dầu ăn') || n.contains('dầu thực vật') || n.contains('cooking oil') || n.contains('dầu')) return 'assets/icons/dau_an.png';
    if (n.contains('sốt mayonnaise') || n.contains('sốt mè rang') || n.contains('mayo')) return 'assets/icons/sot_mayo.png';
    if (n.contains('sốt') || n.contains('nước sốt')) return '🥣';

    // 5. Đồ uống & Kẹo ngọt
    if (n.contains('nước ép dứa') || n.contains('nước thơm') || n.contains('nước dứa')) return '🍹';
    if (n.contains('coca') || n.contains('pepsi') || n.contains('nước ngọt')) return 'assets/icons/cocacola.png';
    if (n.contains('nước dừa') || n.contains('cùi dừa') || n.contains('dừa')) return '🥥';
    if (n.contains('kẹo')) return '🍬';
    if (n.contains('sữa')) return '🥛';

    // 6. Bánh, Tinh bột, Đậu hũ
    if (n.contains('đậu hũ chiên')) return 'assets/icons/dau_hu_chien.png';
    if (n.contains('đậu hũ') || n.contains('đậu phụ') || n.contains('tàu hũ') || n.contains('tofu')) return 'assets/icons/dau_phu.png';
    if (n.contains('bánh phở') || n.contains('phở')) return 'assets/icons/banh_pho.png';
    if (n.contains('bánh tráng')) return 'assets/icons/banh_trang.png';
    if (n.contains('bánh đúc')) return 'assets/icons/banh_duc.png';
    if (n.contains('bột sắn dây') || n.contains('bột sắn')) return 'assets/icons/bot_san_day.png';
    if (n.contains('củ sắn') || n.contains('khoai mì')) return 'assets/icons/cu_san.png';
    if (n.contains('củ từ')) return 'assets/icons/cu_tu.png';
    if (n.contains('khoai tây chiên')) return 'assets/icons/khoai_tay_chien.png';
    if (n.contains('khoai tây') || n.contains('potato')) return 'assets/icons/khoai_tay.png';
    if (n.contains('khoai môn') || n.contains('taro')) return 'assets/icons/khoai_mon.png';
    if (n.contains('khoai lang')) return '🍠';
    if (n.contains('khoai')) return '🍠';
    if (n.contains('gạo') || n.contains('cơm') || n.contains('nếp')) return '🍚';
    if (n.contains('yến mạch') || n.contains('quinoa') || n.contains('diêm mạch')) return '🌾';
    if (n.contains('wrap')) return 'assets/icons/banh_wrap.png';
    if (n.contains('bánh mì')) return '🥖';
    if (n.contains('bún gạo lứt')) return 'assets/icons/bun_gao_lut.png';
    if (n.contains('miến')) return 'assets/icons/mien_dong.png';
    if (n.contains('bún')) return 'assets/icons/bun.png';
    if (n.contains('hoa chuối')) return 'assets/icons/hoa_chuoi.png';
    if (n.contains('whey') || n.contains('isolate')) return 'assets/icons/whey_protein.png';
    if (n.contains('thịt lợn hộp') || n.contains('thịt heo hộp') || n.contains('spam')) return 'assets/icons/thit_lon_hop.png';
    if (n.contains('thịt bò hộp') || n.contains('bò hộp') || n.contains('corned beef')) return 'assets/icons/thit_bo_hop.png';
    if (n.contains('pate') || n.contains('pa-tê')) return 'assets/icons/pate.png';
    if (n.contains('nem chua')) return 'assets/icons/nem_chua.png';
    if (n.contains('lạp xưởng') || n.contains('lạp sườn')) return 'assets/icons/lap_xuong.png';
    if (n.contains('lươn')) return 'assets/icons/luon.png';
    if (n.contains('lòng lợn') || n.contains('lòng heo') || n.contains('phèo')) return 'assets/icons/long_lon.png';
    if (n.contains('cá trích hộp') || n.contains('cá thu hộp') || n.contains('cá ngừ hộp') || (n.contains('cá') && n.contains('hộp'))) return 'assets/icons/ca_hop.png';
    if (n.contains('phồng tôm')) return 'assets/icons/banh_phong_tom.png';
    if (n.contains('chả lụa') || n.contains('giò lụa')) return 'assets/icons/cha_lua.png';
    if (n.contains('chả quế')) return 'assets/icons/cha_que.png';
    if (n.contains('chà bông') || n.contains('ruốc thịt') || n.contains('ruốc')) return 'assets/icons/cha_bong.png';
    if (n.contains('gan gà')) return 'assets/icons/con_ga.png';
    if (n.contains('thịt vịt') || n.contains('gan vịt') || n.contains('vịt')) return 'assets/icons/con_vit.png';
    if (n.contains('chả bò')) return 'assets/icons/cha_bo.png';
    if (n.contains('gan bò') || n.contains('cật bò') || n.contains('bao tử bò') || n.contains('óc bò') || n.contains('đuôi bò')) return 'assets/icons/con_bo.png';
    if (n.contains('gan lợn') || n.contains('gan heo') || n.contains('cật lợn') || n.contains('cật heo') || n.contains('bao tử lợn') || n.contains('bao tử heo') || n.contains('óc lợn') || n.contains('óc heo')) return 'assets/icons/thit_lon.png';
    if (!n.contains('hộp') && (n.contains('thịt lợn') || n.contains('thịt heo') || n.contains('đầu lợn') || n.contains('đầu heo') || n.contains('đuôi lợn') || n.contains('đuôi heo') || n.contains('tai lợn') || n.contains('tai heo') || n.contains('sườn lợn') || n.contains('sườn non lợn') || n.contains('sườn heo') || n.contains('ba chỉ') || n.contains('ba rọi') || n.contains('giò lợn') || n.contains('giò heo') || n.contains('giò thủ') || n.contains('da lợn') || n.contains('da heo') || n.contains('dăm bông lợn') || n.contains('dăm bông heo') || n.contains('nạc heo') || n.contains('nạc lợn'))) return 'assets/icons/thit_lon.png';
    if (n.contains('mì')) return '🍜';

    // 7. Thịt & Thủy hải sản
    if (n.contains('sườn') || n.contains('giò lợn') || n.contains('giò heo')) return '🍖';
    if (n.contains('ba chỉ lợn') || n.contains('ba chỉ heo') || n.contains('thịt ba chỉ') || n.contains('bacon')) return '🥓';
    if (n.contains('thịt dê') || n.contains('dê')) return '🐐';
    if (n.contains('sôcôla') || n.contains('socola') || n.contains('chocolate')) return '🍫';
    if (n.contains('thịt thỏ') || (n.contains('thỏ') && !n.contains('thỏi'))) return '🐇';
    if (n.contains('thịt lợn') || n.contains('thịt heo') || n.contains('lợn') || n.contains('heo') || n.contains('pork')) return '🐖';
    if (n.contains('thịt bò') || n.contains('bắp bò') || n.contains('gầu bò') || n.contains('bò') || n.contains('beef') || n.contains('steak')) return 'assets/icons/con_bo.png';
    if (n.contains('chân vịt') || n.contains('cải bó xôi') || n.contains('spinach')) return 'assets/icons/cai_bo_xoi.png';
    if (n.contains('trứng vịt')) return 'assets/icons/trung_vit.png';
    if (n.contains('trứng') || n.contains('egg')) return 'assets/icons/trung_ga.png';
    if (n.contains('đậu gà') || n.contains('chickpea')) return '🫘';
    if (n.contains('thịt vịt') || n.contains('vịt')) return 'assets/icons/con_vit.png';
    if (n.contains('gà') || n.contains('chicken')) return '🍗';
    if (n.contains('hàu') || n.contains('nghêu') || n.contains('ngao') || n.contains('sò') || n.contains('hến') || n.contains('ốc')) return '🦪';
    if (n.contains('thịt') || n.contains('meat')) return '🥩';
    if (n.contains('tép') || n.contains('tôm') || n.contains('shrimp')) return '🦐';
    if (n.contains('cua') || n.contains('ghẹ') || n.contains('ba khía') || n.contains('crab')) return '🦀';
    if (n.contains('mực') || n.contains('bạch tuộc') || n.contains('squid')) return '🦑';
    if (n.contains('cá') || n.contains('lươn') || n.contains('fish')) return '🐟';

    // 8. Trứng, Bơ, Sữa, Phô mai
    if (n.contains('trứng') || n.contains('egg')) return '🥚';
    if (n.contains('phô mai') || n.contains('cheese')) return '🧀';
    if (n.contains('bơ lạt') || n.contains('bơ đậu phộng') || (n.contains('bơ') && !n.contains('sáp'))) return '🧈';

    // 9. Nấm
    if (n.contains('nấm hương') || n.contains('nấm đông cô')) return 'assets/icons/nam_huong.png';
    if (n.contains('nấm kim châm')) return 'assets/icons/nam_kim_cham.png';
    if (n.contains('nấm rơm')) return 'assets/icons/nam_rom.png';
    if (n.contains('nấm đùi gà')) return 'assets/icons/nam_dui_ga.png';
    if (n.contains('nấm')) return '🍄';

    // 10. Rau củ quả
    if (n.contains('ngó sen')) return 'assets/icons/ngo_sen.png';
    if (n.contains('măng tây')) return 'assets/icons/mang_tay.png';
    if (n.contains('bắp cải tím')) return 'assets/icons/bap_cai_tim.png';
    if (n.contains('bắp cải trắng') || (n.contains('bắp cải') && !n.contains('tím'))) return 'assets/icons/bap_cai_trang.png';
    if (n.contains('giá đỗ')) return 'assets/icons/gia_do.png';
    if (n.contains('mầm')) return '🌱';
    if (n.contains('cần tây')) return '🎋';
    if (n.contains('mướp đắng') || n.contains('khổ qua')) return '🫑';
    if (n.contains('hành lá')) return '🌿';
    if (n.contains('rong biển')) return '🪸';
    if (n.contains('rau dền')) return '🍁';
    if (n.contains('bông cải xanh') || n.contains('broccoli')) return '🥦';
    if (n.contains('cà chua') || n.contains('tomato')) return '🍅';
    if (n.contains('bắp') || n.contains('ngô') || n.contains('corn')) return '🌽';
    if (n.contains('bí đỏ') || n.contains('bí ngô') || n.contains('pumpkin')) return '🎃';
    if (n.contains('bí đao') || n.contains('bí xanh') || n.contains('dưa leo') || n.contains('dưa chuột') || n.contains('mướp')) return '🥒';
    if (n.contains('cà rốt') || n.contains('carrot')) return '🥕';
    if (n.contains('ớt chuông')) return 'assets/icons/ot_chuong.png';
    if (n.contains('ớt tươi') || n.contains('ớt')) return 'assets/icons/ot_tuoi.png';
    // Hạt & Mè đặc thù
    if (n.contains('hạnh nhân') || n.contains('almond')) return 'assets/icons/hat_hanh_nhan.png';
    if (n.contains('óc chó') || n.contains('walnut')) return 'assets/icons/hat_oc_cho.png';
    if (n.contains('hạt điều') || n.contains('cashew')) return 'assets/icons/hat_dieu.png';
    if (n.contains('mè') || n.contains('vừng') || n.contains('sesame')) return 'assets/icons/me.png';
    if (n.contains('hạt chia') || n.contains('chia')) return 'assets/icons/hat_chia.png';
    if (n.contains('hạt')) return '🌰';
    if (n.contains('bơ đậu phộng')) return '🧈';
    if (n.contains('đậu phộng') || n.contains('lạc')) return '🥜';
    if (n.contains('đậu bắp')) return '🫘';
    if (n.contains('đậu hà lan')) return '🫛';
    if (n.contains('đậu')) return '🫘';
    if (n.contains('rau') || n.contains('cải') || n.contains('xà lách') || n.contains('ngót') || n.contains('mồng tơi')) return '🥬';

    // 11. Trái cây
    if (n.contains('thanh long') || n.contains('dragon fruit') || n.contains('pitaya')) return 'assets/icons/thanh_long.png';
    if (n.contains('vải hộp') || n.contains('vải đóng hộp')) return 'assets/icons/vai_hop.png';
    if (n.contains('vải')) return '🍒';
    if (n.contains('chuối') || n.contains('banana')) return '🍌';
    if (n.contains('táo') || n.contains('apple')) return '🍎';
    if (n.contains('cam') || n.contains('orange')) return '🍊';
    if (n.contains('chanh') || n.contains('lemon')) return '🍋';
    if (n.contains('dứa đóng hộp') || n.contains('dứa hộp')) return 'assets/icons/dua_hop.png';
    if (n.contains('dứa') || n.contains('thơm') || n.contains('pineapple')) return '🍍';
    if (n.contains('dâu')) return '🍓';
    if (n.contains('dưa hấu')) return '🍉';
    if (n.contains('bơ sáp') || n.contains('avocado')) return '🥑';
    if (n.contains('xoài') || n.contains('mango')) return 'assets/icons/xoai.png';

    return '🥗';
  }

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
    final fallbackIcon = detectIcon(rawName);
    return {
      "vi": rawName,
      "icon": fallbackIcon,
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
  static String removeDiacritics(String text) {
    var result = text;
    result = result.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    result = result.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
    result = result.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    result = result.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
    result = result.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    result = result.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
    result = result.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    result = result.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
    result = result.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    result = result.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
    result = result.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    result = result.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
    result = result.replaceAll(RegExp(r'[đ]'), 'd');
    result = result.replaceAll(RegExp(r'[Đ]'), 'D');
    return result;
  }

  static bool hasDiacritics(String text) {
    return removeDiacritics(text) != text;
  }

  static List<String> tokenize(String text) {
    final s = text.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return s
        .split(RegExp(r'[\s\-\/(,) ,.:;+]+'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static bool matchesSearch(String target, String query) {
    final q = query.trim();
    if (q.isEmpty) return true;

    final tTokensRaw = tokenize(target).map((w) => w.toLowerCase()).toList();
    final qTokensRaw = tokenize(q).map((w) => w.toLowerCase()).toList();

    for (final qTok in qTokensRaw) {
      final tokHasAccent = hasDiacritics(qTok);
      bool matched = false;

      for (final tTok in tTokensRaw) {
        if (tokHasAccent) {
          if (tTok.startsWith(qTok)) {
            matched = true;
            break;
          }
        } else {
          final tClean = removeDiacritics(tTok);
          final qClean = removeDiacritics(qTok);
          if (tClean.startsWith(qClean)) {
            matched = true;
            break;
          }
        }
      }

      if (!matched) {
        return false;
      }
    }

    return true;
  }

}
