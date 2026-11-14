import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import 'cooking_timer_screen.dart';
import 'profile_screen.dart';
import 'recipe_search_screen.dart';
import 'scan_screen.dart';

enum SearchSortMode {
  relevance, // Mặc định: Phù hợp nhất theo phân cụm K-Means
  latest,    // Thời gian đăng mới nhất
  hot,       // Độ hot (Lượt thích & tương tác nhiều nhất)
}

enum IntentCategory {
  all,
  dish,
  ingredient,
  foodblog,
}

/// Thuật toán K-Means Clustering (K=3) phân loại ý định người dùng
class KMeansIntentClassifier {
  static const List<String> dishKeywords = [
    'món', 'nấu', 'xào', 'kho', 'luộc', 'canh', 'hấp', 'nướng', 'chiên', 'rán',
    'bánh', 'salad', 'pancake', 'súp', 'cháo', 'cơm', 'phở', 'bún', 'miến',
    'bữa', 'ăn sáng', 'ăn trưa', 'ăn tối', 'công thức', 'thực đơn', 'recipe', 'cook'
  ];

  static const List<String> ingredientKeywords = [
    'ức gà', 'thịt gà', 'thịt bò', 'thịt heo', 'cá hồi', 'cá thu', 'tôm', 'trứng',
    'yến mạch', 'gạo lứt', 'khoai lang', 'bơ', 'dầu ô liu', 'hạt chia', 'hạnh nhân',
    'sữa chua', 'whey', 'protein bột', 'rau bina', 'bông cải', 'măng tây', 'chuối',
    'táo', 'nguyên liệu', 'thực phẩm', 'gram', 'kg', 'calo'
  ];

  static const List<String> blogKeywords = [
    'kinh nghiệm', 'chia sẻ', 'review', 'tip', 'mẹo', 'tập luyện', 'giảm cân',
    'tăng cơ', 'giảm mỡ', 'siết cơ', 'cutting', 'bulking', 'eatclean', 'healthy',
    'bài viết', 'foodblog', 'gymer', 'hlv', 'thói quen', 'hướng dẫn', 'kỷ luật'
  ];

  static const List<String> macroKeywords = [
    'protein', 'đạm', 'carb', 'fat', 'chất béo', 'tinh bột', 'calo', 'kcal', 'macro'
  ];

  // Trọng tâm cụm (Cluster Centroids) chuẩn hóa trong không gian 4 chiều [dish, ingredient, blog, macro]
  // K = 3 cụm: 0: Món ăn, 1: Nguyên liệu, 2: FoodBlog
  static const List<List<double>> centroids = [
    [0.82, 0.25, 0.15, 0.55], // Cụm 0: Món ăn
    [0.18, 0.88, 0.10, 0.40], // Cụm 1: Nguyên liệu
    [0.20, 0.15, 0.88, 0.45], // Cụm 2: FoodBlog
  ];

  /// Trích xuất vector đặc trưng 4 chiều từ truy vấn tìm kiếm
  static List<double> extractFeatureVector(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return [0.0, 0.0, 0.0, 0.0];

    double dishScore = _calcMatchDensity(lower, dishKeywords);
    double ingrScore = _calcMatchDensity(lower, ingredientKeywords);
    double blogScore = _calcMatchDensity(lower, blogKeywords);
    double macroScore = _calcMatchDensity(lower, macroKeywords);

    // Chuẩn hóa vector
    double maxVal = [dishScore, ingrScore, blogScore, macroScore].reduce(max);
    if (maxVal > 0) {
      dishScore /= maxVal;
      ingrScore /= maxVal;
      blogScore /= maxVal;
      macroScore /= maxVal;
    }

    return [dishScore, ingrScore, blogScore, macroScore];
  }

  static double _calcMatchDensity(String text, List<String> keywords) {
    double score = 0.0;
    for (final kw in keywords) {
      if (text.contains(kw)) {
        score += 1.0;
      }
    }
    return score;
  }

