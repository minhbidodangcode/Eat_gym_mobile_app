import 'ingredient_normalizer.dart';
import '../../models/voice_ingredient_result.dart';

class VoiceIngredientParser {
  /// Bảng từ số tiếng Việt sang giá trị số
  static final Map<String, double> _vietnameseNumberWords = {
    'không': 0,
    'nửa': 0.5,
    'rưỡi': 0.5,
    'một': 1,
    'mốt': 1,
    'hai': 2,
    'ba': 3,
    'bốn': 4,
    'tư': 4,
    'năm': 5,
    'lăm': 5,
    'sáu': 6,
    'bảy': 7,
    'tám': 8,
    'chín': 9,
    'mười': 10,
    'chục': 10,
    'trăm': 100,
    'nghìn': 1000,
    'ngàn': 1000,
    'kí': 1000,
    'ký': 1000,
    'kg': 1000,
    'cân': 1000,
  };

  /// Ước tính khối lượng (gram) cho 1 đơn vị đếm (quả, trái, củ, hộp,...)
  static int _estimateWeightByUnit(String ingredientName, String unit) {
    final lower = ingredientName.toLowerCase();
    final u = unit.toLowerCase();

    if (u.contains('hộp') || u.contains('bịch') || u.contains('gói')) {
      if (lower.contains('sữa chua')) return 100;
      if (lower.contains('sữa')) return 200;
      if (lower.contains('đậu hũ') || lower.contains('đậu phụ')) return 200;
      return 150;
    }

    if (u.contains('muỗng') || u.contains('thìa')) {
      return 15;
    }

    if (u.contains('lát') || u.contains('miếng')) {
      if (lower.contains('bánh mì')) return 30;
      if (lower.contains('thịt')) return 50;
      return 40;
    }

    if (u.contains('bắp')) return 150;

    // Quả, trái, củ
    if (lower.contains('trứng')) return 50;
    if (lower.contains('chuối')) return 120;
    if (lower.contains('táo')) return 150;
    if (lower.contains('bơ')) return 150;
    if (lower.contains('cam')) return 150;
    if (lower.contains('xoài')) return 200;
    if (lower.contains('cà chua bi')) return 20;
    if (lower.contains('cà chua')) return 80;
    if (lower.contains('dưa leo') || lower.contains('dưa chuột')) return 100;
    if (lower.contains('khoai')) return 150;
    if (lower.contains('cà rốt')) return 100;
    if (lower.contains('hành tây')) return 100;
    if (lower.contains('chanh')) return 40;

    return 100; // Mặc định 1 quả/củ = 100g
  }

  /// Phân tích đoạn văn bản giọng nói thành danh sách VoiceIngredientResult
  static List<VoiceIngredientResult> parseSpokenText(
    String rawText, {
    List<Map<String, dynamic>>? availableIngredients,
  }) {
    if (rawText.trim().isEmpty) return [];

    String text = rawText.toLowerCase().trim();

    // 1. Loại bỏ các từ mở đầu thường gặp trong khẩu lệnh
    final removePrefixes = [
      'hôm nay tôi vừa mua',
      'hôm nay mình vừa mua',
      'hôm nay tôi mua',
      'hôm nay mình mua',
      'hôm nay mua',
      'hôm nay có',
      'hôm nay',
      'tôi vừa mua',
      'mình vừa mua',
      'vừa mua',
      'mới mua',
      'tôi mua',
      'mình mua',
      'thêm vào giỏ',
      'thêm vào kho',
      'lưu vào kho',
      'thêm cho tôi',
      'thêm cho mình',
      'cho tôi',
      'cho mình',
      'tôi có',
      'mình có',
      'thêm',
      'hãy thêm',
      'ghi nhận',
      'mua thêm',
      'mua',
      'nhập',
    ];
    for (final prefix in removePrefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
      }
    }