  /// Tính khoảng cách Euclid giữa 2 vector
  static double _euclideanDistance(List<double> v1, List<double> v2) {
    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      final diff = v1[i] - v2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// Phân loại ý định bằng K-Means (gán điểm vào tâm cụm gần nhất)
  static Map<String, dynamic> classifyIntent(String query) {
    if (query.trim().isEmpty) {
      return {
        'category': IntentCategory.all,
        'label': 'Tổng hợp',
        'confidence': 1.0,
        'clusterIndex': -1,
      };
    }

    final vector = extractFeatureVector(query);
    double minDistance = double.infinity;
    double secondMinDistance = double.infinity;
    int bestCluster = 0;

    for (int k = 0; k < centroids.length; k++) {
      final dist = _euclideanDistance(vector, centroids[k]);
      if (dist < minDistance) {
        secondMinDistance = minDistance;
        minDistance = dist;
        bestCluster = k;
      } else if (dist < secondMinDistance) {
        secondMinDistance = dist;
      }
    }

    // Nếu khoảng cách chênh lệch không nhiều hoặc vector quá thấp
    final totalVectorEnergy = vector.reduce((a, b) => a + b);
    if (totalVectorEnergy == 0) {
      return {
        'category': IntentCategory.all,
        'label': 'Tổng hợp',
        'confidence': 0.70,
        'clusterIndex': -1,
      };
    }

    final confidence = (1.0 - (minDistance / (minDistance + secondMinDistance + 0.001))).clamp(0.65, 0.98);

    switch (bestCluster) {
      case 0:
        return {
          'category': IntentCategory.dish,
          'label': 'Món ăn & Công thức',
          'confidence': confidence,
          'clusterIndex': 0,
        };
      case 1:
        return {
          'category': IntentCategory.ingredient,
          'label': 'Nguyên liệu thể hình',
          'confidence': confidence,
          'clusterIndex': 1,
        };
      case 2:
      default:
        return {
          'category': IntentCategory.foodblog,
          'label': 'FoodBlog & Kinh nghiệm Gymer',
          'confidence': confidence,
          'clusterIndex': 2,
        };
    }
  }
}

class SearchExploreScreen extends StatefulWidget {
  const SearchExploreScreen({super.key});

  @override
  State<SearchExploreScreen> createState() => _SearchExploreScreenState();
}

class _SearchExploreScreenState extends State<SearchExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchSortMode _sortMode = SearchSortMode.relevance;
  String _selectedMacroFilter = 'Tất cả';
  String _selectedSuggestion = '';
  List<Map<String, dynamic>> _results = [];

  final List<String> _macroFilters = [
    'Tất cả',
    'High Protein (>30g)',
    'Low Carb (<20g)',
    'Calo < 500 kcal',
    'Dưới 20 phút',
  ];

  final List<String> _gymSuggestions = [
    'Ức gà',
    'Bò xào',
    'Yến mạch',
    'Salad',
    'Sinh tố whey',
    'Cá hồi',
  ];

  // Danh sách mẫu chuẩn EatGym với timestamp & lượt thích để hỗ trợ sắp xếp K-Means / Thời gian / Độ hot
  final List<Map<String, dynamic>> _mockResults = [
    {
      'id': 'mock_1',
      'title': 'Bò xào măng tây tiêu đen',
      'category': 'Món ăn',
      'calories': 420,
      'protein': 45.0,
      'carbs': 12.0,
      'fat': 10.0,
      'time': '15 phút',
      'badge': 'HIGH PROTEIN',
      'badgeColor': const Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800',
      'author': 'HLV Tuấn Anh',
      'description': 'Món ăn giàu đạm hỗ trợ phục hồi và phát triển cơ bắp tối đa sau buổi tập chân nặng.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
      'likes': 158,
    },
    {
      'id': 'mock_salmon_1',
      'title': 'Phi lê cá hồi áp chảo sốt chanh leo măng tây',
      'category': 'Món ăn',
      'calories': 450,
      'protein': 40.0,
      'carbs': 12.0,
      'fat': 22.0,
      'time': '15 phút',
      'badge': 'HIGH PROTEIN',
      'badgeColor': const Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
      'author': 'Chef Gymer Huy',
      'description': 'Cá hồi giàu Omega-3 và đạm tinh khiết, áp chảo sốt chanh leo chua ngọt thơm mềm.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      'likes': 380,
    },
    {
      'id': 'mock_salmon_2',
      'title': 'Cá hồi nướng bơ tỏi ăn kèm cơm gạo lứt',
      'category': 'FoodBlogs',
      'calories': 480,
      'protein': 42.0,
      'carbs': 38.0,
      'fat': 18.0,
      'time': '20 phút',
      'badge': 'TĂNG CƠ',
      'badgeColor': const Color(0xFFF97316),
      'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
      'author': 'Mai Linh EatClean',
      'description': 'Món cá hồi nướng giấy bạc mọng nước béo ngậy, bổ sung năng lượng sạch cho cơ bắp.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
      'likes': 295,
    },
    {
      'id': 'mock_smoothie_1',
      'title': 'Sinh tố whey protein chuối yến mạch phục hồi',
      'category': 'Món ăn',
      'calories': 320,
      'protein': 34.0,
      'carbs': 35.0,
      'fat': 4.0,
      'time': '5 phút',
      'badge': 'HIGH PROTEIN',
      'badgeColor': const Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=800',
      'author': 'HLV Tuấn Anh',
      'description': 'Smoothie phục hồi sau buổi tập, kết hợp 1 muỗng whey isolate, chuối chín và yến mạch xay mịn.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      'likes': 410,
    },
    {
      'id': 'mock_smoothie_2',
      'title': 'Sinh tố việt quất dâu tây whey protein isolate',
      'category': 'FoodBlogs',
      'calories': 280,
      'protein': 30.0,
      'carbs': 28.0,
      'fat': 3.5,
      'time': '5 phút',
      'badge': 'GIẢM MỠ',
      'badgeColor': const Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=800',
      'author': 'Minh Bi FoodBlog',
      'description': 'Sinh tố mát lạnh giàu chất chống oxy hóa, hỗ trợ siết cơ giảm mỡ cực đỉnh.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
      'likes': 365,
    },
    {
      'id': 'mock_salad_1',
      'title': 'Salad cá ngừ trứng luộc sốt giấm táo ô liu',
      'category': 'Món ăn',
      'calories': 310,
      'protein': 38.0,
      'carbs': 10.0,
      'fat': 8.0,
      'time': '10 phút',
      'badge': 'GIẢM MỠ',
      'badgeColor': const Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
      'author': 'Chef Minh',
      'description': 'Salad thanh mát với cá ngừ ngâm dầu ô liu và trứng gà luộc lòng đào thơm bùi.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 10)),
      'likes': 280,
    },
    {
      'id': 'mock_salad_2',
      'title': 'Salad thăn bò áp chảo rau mầm ngũ sắc',
      'category': 'FoodBlogs',
      'calories': 340,
      'protein': 36.0,
      'carbs': 14.0,
      'fat': 10.0,
      'time': '12 phút',
      'badge': 'HIGH PROTEIN',
      'badgeColor': const Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800',
      'author': 'Coach Nam',
      'description': 'Thịt bò thăn thái lát áp chảo vừa chín tới mềm ngọt cùng rau mầm và sốt dầu giấm.',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'likes': 320,
    },
    {
      'id': 'mock_2',
      'title': 'Yến mạch ngâm qua đêm chuối quế',
      'category': 'FoodBlogs',
      'calories': 380,
      'protein': 22.0,
      'carbs': 55.0,
      'fat': 6.0,
      'time': '5 phút',
      'badge': 'CLEAN CARB',
      'badgeColor': const Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=800',
      'author': 'Mai Linh EatClean',
      'description': 'Bữa sáng nhanh gọn nạp carb phức hợp hấp thu chậm, giữ năng lượng ổn định cả ngày.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
      'likes': 284,
    },
    {
      'id': 'mock_3',
      'title': 'Pancake chuối yến mạch protein',
      'category': 'Món ăn',
      'calories': 410,
      'protein': 32.0,
      'carbs': 48.0,
      'fat': 8.0,
      'time': '20 phút',
      'badge': 'TĂNG CƠ',
      'badgeColor': const Color(0xFFF97316),
      'image': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800',
      'author': 'Gymmer Pro',
      'description': 'Bánh pancake thơm xốp không đường bột tinh luyện, bổ sung 1 scoop whey protein isolate.',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'likes': 92,
    },
    {
      'id': 'mock_4',
      'title': 'Salad ức gà áp chảo sốt mè rang',
      'category': 'Món ăn',
      'calories': 350,
      'protein': 40.0,
      'carbs': 15.0,
      'fat': 9.0,
      'time': '15 phút',
      'badge': 'GIẢM MỠ',
      'badgeColor': const Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800',
      'author': 'Chef Minh',
      'description': 'Salad thanh đạm xé nhỏ ức gà áp chảo vừa chín tới mềm mọng, giữ nguyên hàm lượng protein.',
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'likes': 340,
    },
    {
      'id': 'mock_5',
      'title': 'Cơm gạo lứt thịt bò áp chảo măng tây',
      'category': 'Món ăn',
      'calories': 450,
      'protein': 42.0,
      'carbs': 36.0,
      'fat': 8.5,
      'time': '20 phút',
      'badge': 'TĂNG CƠ',
      'badgeColor': const Color(0xFFF97316),
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
      'author': 'Chef Gymer Huy',
      'description': 'Cơm gạo lứt thơm dẻo kết hợp bò áp chảo và măng tây giàu chất xơ và đạm chất lượng cao.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 4)),
      'likes': 415,
    },
    {
      'id': 'mock_6',
      'title': 'Ức gà cuộn măng tây sốt tiêu đen',
      'category': 'FoodBlogs',
      'calories': 360,
      'protein': 48.0,
      'carbs': 8.0,
      'fat': 6.0,
      'time': '18 phút',
      'badge': 'FOODBLOG',
      'badgeColor': const Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
      'author': 'Minh Bi FoodBlog',
      'description': 'Món ức gà cuộn giòn ngọt mọng nước, chuẩn thực đơn siết cơ giảm mỡ ít carb.',
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      'likes': 520,
    },
  ];