    // 2. Tách các phân đoạn nguyên liệu (qua từ nối: và, với, rồi, dấu phẩy,...)
    final segments = _splitSegments(text);
    final List<VoiceIngredientResult> results = [];

    for (final seg in segments) {
      final cleanSeg = seg.trim();
      if (cleanSeg.isEmpty) continue;

      final parsed = _parseSingleSegment(cleanSeg, availableIngredients);
      if (parsed != null) {
        // Tránh trùng lặp trong cùng một lần nói
        final existingIdx = results.indexWhere(
          (r) => r.name.toLowerCase() == parsed.name.toLowerCase(),
        );
        if (existingIdx >= 0) {
          results[existingIdx].weight += parsed.weight;
        } else {
          results.add(parsed);
        }
      }
    }

    return results;
  }

  /// Tách câu nói thành các phần tử nguyên liệu độc lập
  static List<String> _splitSegments(String text) {
    // Thay thế các từ nối thành ký tự phân cách chuẩn '|'
    String normalized = text
        .replaceAll(RegExp(r'(?:^|\s+)(và|với|cùng với|kèm|kèm theo|rồi|cộng|sau đó)(?:\s+|$)', caseSensitive: false), ' | ')
        .replaceAll(RegExp(r'[,;\n\+]'), ' | ');

    // Tách thêm khi có pattern số mới xuất hiện: "200g ức gà 3 quả trứng"
    // KHÔNG tách nếu từ đứng trước số là động từ hành động hoặc từ bổ trợ ("mua 300g", "thêm 200g", "khoảng 500g",...)
    final nonSplittingWords = {
      'thêm', 'mua', 'có', 'lấy', 'bổ sung', 'khoảng', 'tầm', 'được',
      'tôi', 'mình', 'hôm', 'nay', 'vừa', 'mới', 'cho', 'nạp', 'vào', 'kèm'
    };
    normalized = normalized.replaceAllMapped(
      RegExp(r'([a-zA-ZÀ-ỹ]+)\s+(\d+(?:[\.,]\d+)?\s*(g|gam|gram|kg|kí|ký|lạng|cân|quả|trái|củ|bắp|hộp|bịch))'),
      (m) {
        final prevWord = m.group(1)!.toLowerCase();
        if (nonSplittingWords.contains(prevWord)) {
          return m.group(0)!;
        }
        return '${m.group(1)} | ${m.group(2)}';
      },
    );

    return normalized
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Bóc tách một cụm đơn lẻ: ví dụ "200 gam ức gà", "nửa ký thịt bò", "3 quả trứng gà"
  static VoiceIngredientResult? _parseSingleSegment(
    String segment,
    List<Map<String, dynamic>>? availableIngredients,
  ) {
    String working = segment.trim();

    double quantity = 100; // Mặc định 100g nếu không nói khối lượng
    String unit = 'g';
    bool foundQuantity = false;

    // Pattern 1: Xử lý các cụm từ đặc biệt tiếng Việt: "nửa ký", "nửa cân", "nửa lạng", "nửa quả"
    if (working.contains('nửa ký') || working.contains('nửa cân') || working.contains('nửa kg')) {
      quantity = 500;
      unit = 'g';
      foundQuantity = true;
      working = working.replaceAll(RegExp(r'nửa\s+(ký|cân|kg)'), '').trim();
    } else if (working.contains('nửa lạng')) {
      quantity = 50;
      unit = 'g';
      foundQuantity = true;
      working = working.replaceAll(RegExp(r'nửa\s+lạng'), '').trim();
    }

    // Pattern 2: Dạng số viết rõ: "200 g", "1.5 kg", "3 quả", "2 lạng"
    if (!foundQuantity) {
      final numberRegex = RegExp(
        r'(\d+(?:[\.,]\d+)?)\s*(gam|gram|g|kg|kí|ký|cân|lạng|quả|trái|củ|bắp|hộp|bịch|gói|lát|muỗng|thìa)?(?=\s|$|[,;.])',
        caseSensitive: false,
      );

      final match = numberRegex.firstMatch(working);
      if (match != null) {
        final numStr = match.group(1)!.replaceAll(',', '.');
        final rawNum = double.tryParse(numStr) ?? 100;
        final matchedUnit = (match.group(2) ?? 'g').toLowerCase();

        quantity = _convertUnitToGrams(rawNum, matchedUnit);
        unit = 'g';
        foundQuantity = true;

        // Xóa phần số và đơn vị ra khỏi chuỗi để lấy tên nguyên liệu
        working = working.replaceFirst(match.group(0)!, '').trim();
      }
    }

    // Pattern 3: Dạng chữ số tiếng Việt: "hai trăm gam", "ba quả", "hai lạng", "một cân"
    if (!foundQuantity) {
      final wordMatch = _parseVietnameseWordsNumber(working);
      if (wordMatch != null) {
        quantity = wordMatch.grams;
        foundQuantity = true;
        working = wordMatch.remainingText;
      }
    }

    // Làm sạch tên nguyên liệu còn lại
    String ingredientQuery = working
        .replaceAll(RegExp(r'^(của|cho|thêm|loại|khoảng|tầm|tươi|nạc)\s+'), '')
        .trim();

    if (ingredientQuery.isEmpty) return null;

    // Nếu không có số lượng cụ thể và không phải là nguyên liệu hợp lệ trong từ điển, bỏ qua
    if (!foundQuantity) {
      final isKnown = IngredientNormalizer.isKnownIngredient(ingredientQuery) ||
          (availableIngredients != null &&
              availableIngredients.any((i) =>
                  IngredientNormalizer.matchesSearch((i['name'] ?? '').toString(), ingredientQuery)));
      if (!isKnown) {
        return null;
      }
    }

    // Đối chiếu với CSDL nguyên liệu
    return _matchIngredient(
      query: ingredientQuery,
      weight: quantity.round(),
      unit: unit,
      rawSpoken: segment,
      availableIngredients: availableIngredients,
    );
  }

  /// Quy đổi các đơn vị đo lường sang gram
  static double _convertUnitToGrams(double value, String unit) {
    final u = unit.toLowerCase().trim();
    if (u == 'kg' || u == 'kí' || u == 'ký' || u == 'cân') {
      return value * 1000;
    }
    if (u == 'lạng') {
      return value * 100;
    }
    if (u == 'g' || u == 'gam' || u == 'gram') {
      return value;
    }
    // Đối với đơn vị đếm (quả, trái, củ, bắp, hộp,...)
    if (['quả', 'trái', 'củ', 'bắp', 'hộp', 'bịch', 'gói', 'lát', 'muỗng', 'thìa'].contains(u)) {
      // Sẽ ước tính sau khi xác định được tên nguyên liệu
      return value * -1; // Đánh dấu là hệ số nhân đơn vị đếm (âm để phân biệt)
    }
    return value;
  }

  /// Bóc tách số bằng chữ tiếng Việt (ví dụ "hai trăm gam", "hai lạng", "ba quả")
  static _WordNumberResult? _parseVietnameseWordsNumber(String text) {
    final wordsRegex = RegExp(
      r'(?:^|\s*)(hai trăm|ba trăm|bốn trăm|năm trăm|sáu trăm|bảy trăm|tám trăm|chín trăm|hai mươi|ba mươi|bốn mươi|năm mươi|sáu mươi|bảy mươi|tám mươi|chín mươi|mười một|mười hai|mười ba|mười bốn|mười lăm|mười sáu|mười bảy|mười tám|mười chín|mười|chục|trăm|nửa|một|hai|ba|bốn|tư|năm|sáu|bảy|tám|chín)\s*(gam|gram|g|kg|kí|ký|cân|lạng|quả|trái|củ|bắp|hộp|bịch|lát|muỗng)?(?=\s|$|[,;.])',
      caseSensitive: false,
    );

    final match = wordsRegex.firstMatch(text);
    if (match != null) {
      final numberPhrase = match.group(1)!.trim();
      final unitPhrase = (match.group(2) ?? 'g').trim();

      double val = 1.0;
      if (numberPhrase.contains('trăm')) {
        final prefix = numberPhrase.replaceAll('trăm', '').trim();
        final pVal = _vietnameseNumberWords[prefix] ?? 1.0;
        val = pVal * 100;
      } else if (numberPhrase.contains('mươi')) {
        final prefix = numberPhrase.replaceAll('mươi', '').trim();
        final pVal = _vietnameseNumberWords[prefix] ?? 1.0;
        val = pVal * 10;
      } else {
        val = _vietnameseNumberWords[numberPhrase] ?? 1.0;
      }

      double grams = _convertUnitToGrams(val, unitPhrase);
      String remaining = text.replaceFirst(match.group(0)!, '').trim();

      return _WordNumberResult(grams: grams, remainingText: remaining);
    }

    return null;
  }

  /// So khớp tên nguyên liệu với CSDL & từ điển chuẩn hóa
  static VoiceIngredientResult _matchIngredient({
    required String query,
    required int weight,
    required String unit,
    required String rawSpoken,
    List<Map<String, dynamic>>? availableIngredients,
  }) {
    final qLower = query.toLowerCase().trim();

    // 1. Tìm trong danh sách CSDL động (nếu có truyền vào từ API)
    if (availableIngredients != null && availableIngredients.isNotEmpty) {
      // Khớp chính xác hoặc chứa tên
      for (final item in availableIngredients) {
        final name = (item['name'] ?? '').toString();
        if (IngredientNormalizer.matchesSearch(name, qLower) || IngredientNormalizer.matchesSearch(qLower, name)) {
          int finalWeight = weight;
          if (finalWeight < 0) {
            final count = (-finalWeight).toDouble();
            finalWeight = (_estimateWeightByUnit(item['name'].toString(), 'quả') * count).round();
          }

          return VoiceIngredientResult(
            name: item['name'].toString(),
            rawSpokenText: rawSpoken,
            icon: item['icon']?.toString() ?? '🥗',
            weight: finalWeight,
            unit: 'g',
            kcalPer100g: (item['kcalPer100g'] as num?)?.toInt() ?? 100,
            protein: ((item['protein'] as num?) ?? 10).toDouble(),
            carbs: ((item['carbs'] as num?) ?? 5).toDouble(),
            fat: ((item['fat'] as num?) ?? 3).toDouble(),
            category: item['category']?.toString() ?? 'other',
          );
        }
      }
    }

    // 2. Tìm trong IngredientNormalizer
    final details = IngredientNormalizer.getIngredientDetails(qLower);
    final standardName = details['vi']?.toString() ?? _capitalize(query);

    int finalWeight = weight;
    if (finalWeight < 0) {
      final count = (-finalWeight).toDouble();
      finalWeight = (_estimateWeightByUnit(standardName, 'quả') * count).round();
    }

    return VoiceIngredientResult(
      name: standardName,
      rawSpokenText: rawSpoken,
      icon: details['icon']?.toString() ?? '🥗',
      weight: finalWeight <= 0 ? 100 : finalWeight,
      unit: 'g',
      kcalPer100g: (details['kcal'] as num?)?.toInt() ?? 100,
      protein: ((details['protein'] as num?) ?? 10).toDouble(),
      carbs: ((details['carbs'] as num?) ?? 5).toDouble(),
      fat: ((details['fat'] as num?) ?? 3).toDouble(),
      category: details['cat']?.toString() ?? 'other',
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _WordNumberResult {
  final double grams;
  final String remainingText;

  _WordNumberResult({required this.grams, required this.remainingText});
}