  @override
  void initState() {
    super.initState();
    _results = List.from(_mockResults);
    _loadApiRecipes();
  }

  Future<void> _loadApiRecipes() async {
    try {
      final recipes = await ApiService.getRecipes(limit: 3000);

      final List<Map<String, dynamic>> extraSharedPosts = [];
      try {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        for (final key in allKeys) {
          if (key.startsWith('eatgym_user_created_recipes_') || key == 'eatgym_user_recipes') {
            final str = prefs.getString(key);
            if (str != null && str.isNotEmpty) {
              final list = jsonDecode(str);
              if (list is List) {
                for (final p in list) {
                  if (p is Map) {
                    extraSharedPosts.add({
                      'id': p['id']?.toString() ?? 'blog_${DateTime.now().millisecondsSinceEpoch}',
                      'title': p['title'] ?? p['name'] ?? '',
                      'category': 'FoodBlogs',
                      'calories': (p['kcal'] is num) ? (p['kcal'] as num).round() : 350,
                      'protein': (p['protein'] is num) ? (p['protein'] as num).toDouble() : 35.0,
                      'carbs': (p['carbs'] is num) ? (p['carbs'] as num).toDouble() : 20.0,
                      'fat': (p['fat'] is num) ? (p['fat'] as num).toDouble() : 8.0,
                      'time': '${p['time'] ?? 15} phút',
                      'badge': 'FOODBLOG',
                      'badgeColor': const Color(0xFF10B981),
                      'image': RecipeImageDatabase.resolveImage(p['title'] ?? '', existingImage: p['image']),
                      'author': p['authorName'] ?? p['authorUsername'] ?? 'Gymer FoodBlog',
                      'authorAvatar': p['authorAvatar'],
                      'description': p['description'] ?? p['tips'] ?? 'Công thức nấu ăn chia sẻ từ cộng đồng Gymer.',
                      'createdAt': DateTime.now(),
                      'likes': (p['likes_count'] is num) ? (p['likes_count'] as num).toInt() : 120,
                    });
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      if (recipes.isNotEmpty && mounted) {
        setState(() {
          final apiItems = recipes.map((r) {
            final title = (r['title'] ?? r['name'] ?? 'Món ăn Gymer').toString();
            final calories = (r['kcal'] is num)
                ? (r['kcal'] as num).round()
                : ((r['calories'] is num) ? (r['calories'] as num).round() : 350);
            final protein = (r['protein'] is num)
                ? (r['protein'] as num).toDouble()
                : ((r['protein_g'] is num) ? (r['protein_g'] as num).toDouble() : 30.0);
            final carbs = (r['carbs'] is num)
                ? (r['carbs'] as num).toDouble()
                : ((r['carbs_g'] is num) ? (r['carbs_g'] as num).toDouble() : 25.0);
            final fat = (r['fat'] is num)
                ? (r['fat'] as num).toDouble()
                : ((r['fat_g'] is num) ? (r['fat_g'] as num).toDouble() : 8.0);
            
            final cookTime = r['time'] ?? r['cooking_time_min'] ?? r['cooking_time'] ?? 20;

            DateTime created = DateTime.now().subtract(Duration(hours: (r['id'] is num ? (r['id'] as num).toInt() : 2) % 48 + 1));
            if (r['created_at'] != null) {
              final parsed = DateTime.tryParse(r['created_at'].toString());
              if (parsed != null) created = parsed;
            }
            final likesCount = (r['likes_count'] is num)
                ? (r['likes_count'] as num).toInt()
                : ((r['id'] is num ? (r['id'] as num).toInt() * 17 : 45) % 250 + 20);

            // Xác định badge phù hợp theo tỷ lệ dinh dưỡng
            String badge = 'BALANCED';
            Color badgeColor = const Color(0xFF3B82F6);
            if (protein >= 35) {
              badge = 'HIGH PROTEIN';
              badgeColor = const Color(0xFF10B981);
            } else if (carbs >= 40) {
              badge = 'CLEAN CARB';
              badgeColor = const Color(0xFF6366F1);
            } else if (carbs <= 15) {
              badge = 'LOW CARB';
              badgeColor = const Color(0xFFF59E0B);
            }

            return {
              'id': r['id']?.toString() ?? '',
              'title': title,
              'category': r['meal_type'] != null && r['meal_type'].toString().isNotEmpty
                  ? (r['meal_type'] == 'breakfast' ? 'Bữa sáng' : (r['meal_type'] == 'snack' ? 'Bữa phụ' : 'Món ăn'))
                  : 'Món ăn',
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fat,
              'time': '$cookTime phút',
              'badge': badge,
              'badgeColor': badgeColor,
              'image': RecipeImageDatabase.resolveImage(title, existingImage: r['image_url'] ?? r['image']),
              'author': r['author'] ?? 'Cộng đồng EatGym',
              'description': r['description'] ?? 'Công thức chuẩn macro dinh dưỡng cho người tập thể hình.',
              'createdAt': created,
              'likes': likesCount,
            };
          }).toList();

          final List<Map<String, dynamic>> combined = [];
          if (apiItems.isNotEmpty) {
            combined.addAll(apiItems);
          }
          for (final mock in _mockResults) {
            if (!combined.any((e) => e['title'] == mock['title'])) {
              combined.add(mock);
            }
          }
          final recipeState = RecipeSearchScreen.recipeScreenKey.currentState;
          if (recipeState != null && recipeState.feedPosts.isNotEmpty) {
            for (final p in recipeState.feedPosts) {
              if (!combined.any((e) => e['title'] == p['title'])) {
                combined.add({
                  'id': p['id'] ?? 'post_${DateTime.now().millisecondsSinceEpoch}',
                  'title': p['title'] ?? '',
                  'category': 'FoodBlogs',
                  'calories': p['kcal'] ?? 350,
                  'protein': (p['protein'] ?? 30).toDouble(),
                  'carbs': (p['carbs'] ?? 20).toDouble(),
                  'fat': (p['fat'] ?? 8).toDouble(),
                  'time': '${p['time'] ?? 15} phút',
                  'badge': 'FOODBLOG',
                  'badgeColor': const Color(0xFF10B981),
                  'image': RecipeImageDatabase.resolveImage(p['title'] ?? '', existingImage: p['image']),
                  'author': p['authorName'] ?? 'Gymer Chef',
                  'authorAvatar': p['authorAvatar'],
                  'description': p['description'] ?? p['tips'] ?? '',
                  'createdAt': DateTime.now(),
                  'likes': 150,
                });
              }
            }
          }

          // Bổ sung các bài foodblog lấy từ SharedPreferences
          for (final ep in extraSharedPosts) {
            if (!combined.any((e) => e['title'] == ep['title'])) {
              combined.add(ep);
            }
          }

          // Lọc triệt để: Chỉ hiển thị công thức database + foodblog nấu ăn, loại bỏ mọi bài kinh nghiệm tập luyện không phải đồ ăn
          final foodOnly = combined.where((item) {
            final title = (item['title'] ?? '').toString().toLowerCase();
            final badge = (item['badge'] ?? '').toString().toUpperCase();
            final img = (item['image'] ?? '').toString().toLowerCase();
            final id = (item['id'] ?? '').toString();

            // Loại bỏ các công thức có ảnh không phải đồ ăn (ảnh 7: đĩa trắng, ảnh 8: sách vở/ví da, v.v.)
            if (img.contains('dia-khum') ||
                img.contains('longphuong') ||
                img.contains('vi-nam') ||
                img.contains('mediaelly') ||
                img.contains('tapchixaydung') ||
                id == '50082006-752f-4bda-bc77-0804e8d43b15' ||
                id == '30a4c578-51e4-4b50-ae7f-b44fc13d015c' ||
                id == 'd73bbde8-a6d3-4178-acdb-2083b298f7d4') {
              return false;
            }

            if (badge == 'KINH NGHIỆM' || title.contains('kinh nghiệm') || title.contains('lịch tập') || title.contains('siết cơ 8 tuần')) {
              return false;
            }
            final cal = (item['calories'] as num?)?.toDouble() ?? 0;
            return cal > 50; // Chỉ giữ món ăn thực sự có calo
          }).toList();

          _results = foodOnly.isNotEmpty ? foodOnly : List.from(_mockResults);
        });
      }
    } catch (_) {
      if (mounted && _results.isEmpty) {
        setState(() {
          _results = List.from(_mockResults);
        });
      }
    }
  }

  double _computeRelevanceScore(Map<String, dynamic> item, String query, IntentCategory intentCat) {
    double score = 0.0;
    final title = (item['title'] ?? '').toString().toLowerCase();
    final desc = (item['description'] ?? '').toString().toLowerCase();
    final author = (item['author'] ?? '').toString().toLowerCase();
    final itemCat = (item['category'] ?? '').toString();

    // 1. Phân cụm K-Means Intent Boost (+100 điểm nếu đúng tâm cụm ý định)
    if (intentCat == IntentCategory.dish && itemCat == 'Món ăn') {
      score += 100.0;
    } else if (intentCat == IntentCategory.ingredient && itemCat == 'Nguyên liệu') {
      score += 100.0;
    } else if (intentCat == IntentCategory.foodblog && itemCat == 'FoodBlogs') {
      score += 100.0;
    }

    // 2. Trùng từ khóa tiêu đề hoặc tác giả foodblog (+50 điểm)
    if (query.isNotEmpty) {
      if (title.contains(query)) {
        score += 50.0;
        if (title.startsWith(query)) score += 20.0;
      }
      if (author.contains(query)) {
        score += 60.0;
      }
    }

    // 3. Trùng trong mô tả (+15 điểm)
    if (query.isNotEmpty && desc.contains(query)) {
      score += 15.0;
    }

    // 4. Trọng số tương tác thực tế
    final likes = (item['likes'] as num?)?.toDouble() ?? 0.0;
    score += (likes / 100.0);

    return score;
  }

  String _removeDiacritics(String str) {
    const withDia = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
    const withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    String res = str.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      res = res.replaceAll(withDia[i], withoutDia[i]);
    }
    return res;
  }

  bool get _isFiltering {
    return _searchController.text.trim().isNotEmpty ||
        _selectedSuggestion.isNotEmpty ||
        _selectedMacroFilter != 'Tất cả';
  }

  List<Map<String, dynamic>> get _displayedResults {
    if (_isFiltering) {
      // Khi người dùng tìm kiếm hoặc lọc: Hiển thị đầy đủ tất cả kết quả khớp (Yêu cầu 5)
      return _filteredResults;
    }
    // Mặc định ban đầu chỉ hiển thị 30 công thức cho mượt (Yêu cầu 5)
    return _filteredResults.take(30).toList();
  }

  List<Map<String, dynamic>> get _filteredResults {
    final query = _searchController.text.trim().toLowerCase();
    final queryNormalized = _removeDiacritics(query);
    final activeQuery = query.isNotEmpty ? query : _selectedSuggestion.toLowerCase();
    final intentInfo = KMeansIntentClassifier.classifyIntent(activeQuery);
    final detectedCategory = intentInfo['category'] as IntentCategory;

    final filtered = _results.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final titleNormalized = _removeDiacritics(title);
      final author = (item['author'] ?? '').toString().toLowerCase();
      final authorNormalized = _removeDiacritics(author);
      final img = (item['image'] ?? '').toString().toLowerCase();
      final id = (item['id'] ?? '').toString();

      // Loại bỏ ảnh không phải món ăn (Ảnh 7: đĩa trắng, Ảnh 8: sách vở bút / ví da) - Yêu cầu 4
      if (img.contains('dia-khum') ||
          img.contains('longphuong') ||
          img.contains('vi-nam') ||
          img.contains('mediaelly') ||
          img.contains('tapchixaydung') ||
          id == '50082006-752f-4bda-bc77-0804e8d43b15' ||
          id == '30a4c578-51e4-4b50-ae7f-b44fc13d015c' ||
          id == 'd73bbde8-a6d3-4178-acdb-2083b298f7d4') {
        return false;
      }

      // 1. Lọc theo search input: CHỈ lọc đúng từ khóa có trong TÊN CÔNG THỨC (Title) theo yêu cầu chính xác của người dùng
      if (query.isNotEmpty) {
        final matchTitle = title.contains(query) || titleNormalized.contains(queryNormalized);
        final matchAuthor = author.contains(query) || authorNormalized.contains(queryNormalized);
        if (!matchTitle && !matchAuthor) {
          return false;
        }
      }

      // 2. Lọc theo suggestion chip: CHỈ lọc đúng từ khóa có trong TÊN CÔNG THỨC (Title) theo yêu cầu
      if (_selectedSuggestion.isNotEmpty) {
        final sug = _selectedSuggestion.toLowerCase();
        final sugNormalized = _removeDiacritics(sug);
        bool matches = false;

        if (sug == 'bò xào') {
          // Chỉ lọc đúng từ "bò xào" có trong tên công thức
          matches = title.contains('bò xào') || titleNormalized.contains('bo xao');
        } else if (sug == 'ức gà') {
          // Chỉ lọc đúng từ "ức gà" có trong tên công thức
          matches = title.contains('ức gà') || titleNormalized.contains('uc ga');
        } else if (sug == 'cá hồi') {
          // Chỉ lọc đúng từ "cá hồi" có trong tên công thức
          matches = title.contains('cá hồi') || titleNormalized.contains('ca hoi') || titleNormalized.contains('salmon');
        } else if (sug == 'sinh tố whey') {
          // Chỉ lọc đúng từ sinh tố/whey có trong tên công thức
          matches = title.contains('sinh tố') || title.contains('whey') || titleNormalized.contains('sinh to') || titleNormalized.contains('whey') || titleNormalized.contains('smoothie');
        } else if (sug == 'salad') {
          // Chỉ lọc đúng từ "salad" có trong tên công thức
          matches = title.contains('salad') || titleNormalized.contains('salad');
        } else if (sug == 'yến mạch') {
          // Chỉ lọc đúng từ "yến mạch" có trong tên công thức
          matches = title.contains('yến mạch') || titleNormalized.contains('yen mach') || titleNormalized.contains('oat');
        } else {
          matches = title.contains(sug) || titleNormalized.contains(sugNormalized);
        }
        if (!matches) return false;
      }

      // 3. Lọc theo Macro
      if (_selectedMacroFilter == 'High Protein (>30g)') {
        final protein = (item['protein'] as num?)?.toDouble() ?? 0.0;
        if (protein < 30.0) return false;
      } else if (_selectedMacroFilter == 'Low Carb (<20g)') {
        final carbs = (item['carbs'] as num?)?.toDouble() ?? 0.0;
        if (carbs >= 20.0) return false;
      } else if (_selectedMacroFilter == 'Calo < 500 kcal') {
        final calo = (item['calories'] as num?)?.toDouble() ?? 999.0;
        if (calo >= 500.0) return false;
      } else if (_selectedMacroFilter == 'Dưới 20 phút') {
        final timeStr = item['time']?.toString() ?? '';
        final minutes = int.tryParse(RegExp(r'\d+').firstMatch(timeStr)?.group(0) ?? '99') ?? 99;
        if (minutes > 20) return false;
      }

      return true;
    }).toList();

    // Sắp xếp linh hoạt theo tùy chọn: Liên quan nhất (K-Means), Mới nhất, Độ hot
    switch (_sortMode) {
      case SearchSortMode.latest:
        filtered.sort((a, b) {
          final da = a['createdAt'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b['createdAt'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        break;

      case SearchSortMode.hot:
        filtered.sort((a, b) {
          final la = (a['likes'] as num?)?.toInt() ?? 0;
          final lb = (b['likes'] as num?)?.toInt() ?? 0;
          return lb.compareTo(la);
        });
        break;

      case SearchSortMode.relevance:
        filtered.sort((a, b) {
          final scoreA = _computeRelevanceScore(a, activeQuery, detectedCategory);
          final scoreB = _computeRelevanceScore(b, activeQuery, detectedCategory);
          return scoreB.compareTo(scoreA);
        });
        break;
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadApiRecipes,
            color: primaryAccent,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. THANH TÌM KIẾM TƯƠNG TÁC (Interactive Search Input Bar - fill: #ECF5FE)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECF5FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF000000),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm công thức, món ăn, gymer...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF5B5F63),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setState(() {});
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. AI K-MEANS INTENT BADGE (Khi người dùng gõ tìm kiếm hoặc chọn gợi ý)
              if (_searchController.text.trim().isNotEmpty || _selectedSuggestion.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    child: Builder(
                      builder: (context) {
                        final activeQ = _searchController.text.trim().isNotEmpty
                            ? _searchController.text.trim()
                            : _selectedSuggestion;
                        final intentInfo = KMeansIntentClassifier.classifyIntent(activeQ);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 15),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E3A8A),
                                    ),
                                    children: [
                                      const TextSpan(text: 'AI K-Means phân loại: '),
                                      TextSpan(
                                        text: intentInfo['label'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: ' • ${(intentInfo['confidence'] * 100).toInt()}% độ chuẩn',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // 3. TÙY CHỌN SẮP XẾP: LIÊN QUAN NHẤT (MẶC ĐỊNH) | MỚI NHẤT | ĐỘ HOT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      _buildSortOption(SearchSortMode.relevance, '✨ Liên quan', isDark),
                      const SizedBox(width: 8),
                      _buildSortOption(SearchSortMode.latest, '🕒 Mới nhất', isDark),
                      const SizedBox(width: 8),
                      _buildSortOption(SearchSortMode.hot, '🔥 Độ hot', isDark),
                    ],
                  ),
                ),
              ),

              // 3. BỘ LỌC MACRO & THỜI GIAN (Macro & Time Filter Pill Badges)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _macroFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _macroFilters[index];
                      final isSelected = _selectedMacroFilter == filter;
                      return GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() {
                            _selectedMacroFilter = isSelected ? 'Tất cả' : filter;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF000000))
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E9F2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filter,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF5B5F63)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. GỢI Ý GYMER THỊNH HÀNH (Trending / Gym Suggestions)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'GỢI Ý GYMER THỊNH HÀNH',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _gymSuggestions.map((sug) {
                          final isSelected = _selectedSuggestion == sug;
                          return GestureDetector(
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _selectedSuggestion = isSelected ? '' : sug;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? Colors.white : const Color(0xFF000000))
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFECF5FE)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2)),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                sug,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. BANNER DISCOVERY HELPER (Quick Action Drawer: Bắt đầu tính Macro & Scan AI)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECF5FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFF000000),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Quét nguyên liệu AI',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScanScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : const Color(0xFF000000),
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Quét',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. THÔNG TIN SỐ LƯỢNG KẾT QUẢ (Đã xóa dòng SẮP XẾP: PHÙ HỢP Ý ĐỊNH (K-MEANS) theo Yêu cầu 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _isFiltering
                            ? '${_filteredResults.length} kết quả'
                            : 'Hiển thị ${_displayedResults.length} / ${_filteredResults.length} công thức',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 7. DANH SÁCH THẺ MÓN ĂN (Results Cards Stack)
              if (_filteredResults.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy công thức phù hợp',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _displayedResults[index];
                      return _buildRecipeCard(item, isDark);
                    },
                    childCount: _displayedResults.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSortOption(SearchSortMode mode, String label, bool isDark) {
    final isSelected = _sortMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            _sortMode = mode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : const Color(0xFF000000))
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE6EFF8)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> item, bool isDark) {
    final title = item['title'] ?? '';
    final category = (item['category'] ?? 'Món ăn').toString();
    final calories = item['calories'] ?? 350;
    final protein = item['protein'] ?? 30.0;
    final carbs = item['carbs'] ?? 20.0;
    final fat = item['fat'] ?? 8.0;
    final time = item['time'] ?? '15 phút';
    final badge = item['badge'] ?? 'FITNESS';
    final badgeColor = item['badgeColor'] as Color? ?? const Color(0xFF10B981);
    final image = item['image'] as String?;
    final likes = (item['likes'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () {
          // Mở màn hình nấu ăn Cooking Timer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CookingTimerScreen(
                recipe: {
                  'id': item['id'],
                  'title': title,
                  'calories': calories,
                  'protein': protein,
                  'carbs': carbs,
                  'fat': fat,
                  'time': 20,
                  'cooking_time_min': 20,
                },
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh món ăn
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image != null && image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              // Thông tin chi tiết
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge nhãn & Danh mục & Thời gian đăng
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Lượt tim & Thời gian
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded, size: 10, color: Color(0xFFEF4444)),
                            const SizedBox(width: 2),
                            Text(
                              '$likes',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            if (time.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              Text(
                                '• $time',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Tên món ăn
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    if (item['author'] != null && (item['author'] as String).isNotEmpty) ...[
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(
                                authorData: {
                                  'authorName': item['author'],
                                  'authorAvatar': item['authorAvatar'] ?? item['image'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                                  'authorBadge': 'Gymer Chef',
                                  'location': 'EatGym Kitchen',
                                },
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_pin_rounded, size: 13, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 3),
                            Text(
                              '${item['author']}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    // Macro tags: Calo | Protein | Carb
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildMacroPill('$calories kcal', isDark ? Colors.white70 : const Color(0xFF0F172A), isDark),
                        _buildMacroPill('${protein}g đạm', const Color(0xFF10B981), isDark),
                        _buildMacroPill('${carbs}g carb', const Color(0xFF3B82F6), isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPill(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
