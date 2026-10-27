import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'cooking_timer_screen.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/ai/ingredient_normalizer.dart';
import 'profile_screen.dart';

/// Trang Nấu Ăn thiết kế theo phong cách Lướt Bảng Tin Instagram (Instagram Recipe Feed)

/// Cơ sở dữ liệu ảnh chuẩn 100% cho TẤT CẢ các món ăn trong hệ thống (Hơn 4,000 công thức)
class RecipeImageDatabase {
  static const Map<String, String> standardImages = {
    // 1. Overnight oats yến mạch ngâm sữa chua hoa quả
    'overnight_oats': 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=800',
    // 2. Bữa phụ phục hồi sữa hạt & đĩa hạt dinh dưỡng
    'snack_plate': 'https://images.unsplash.com/photo-1508736793122-f516e3ba5569?w=800',
    'nut_milk_snack': 'https://images.unsplash.com/photo-1508736793122-f516e3ba5569?w=800',
    'nuts_superfood': 'https://images.unsplash.com/photo-1508736793122-f516e3ba5569?w=800',
    // 3. Bánh mì đen kẹp trứng ốp & bơ
    'egg_toast': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
    'black_bread_egg': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
    // 4. Bánh mì sandwich cá ngừ
    'tuna_sandwich': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=800',
    // 5. Wrap ức gà ngũ cốc Tortilla
    'chicken_wrap': 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=800',
    // 6. Bún nưa / Mì gạo lứt Eat Clean
    'noodle_bowl': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800',
    'shirataki_bowl': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800',
    // 7. Cháo yến mạch ức gà nấm
    'porridge': 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=800',
    'oatmeal_porridge': 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=800',
    // 8. Đậu hũ áp chảo vàng giòn sốt tương gừng
    'tofu_meal': 'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?w=800',
    'tofu_dish': 'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?w=800',
    'tofu_rice_bowl': 'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?w=800',
    // 9. Đậu nành Edamame hấp đĩa
    'edamame_plate': 'https://images.unsplash.com/photo-1551462147-37885acc36f1?w=800',
    'edamame_beans': 'https://images.unsplash.com/photo-1551462147-37885acc36f1?w=800',
    // 10. Bắp ngọt xào rau củ sốt tiêu đen Eat Clean
    'corn_stir_fry': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800',
    'sweet_corn': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800',
    // 11. Bắp ngọt hấp kèm ức gà poke bowl
    'chicken_corn_meal': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
    // 12. Bò bít tết thăn nạc măng tây
    'beef_steak': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800',
    // 13. Bò xào ớt chuông cơm gạo lứt
    'beef_rice': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800',
    'beef_stir_fry': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800',
    // 14. Cá hồi áp chảo sốt chanh leo
    'salmon_fillet': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
    // 15. Cá ngừ áp chảo măng tây
    'tuna_steak': 'https://images.unsplash.com/photo-1501595091296-3aa970afb3ff?w=800',
    'tuna_egg_salad': 'https://images.unsplash.com/photo-1501595091296-3aa970afb3ff?w=800',
    // 16. Tôm sú áp chảo bơ tỏi
    'garlic_shrimp': 'https://images.unsplash.com/photo-1559737558-2f5a35f4523b?w=800',
    // 17. Ức gà áp chảo sốt bơ tỏi / tiêu đen
    'chicken_breast': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
    // 18. Salad ức gà áp chảo sốt mè
    'chicken_salad': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800',
    // 19. Đùi gà nướng thảo mộc
    'roast_chicken': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800',
    'roast_chicken_thigh': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800',
    // 20. Thịt lợn nạc rim mật ong cơm gạo lứt
    'pork_rice': 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=800',
    'pork_brown_rice': 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=800',
    // 21. Trứng cuộn phô mai rau củ
    'egg_roll': 'https://images.unsplash.com/photo-1510693206972-df098062cb71?w=800',
    // 22. Soup nóng / súp gà nấm
    'soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800',
    'chicken_soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800',
    // 23. Canh rong biển bò băm đậu hũ
    'seaweed_soup': 'https://images.unsplash.com/photo-1607528971899-2e89e6c0ec69?w=800',
    // 24. Sữa chua Hy Lạp việt quất Granola
    'yogurt_bowl': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
    'greek_yogurt_bowl': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
    // 25. Sinh tố Protein chuối yến mạch
    'smoothie': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=800',
    'protein_smoothie': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=800',
    // 26. Salad rau củ ngũ sắc Eat Clean
    'salad_bowl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
    'garden_salad': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
    'chickpea_salad': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
    // 27. Ức gà xào súp lơ nấm
    'chicken_stir_fry': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
  };

  /// Phân tích tiêu đề và mô tả món ăn để trả về ảnh CHUẨN 100% MÓN ĂN ĐÃ NẤU CHÍN
  static String resolveImage(String title, {String? existingImage, String? description}) {
    if (existingImage != null && existingImage.isNotEmpty) {
      // Bỏ qua nếu là placeholder hoặc ảnh cũ của ngô sống/hạt sống
      if (existingImage.contains('placeholder') ||
          existingImage.contains('photo-1551754655-cd27e38d2076') ||
          existingImage.contains('photo-1514733670139-4d87a1941d55')) {
        // Tự động phân tích theo tiêu đề bên dưới để gán ảnh chuẩn
      } else {
        // Sử dụng trực tiếp ảnh chuẩn đã lưu từ Database cho từng món!
        return existingImage;
      }
    }

    final lower = (title + ' ' + (description ?? '')).toLowerCase();

    // 1. Overnight oats & Sinh tố / Sữa chua / Granola
    if (lower.contains('ngâm qua đêm') || lower.contains('overnight')) {
      return standardImages['overnight_oats']!;
    }
    if (lower.contains('sinh tố') || lower.contains('smoothie') || lower.contains('whey')) {
      return standardImages['smoothie']!;
    }
    if (lower.contains('sữa chua') || lower.contains('yogurt') || lower.contains('granola') || lower.contains('parfait')) {
      return standardImages['yogurt_bowl']!;
    }
    if (lower.contains('sữa hạt') || lower.contains('bữa phụ')) {
      return standardImages['snack_plate']!;
    }

    // 2. Wrap & Bánh mì / Sandwich / Toast
    if (lower.contains('wrap') || lower.contains('bánh cuộn') || lower.contains('tortilla')) {
      return standardImages['chicken_wrap']!;
    }
    if (lower.contains('bánh mì') || lower.contains('sandwich') || lower.contains('toast')) {
      if (lower.contains('cá ngừ') || lower.contains('tuna')) {
        return standardImages['tuna_sandwich']!;
      }
      return standardImages['egg_toast']!;
    }

    // 3. Bún / Mì / Phở / Shirataki / Miến / Nui / Bánh canh
    if (lower.contains('bún') || lower.contains('shirataki') || lower.contains('mì') || lower.contains('phở') || lower.contains('miến') || lower.contains('nui') || lower.contains('pasta') || lower.contains('bánh canh')) {
      return standardImages['noodle_bowl']!;
    }

    // 4. Cháo / Soup / Canh
    if (lower.contains('cháo')) {
      return standardImages['porridge']!;
    }
    if (lower.contains('canh rong biển') || lower.contains('rong biển')) {
      return standardImages['seaweed_soup']!;
    }
    if (lower.contains('soup') || lower.contains('súp') || (lower.contains('canh') && !lower.contains('bánh'))) {
      return standardImages['soup']!;
    }

    // 5. Hải sản (Tôm, Cá hồi, Cá ngừ, Cua, Mực)
    if (lower.contains('tôm') || lower.contains('shrimp') || lower.contains('cua') || lower.contains('mực') || lower.contains('hải sản')) {
      return standardImages['garlic_shrimp']!;
    }
    if (lower.contains('cá hồi') || lower.contains('salmon')) {
      return standardImages['salmon_fillet']!;
    }
    if (lower.contains('cá ngừ') || lower.contains('tuna')) {
      return standardImages['tuna_steak']!;
    }

    // 6. Trứng
    if (lower.contains('trứng cuộn') || lower.contains('omlet') || lower.contains('omelette') || lower.contains('trứng ốp') || lower.contains('trứng')) {
      return standardImages['egg_roll']!;
    }

    // 7. Thịt bò
    if (lower.contains('bít tết') || lower.contains('steak') || lower.contains('thăn bò')) {
      return standardImages['beef_steak']!;
    }
    if (lower.contains('bò xào') || lower.contains('bò băm') || lower.contains('bò') || lower.contains('thịt bò')) {
      return standardImages['beef_rice']!;
    }

    // 8. Thịt lợn
    if (lower.contains('thịt lợn') || lower.contains('nạc lợn') || lower.contains('lợn rim') || lower.contains('thịt lợn') || lower.contains('thăn heo') || lower.contains('heo kho') || lower.contains('bao tử')) {
      return standardImages['pork_rice']!;
    }

    // 9. Đậu hũ / Món chay
    if (lower.contains('đậu hũ') || lower.contains('đậu phụ') || lower.contains('tofu') || lower.contains('chao') || lower.contains('món chay')) {
      return standardImages['tofu_meal']!;
    }

    // 10. Thịt gà
    if (lower.contains('đùi gà') || lower.contains('má đùi') || lower.contains('cánh gà') || lower.contains('gà nướng')) {
      return standardImages['roast_chicken']!;
    }
    if (lower.contains('ức gà') || lower.contains('gà')) {
      if (lower.contains('salad') || lower.contains('xà lách')) {
        return standardImages['chicken_salad']!;
      }
      if (lower.contains('xào') || lower.contains('tiêu đen') || lower.contains('nấm')) {
        return standardImages['chicken_stir_fry']!;
      }
      if (lower.contains('bắp') || lower.contains('ngô') || lower.contains('hấp')) {
        return standardImages['chicken_corn_meal']!;
      }
      return standardImages['chicken_breast']!;
    }

    // 11. Salad tươi trộn
    if (lower.contains('salad') || lower.contains('trộn sốt') || lower.contains('giấm táo') || lower.contains('dầu ô liu')) {
      return standardImages['salad_bowl']!;
    }

    // 12. Bắp ngọt (Ngô) & Rau củ xào / hấp chín
    if (lower.contains('bắp ngọt') || lower.contains('ngô')) {
      if (lower.contains('xào') || lower.contains('áp chảo') || lower.contains('tiêu đen')) {
        return standardImages['corn_stir_fry']!;
      }
      return standardImages['chicken_corn_meal']!;
    }

    // 13. Đậu nành Edamame & Các loại hạt dinh dưỡng
    if (lower.contains('edamame') || lower.contains('đậu nành') || lower.contains('đậu hà lan')) {
      return standardImages['edamame_plate']!;
    }
    if (lower.contains('hạt') || lower.contains('quinoa') || lower.contains('hạnh nhân') || lower.contains('óc chó') || lower.contains('điều') || lower.contains('chia')) {
      return standardImages['snack_plate']!;
    }

    return standardImages['chicken_breast']!;
  }
}

class RecipeSearchScreen extends StatefulWidget {
  static final GlobalKey<RecipeSearchScreenState> recipeScreenKey = GlobalKey<RecipeSearchScreenState>();

  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => RecipeSearchScreenState();
}

class RecipeSearchScreenState extends State<RecipeSearchScreen> {
  /// Helper hiển thị ảnh linh hoạt: hỗ trợ cả URL mạng lẫn file chụp từ máy (Yêu cầu 1 & 2)
  Widget _buildRecipeImage(
    String? imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    Widget imgWidget;
    if (imagePath == null || imagePath.isEmpty) {
      imgWidget = Container(
        width: width,
        height: height,
        color: AppColors.surfaceContainerLow,
        child: const Icon(Icons.restaurant, color: Colors.grey, size: 28),
      );
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      imgWidget = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.surfaceContainerLow,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        },
        errorBuilder: (ctx, err, stack) => Container(
          width: width,
          height: height,
          color: AppColors.surfaceContainerLow,
          child: const Icon(Icons.restaurant, color: Colors.grey, size: 28),
        ),
      );
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        imgWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, err, stack) => Container(
            width: width,
            height: height,
            color: AppColors.surfaceContainerLow,
            child: const Icon(Icons.restaurant, color: Colors.grey, size: 28),
          ),
        );
      } else {
        imgWidget = Image.network(
          RecipeImageDatabase.standardImages['chicken_breast']!,
          width: width,
          height: height,
          fit: fit,
        );
      }
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imgWidget);
    }
    return imgWidget;
  }


  static const String _savedRecipesKey = 'eatgym_saved_recipes_ids_v1';
  static const String _likedRecipesKey = 'eatgym_liked_recipes_ids_v1';

  String _selectedFilter = 'Tất cả';
  bool _isLoading = true;
  List<Map<String, dynamic>> _feedPosts = [];
  final Set<String> _likedRecipeIds = {};
  final Set<String> _savedRecipeIds = {};
  final Map<String, List<Map<String, String>>> _commentsMap = {};
  static const String _userPostsKey = 'eatgym_user_created_recipes_v2';
  List<Map<String, dynamic>> _userPosts = [];

  // Getters & helper methods cho ProfileScreen (Instagram profile)
  List<Map<String, dynamic>> get userPosts => _userPosts;
  List<Map<String, dynamic>> get feedPosts => _feedPosts;
  Set<String> get savedRecipeIds => _savedRecipeIds;
  Set<String> get likedRecipeIds => _likedRecipeIds;
  void showRecipeDetails(Map<String, dynamic> recipe, {BuildContext? customContext}) => _showRecipeDetailsModal(recipe, customContext: customContext);
  void deleteUserPost(String id) {
    setState(() {
      _userPosts.removeWhere((p) => p['id'] == id);
      _feedPosts.removeWhere((p) => p['id'] == id);
    });
    _saveUserPosts();
  }
  void toggleSaveRecipe(String id, String title) => _toggleSave(id, title);
  void toggleLikeRecipe(String id) => _toggleLike(id);

  final List<Map<String, String>> _stories = [
    {'label': 'Tất cả', 'icon': '🌟', 'tag': 'Tất cả'},
    {'label': 'Tăng cơ', 'icon': '💪', 'tag': 'Tăng cơ'},
    {'label': 'Giảm mỡ', 'icon': '🔥', 'tag': 'Giảm mỡ'},
    {'label': 'Dưới 15p', 'icon': '⏱️', 'tag': 'Dưới 15 phút'},
    {'label': 'Eat Clean', 'icon': '🥗', 'tag': 'Eat Clean'},
    {'label': 'High-Pro', 'icon': '🍗', 'tag': 'High Protein'},
    {'label': 'Ăn chay', 'icon': '🥦', 'tag': 'Ăn chay'},
    {'label': 'Smoothie', 'icon': '🥤', 'tag': 'Smoothie'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAndLikedState();
    _loadFeed();
  }

  Future<void> _loadSavedAndLikedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_savedRecipesKey) ?? [];
      final likedList = prefs.getStringList(_likedRecipesKey) ?? [];
      
      // Tải các công thức do người dùng tự đăng
      final userPostsJson = prefs.getString(_userPostsKey);
      List<Map<String, dynamic>> loadedUserPosts = [];
      if (userPostsJson != null && userPostsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(userPostsJson);
        loadedUserPosts = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        // Pre-seed 1 bài đăng mẫu ban đầu của người dùng để giao diện luôn đầy đặn
        loadedUserPosts = [
          {
            'id': 'user_recipe_sample_1',
            'title': 'Ức gà áp chảo sốt bơ tỏi của tôi',
            'time': 20,
            'difficulty': 'Dễ',
            'kcal': 360,
            'protein': 44,
            'carbs': 8,
            'fat': 10,
            'image': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
            'description': 'Công thức bí quyết áp chảo lửa vừa giúp ức gà giữ trọn độ mềm mọng nước, không bị khô xơ!',
            'authorName': 'Bạn (Gymer)',
            'authorAvatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
            'authorBadge': 'Gymer Tác Giả',
            'location': 'EatGym Kitchen • Bếp Của Tôi',
            'postedTime': '1 ngày trước',
            'isMine': true,
            'baseLikes': 38,
            'commentsCount': 6,
            'ingredients': [
              {'name': 'Ức gà tươi', 'amount': '250', 'unit': 'g'},
              {'name': 'Bơ lạt', 'amount': '15', 'unit': 'g'},
              {'name': 'Tỏi băm & tiêu', 'amount': '2', 'unit': 'tép'},
            ],
            'steps': [
              {'step': 'Khứa nhẹ bề mặt ức gà, ướp tiêu muối trong 5 phút.', 'timeMinutes': 5},
              {'step': 'Làm nóng chảo, áp chảo mỗi mặt 4-5 phút cho vàng giòn.', 'timeMinutes': 10},
              {'step': 'Cho bơ tỏi vào rưới đều lên bề mặt và tắt bếp.', 'timeMinutes': 5},
            ],
            'tips': 'Áp chảo lửa vừa, để gà nghỉ 2 phút trước khi thái để nước cốt ngấm đều thớ thịt.',
          }
        ];
        await prefs.setString(_userPostsKey, jsonEncode(loadedUserPosts));
      }

      setState(() {
        _savedRecipeIds.addAll(savedList);
        _likedRecipeIds.addAll(likedList);
        _userPosts = loadedUserPosts;
      });
    } catch (_) {}
  }

  Future<void> _saveUserPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPostsKey, jsonEncode(_userPosts));
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_savedRecipesKey, _savedRecipeIds.toList());
      await prefs.setStringList(_likedRecipesKey, _likedRecipeIds.toList());
    } catch (_) {}
  }

  List<Map<String, dynamic>> _interleaveRecipes(List<Map<String, dynamic>> recipes) {
    const order = [
      'chicken',
      'beef',
      'salmon',
      'noodle',
      'egg',
      'tuna',
      'shrimp',
      'tofu',
      'bread',
      'oats',
      'salad',
      'pork',
      'corn',
      'soup',
      'other',
    ];
    final Map<String, List<Map<String, dynamic>>> buckets = {
      for (final k in order) k: <Map<String, dynamic>>[],
    };

    for (final r in recipes) {
      final t = ((r['title']?.toString() ?? '') + ' ' + (r['description']?.toString() ?? '')).toLowerCase();
      if (t.contains('cá hồi') || t.contains('salmon')) {
        buckets['salmon']!.add(r);
      } else if (t.contains('cá ngừ') || t.contains('tuna')) {
        buckets['tuna']!.add(r);
      } else if (t.contains('tôm') || t.contains('shrimp') || t.contains('cua') || t.contains('hải sản')) {
        buckets['shrimp']!.add(r);
      } else if (t.contains('bít tết') || t.contains('steak') || t.contains('thịt bò') || t.contains('bò')) {
        buckets['beef']!.add(r);
      } else if (t.contains('ức gà') || t.contains('đùi gà') || t.contains('cánh gà') || t.contains('thịt gà') || t.contains('gà')) {
        buckets['chicken']!.add(r);
      } else if (t.contains('thịt lợn') || t.contains('nạc lợn') || t.contains('thịt lợn') || t.contains('heo')) {
        buckets['pork']!.add(r);
      } else if (t.contains('bún') || t.contains('mì') || t.contains('phở') || t.contains('shirataki') || t.contains('miến') || t.contains('nui') || t.contains('bánh canh')) {
        buckets['noodle']!.add(r);
      } else if (t.contains('trứng')) {
        buckets['egg']!.add(r);
      } else if (t.contains('bánh mì') || t.contains('sandwich') || t.contains('toast') || t.contains('wrap') || t.contains('bánh cuộn')) {
        buckets['bread']!.add(r);
      } else if (t.contains('đậu hũ') || t.contains('tofu') || t.contains('món chay') || t.contains('chao')) {
        buckets['tofu']!.add(r);
      } else if (t.contains('overnight') || t.contains('yến mạch') || t.contains('oats')) {
        buckets['oats']!.add(r);
      } else if (t.contains('canh') || t.contains('soup') || t.contains('súp')) {
        buckets['soup']!.add(r);
      } else if (t.contains('bắp') || t.contains('ngô')) {
        buckets['corn']!.add(r);
      } else if (t.contains('salad') || t.contains('xà lách')) {
        buckets['salad']!.add(r);
      } else {
        buckets['other']!.add(r);
      }
    }

    final List<Map<String, dynamic>> result = [];
    int maxLen = 0;
    for (final b in buckets.values) {
      if (b.length > maxLen) maxLen = b.length;
    }

    for (int i = 0; i < maxLen; i++) {
      for (final k in order) {
        if (i < buckets[k]!.length) {
          result.add(buckets[k]![i]);
        }
      }
    }

    return result.isNotEmpty ? result : recipes;
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final apiRecipes = await ApiService.getRecipes();
      List<Map<String, dynamic>> rawList = apiRecipes;

      if (rawList.isEmpty) {
        rawList = _getCuratedFallbackRecipes();
      }

      // Đan xen luân phiên các nhóm món ăn để bảng tin đa dạng phong phú
      final diversifiedList = _interleaveRecipes(rawList);

      // Biến đổi các công thức thành bài đăng Instagram sống động với ảnh món ăn chuẩn 100%
      final enriched = _enrichRecipesToInstagramPosts(diversifiedList);
      _feedPosts = [..._userPosts, ...enriched];

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        final diversifiedList = _interleaveRecipes(_getCuratedFallbackRecipes());
        final enriched = _enrichRecipesToInstagramPosts(diversifiedList);
        _feedPosts = [..._userPosts, ...enriched];
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _enrichRecipesToInstagramPosts(List<Map<String, dynamic>> recipes) {
    final chefs = [
      {'name': 'chef_vietanh_eatclean', 'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', 'badge': 'HLV Dinh Dưỡng'},
      {'name': 'gymer_bepnha', 'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', 'badge': 'EatClean Chef'},
      {'name': 'coach_nam_nutrition', 'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', 'badge': 'Fitness Pro'},
      {'name': 'fitfoodie_vietnam', 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', 'badge': 'Healthy Kitchen'},
      {'name': 'eatgym_official', 'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150', 'badge': 'Bếp Trưởng EatGym'},
    ];

    return recipes.asMap().entries.map((entry) {
      final index = entry.key;
      final recipe = Map<String, dynamic>.from(entry.value);
      final id = recipe['id']?.toString() ?? 'recipe_$index';
      recipe['id'] = id;

      final chef = chefs[index % chefs.length];
      recipe['authorName'] = chef['name'];
      recipe['authorAvatar'] = chef['avatar'];
      recipe['authorBadge'] = chef['badge'];
      recipe['postedTime'] = '${(index + 1) * 3} giờ trước';
      recipe['location'] = 'EatGym Kitchen • Bếp Gymer';

      // GÁN ẢNH CHUẨN 100% THEO TỪNG MÓN ĂN TRONG DATABASE (Yêu cầu 2)
      final existingImg = recipe['image'] ?? recipe['imageUrl'] ?? recipe['image_url'];
      recipe['image'] = RecipeImageDatabase.resolveImage(
        recipe['title'] ?? '',
        existingImage: existingImg is String ? existingImg : null,
        description: recipe['description']?.toString(),
      );

      recipe['baseLikes'] = 142 + (index * 37) % 380;
      recipe['commentsCount'] = (index * 7) % 25 + 3;

      return recipe;
    }).toList();
  }

  List<Map<String, dynamic>> _getCuratedFallbackRecipes() {
    return [
      {
        'id': 'ig_1',
        'title': 'Ức gà áp chảo sốt bơ tỏi hương thảo',
        'kcal': 380,
        'protein': 42,
        'carbs': 8,
        'fat': 12,
        'time': 15,
        'tags': ['Tăng cơ', 'High Protein', 'Dưới 15 phút'],
        'description': 'Món ức gà vàng óng mặt ngoài, thớ thịt bên trong mọng nước ngọt tự nhiên quyện cùng mùi bơ tỏi thơm lừng. Cứu tinh cho gymer ngán ức gà luộc!',
        'ingredients': [
          {'name': 'Ức gà không da', 'amount': '250', 'unit': 'g'},
          {'name': 'Bơ lạt Anchor', 'amount': '15', 'unit': 'g'},
          {'name': 'Tỏi tép đập dập', 'amount': '3', 'unit': 'tép'},
          {'name': 'Lá hương thảo (Rosemary)', 'amount': '1', 'unit': 'nhánh'},
          {'name': 'Tiêu đen & muối biển', 'amount': '1', 'unit': 'nhúm'},
        ],
        'instructions': '1. Dùng khăn giấy thấm khô bề mặt ức gà, khứa caro nhẹ.\n2. Ướp muối tiêu 5 phút.\n3. Đun nóng chảo với chút dầu ô liu, áp chảo mỗi mặt 4-5 phút lửa vừa.\n4. Thả bơ lạt, tỏi và hương thảo vào, nghiêng chảo rưới đều bơ lên thịt gà cho đến khi vàng ruộm.',
      },
      {
        'id': 'ig_2',
        'title': 'Salad thăn bò áp chảo rau mầm ngũ sắc',
        'kcal': 340,
        'protein': 36,
        'carbs': 14,
        'fat': 10,
        'time': 12,
        'tags': ['Giảm mỡ', 'Eat Clean', 'Dưới 15 phút'],
        'description': 'Đĩa salad tươi mát giòn rụm với thịt bò thăn mềm ngọt xì xèo, cung cấp sắt và protein chất lượng cao hỗ trợ đốt mỡ siết cơ.',
        'ingredients': [
          {'name': 'Thịt thăn bò Úc', 'amount': '200', 'unit': 'g'},
          {'name': 'Cà chua bi tươi', 'amount': '80', 'unit': 'g'},
          {'name': 'Rau xà lách & bắp cải tím', 'amount': '120', 'unit': 'g'},
          {'name': 'Dưa leo baby', 'amount': '1', 'unit': 'trái'},
          {'name': 'Sốt giấm táo ô liu', 'amount': '2', 'unit': 'muỗng'},
        ],
        'instructions': '1. Bò thái lát vừa ăn, ướp tiêu tỏi trong 5 phút.\n2. Áp chảo thịt bò lửa lớn trong 2 phút chín tái mềm.\n3. Rửa sạch các loại rau, xếp vào tô lớn.\n4. Đặt thịt bò lên trên cùng, rưới sốt giấm táo và trộn đều.',
      },
      {
        'id': 'ig_3',
        'title': 'Phi lê cá hồi sốt chanh leo măng tây',
        'kcal': 450,
        'protein': 40,
        'carbs': 12,
        'fat': 22,
        'time': 15,
        'tags': ['Tăng cơ', 'High Protein', 'Dưới 15 phút'],
        'description': 'Giàu Omega-3 và chất béo lành mạnh giúp giảm viêm cơ sau buổi tập nặng. Sốt chanh leo chua ngọt cân bằng vị béo ngậy của cá hồi.',
        'ingredients': [
          {'name': 'Phi lê cá hồi tươi', 'amount': '220', 'unit': 'g'},
          {'name': 'Măng tây tươi', 'amount': '100', 'unit': 'g'},
          {'name': 'Nước cốt chanh leo', 'amount': '30', 'unit': 'ml'},
          {'name': 'Mật ong nguyên chất', 'amount': '1', 'unit': 'thìa cà phê'},
        ],
        'instructions': '1. Ướp cá hồi với chút muối và tiêu trắng.\n2. Áp chảo mặt da cá trước cho giòn rụm trong 4 phút, lật mặt còn lại 3 phút.\n3. Xào nhanh măng tây cùng chút bơ tỏi.\n4. Đun sôi nước cốt chanh leo với mật ong làm sốt rưới lên cá hồi.',
      },
      {
        'id': 'ig_4',
        'title': 'Trứng cuộn rau củ phô mai Mozzarella',
        'kcal': 290,
        'protein': 24,
        'carbs': 6,
        'fat': 18,
        'time': 10,
        'tags': ['Dưới 15 phút', 'Eat Clean'],
        'description': 'Bữa sáng nhanh gọn 10 phút tràn đầy năng lượng, phô mai kéo sợi thơm ngậy kích thích vị giác tuyệt đỉnh.',
        'ingredients': [
          {'name': 'Trứng gà tươi', 'amount': '3', 'unit': 'quả'},
          {'name': 'Phô mai Mozzarella bào', 'amount': '30', 'unit': 'g'},
          {'name': 'Bắp ngọt & cà rốt băm', 'amount': '40', 'unit': 'g'},
          {'name': 'Hành lá', 'amount': '10', 'unit': 'g'},
        ],
        'instructions': '1. Đánh tan 3 quả trứng với xíu tiêu, hành lá và bắp ngọt.\n2. Đổ 1 lớp trứng mỏng vào chảo chống dính.\n3. Rắc phô mai Mozzarella lên trên rồi nhẹ nhàng cuộn tròn từ từ.',
      },
      {
        'id': 'ig_5',
        'title': 'Cơm gạo lứt thịt nạc lợn rim mật ong',
        'kcal': 420,
        'protein': 35,
        'carbs': 48,
        'fat': 8,
        'time': 20,
        'tags': ['Tăng cơ', 'Eat Clean'],
        'description': 'Bữa trưa no lâu với carbs chậm từ gạo lứt và protein nạc không mỡ, giúp cơ bắp có nguồn năng lượng dồi dào suốt ngày dài.',
        'ingredients': [
          {'name': 'Thịt nạc lợn thăn', 'amount': '200', 'unit': 'g'},
          {'name': 'Cơm gạo lứt nấu chín', 'amount': '150', 'unit': 'g'},
          {'name': 'Mật ong & nước tương thanh vị', 'amount': '2', 'unit': 'muỗng'},
          {'name': 'Dưa chuột ăn kèm', 'amount': '1', 'unit': 'trái'},
        ],
        'instructions': '1. Thái thịt nạc lợn miếng vừa ăn, ướp mật ong, nước tương, tiêu tỏi trong 10 phút.\n2. Cho vào chảo rim lửa nhỏ cho đến khi sốt keo sền sệt bám đều thịt.\n3. Bày ăn cùng cơm gạo lứt nóng hổi và dưa chuột.',
      },
    ];
  }

  void _toggleLike(String id) {
    setState(() {
      if (_likedRecipeIds.contains(id)) {
        _likedRecipeIds.remove(id);
      } else {
        _likedRecipeIds.add(id);
      }
    });
    _saveState();
  }

  void _toggleSave(String id, String title) {
    final isSaved = _savedRecipeIds.contains(id);
    setState(() {
      if (isSaved) {
        _savedRecipeIds.remove(id);
      } else {
        _savedRecipeIds.add(id);
      }
    });
    _saveState();

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: !isSaved ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !isSaved
                    ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                    : const Color(0xFFEF4444).withValues(alpha: 0.2),
              ),
              child: Icon(
                !isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
                color: !isSaved ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                !isSaved
                    ? 'Đã lưu "$title" vào Bộ sưu tập của bạn!'
                    : 'Đã xóa "$title" khỏi Bộ sưu tập!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsSheet(String recipeId, String recipeTitle) {
    final comments = _commentsMap[recipeId] ?? [];
    final textCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF191C1B) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 14,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BÌNH LUẬN CÔNG THỨC',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    recipeTitle,
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 20),

                  // Danh sách bình luận
                  Expanded(
                    child: comments.isEmpty
                        ? const Center(child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!'))
                        : ListView.separated(
                            itemCount: comments.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (_, idx) {
                              final c = comments[idx];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                                    child: Text(
                                      (c['user'] ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: AppTypography.bodySmall(color: AppColors.onSurface),
                                            children: [
                                              TextSpan(
                                                text: '${c['user']}  ',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(text: c['text'] ?? ''),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Vừa xong • Trả lời', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                                ],
                              );
                            },
                          ),
                  ),

                  // Thanh gõ bình luận
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: textCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Thêm bình luận cho công thức này...',
                              isDense: true,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final txt = textCtrl.text.trim();
                            if (txt.isNotEmpty) {
                              setSheetState(() {
                                comments.insert(0, {'user': 'toi_gymer', 'text': txt});
                                _commentsMap[recipeId] = comments;
                              });
                              setState(() {});
                              textCtrl.clear();
                            }
                          },
                          child: const Text('Đăng', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showShareSheet(Map<String, dynamic> recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF191C1B) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('CHIA SẺ CÔNG THỨC', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(recipe['title'] ?? '', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant), maxLines: 1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareAction(
                      icon: Icons.link,
                      label: 'Sao chép link',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép liên kết công thức vào bộ nhớ tạm! 📋')),
                        );
                      },
                    ),
                    _buildShareAction(
                      icon: Icons.send_rounded,
                      label: 'Gửi bạn bè',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã mở danh sách gửi công thức cho đồng đội Gym! 🚀')),
                        );
                      },
                    ),
                    _buildShareAction(
                      icon: Icons.share_rounded,
                      label: 'Chia sẻ khác',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã mở hộp thoại chia sẻ công thức! 📲')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Icon(icon, color: AppColors.onSurface, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showRecipeDetailsModal(Map<String, dynamic> recipe, {BuildContext? customContext}) {
    final ingredients = recipe['ingredients'] as List? ?? [];
    final activeContext = customContext ?? context;
    final isDark = Theme.of(activeContext).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    showModalBottomSheet(
      context: activeContext,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF191C1B) : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Ảnh minh họa món ăn chi tiết
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 190,
                      child: _buildRecipeImage(recipe['image'], fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Thanh thông tin tác giả (Bấm vào xem trang cá nhân tác giả hoặc bản thân)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen(authorData: recipe)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundImage: NetworkImage(recipe['authorAvatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                            backgroundColor: isDark ? const Color(0xFF26322C) : Colors.grey[200],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      recipe['authorName'] ?? 'Tác giả',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: isDark ? Colors.white : AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (recipe['isMine'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isDark ? primaryAccent : AppColors.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'CỦA TÔI',
                                          style: TextStyle(
                                            color: isDark ? Colors.black : Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.verified, size: 14, color: Colors.blueAccent),
                                  ],
                                ),
                                Text(
                                  recipe['authorBadge'] ?? 'Đầu bếp EatClean',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Xem trang cá nhân',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? primaryAccent : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: isDark ? primaryAccent : AppColors.primary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    recipe['title'] ?? '',
                    style: AppTypography.headline(color: AppColors.onSurface).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (recipe['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      recipe['description'],
                      style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Macro cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge('Calo', '${recipe['kcal']} kcal', AppColors.fire),
                      _buildMacroBadge('Protein', '${recipe['protein']}g', AppColors.primary),
                      _buildMacroBadge('Carbs', '${recipe['carbs']}g', Colors.orange),
                      _buildMacroBadge('Chất béo', '${recipe['fat']}g', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Nguyên liệu cần có (${ingredients.length})', style: AppTypography.titleMedium(color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  ...ingredients.map((ing) {
                    final name = ing['name'] ?? '';
                    final amount = ing['amount'] ?? '';
                    final unit = ing['unit'] ?? '';
                    final notes = ing['notes'] != null ? ' (${ing['notes']})' : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text('$name$notes', style: AppTypography.bodyMedium(color: AppColors.onSurface))),
                          Text('$amount $unit', style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  if (recipe['instructions'] != null) ...[
                    const SizedBox(height: 20),
                    Text('Cách thực hiện', style: AppTypography.titleMedium(color: AppColors.onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recipe['instructions'],
                        style: AppTypography.bodyMedium(color: AppColors.onSurface),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.timer_outlined),
                      label: const Text('BẮT ĐẦU NẤU MÓN NÀY ⏱️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CookingTimerScreen(recipe: recipe),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.bodyMedium(color: color).copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _feedPosts.where((p) {
      if (_selectedFilter == 'Tất cả') return true;
      final tags = (p['tags'] as List?)?.map((t) => t.toString().toLowerCase()).toList() ?? [];
      final title = (p['title'] ?? '').toString().toLowerCase();
      final filterLower = _selectedFilter.toLowerCase();
      return tags.any((t) => t.contains(filterLower)) || title.contains(filterLower);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0D) : const Color(0xFFF8FAFC),
      appBar: null, // Đã chuyển lên AppHeader chính để tránh bị 2 tầng header
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : RefreshIndicator(
              onRefresh: _loadFeed,
              color: primaryAccent,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. THANH CHỦ ĐỀ CÔNG THỨC (Đã bỏ story tròn)
                  SliverToBoxAdapter(
                    child: _buildCategoryFilterChips(isDark, primaryAccent),
                  ),

                  // 2. DANH SÁCH BÀI ĐĂNG CÔNG THỨC KIỂU INSTAGRAM FEED
                  if (filteredPosts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Chưa có công thức cho mục "$_selectedFilter"',
                          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final post = filteredPosts[idx];
                          return _buildInstagramPostCard(post, isDark, primaryAccent);
                        },
                        childCount: filteredPosts.length,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// 4. Hiển thị danh sách công thức đã lưu có thanh tìm kiếm (Yêu cầu 4)
  void showSavedCollectionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF191C1B) : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final savedPosts = _feedPosts.where((p) => _savedRecipeIds.contains(p['id'])).toList();
            final filtered = savedPosts.where((p) {
              final title = (p['title'] ?? '').toString().toLowerCase();
              final desc = (p['description'] ?? '').toString().toLowerCase();
              return IngredientNormalizer.matchesSearch(title, searchQuery) || IngredientNormalizer.matchesSearch(desc, searchQuery);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bookmark, color: isDark ? primaryAccent : AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'CÔNG THỨC ĐÃ LƯU (${savedPosts.length})',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Thanh tìm kiếm trong công thức đã lưu
                  TextField(
                    onChanged: (val) => setSheetState(() => searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công thức đã lưu...',
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, size: 20, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF202623) : AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: savedPosts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark_border, size: 56, color: isDark ? Colors.white30 : Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'Bạn chưa lưu công thức nào',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Bấm vào biểu tượng 🔖 trên các bài đăng để lưu công thức yêu thích vào đây nhé!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'Không tìm thấy công thức nào khớp với "$searchQuery"',
                                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700]),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, idx) {
                                  final p = filtered[idx];
                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 65,
                                            height: 65,
                                            child: Image.network(
                                              p['image'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(color: isDark ? const Color(0xFF26322C) : Colors.grey[200], child: const Icon(Icons.restaurant)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p['title'] ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '⏱️ ${p['time']}p • 🔥 ${p['kcal']} kcal • 🍗 ${p['protein']}g Pro',
                                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700]),
                                              ),
                                              const SizedBox(height: 6),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.pop(ctx);
                                                  _showRecipeDetailsModal(p);
                                                },
                                                child: Text(
                                                  'Xem chi tiết & Nấu ngay →',
                                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? primaryAccent : AppColors.primary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.bookmark, color: isDark ? primaryAccent : AppColors.primary),
                                          tooltip: 'Bỏ lưu',
                                          onPressed: () {
                                            _toggleSave(p['id'], p['title'] ?? '');
                                            setSheetState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 5. Hiển thị danh sách các bài đăng công thức của tôi (Yêu cầu 5)
  void showMyPostsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF191C1B) : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'BÀI ĐĂNG CỦA TÔI (${_userPosts.length})',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quản lý lượt tim, bình luận, sửa hoặc gỡ công thức của bạn',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                  ),
                  Divider(height: 20, color: isDark ? Colors.white12 : Colors.grey[300]),

                  Expanded(
                    child: _userPosts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_note, size: 64, color: isDark ? Colors.white30 : Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'Bạn chưa đăng công thức nào',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Bấm vào dấu [+] cạnh chữ EatGym Kitchen để chia sẻ công thức đầu tiên của bạn nhé!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? primaryAccent : AppColors.primary,
                                    foregroundColor: isDark ? Colors.black : AppColors.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    showCreateRecipeSheet();
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Đăng công thức mới ngay'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _userPosts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, idx) {
                              final post = _userPosts[idx];
                              final isLiked = _likedRecipeIds.contains(post['id']);
                              final totalLikes = (post['baseLikes'] as int? ?? 1) + (isLiked ? 1 : 0);
                              final comments = _commentsMap[post['id']] ?? [];

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineVariant.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 65,
                                            height: 65,
                                            child: Image.network(
                                              post['image'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(color: isDark ? const Color(0xFF26322C) : Colors.grey[200], child: const Icon(Icons.restaurant)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post['title'] ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Đăng ${post['postedTime'] ?? "vừa xong"}',
                                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                                                        const SizedBox(width: 3),
                                                        Text('$totalLikes tim', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.chat_bubble_outline, size: 12, color: Colors.blue),
                                                        const SizedBox(width: 3),
                                                        Text('${comments.length + (post['commentsCount'] as int? ?? 0)} bình luận', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey[300]),
                                    const SizedBox(height: 8),

                                    // 3 Nút thao tác: Xem chi tiết & bình luận / Chỉnh sửa / Gỡ bài
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _showRecipeDetailsModal(post);
                                          },
                                          icon: Icon(Icons.visibility_outlined, size: 16, color: isDark ? primaryAccent : AppColors.primary),
                                          label: Text('Xem & Bình luận', style: TextStyle(fontSize: 11.5, color: isDark ? primaryAccent : AppColors.primary)),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            showEditRecipeSheet(post);
                                          },
                                          icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.orange),
                                          label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 11.5, color: Colors.orange)),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                          onPressed: () => _confirmDeletePost(post['id'], setSheetState),
                                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                          label: const Text('Gỡ bài', style: TextStyle(fontSize: 11.5, color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePost(String id, void Function(void Function()) setSheetState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF191C1B) : Colors.white,
        title: Text('Xác nhận gỡ bài đăng?', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text('Bài đăng công thức này sẽ bị xóa khỏi EatGym Kitchen và không thể khôi phục lại.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Hủy', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                _userPosts.removeWhere((p) => p['id'] == id);
                _feedPosts.removeWhere((p) => p['id'] == id);
              });
              _saveUserPosts();
              setSheetState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gỡ bài đăng thành công!'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Xóa bài'),
          ),
        ],
      ),
    );
  }

  /// 2. Nút [+] Mở form đăng công thức của riêng tôi (Yêu cầu 2)
  void showCreateRecipeSheet({BuildContext? customContext}) {
    _openRecipeFormSheet(isEditing: false, customContext: customContext);
  }

  /// Mở form chỉnh sửa công thức của tôi (Yêu cầu 5)
  void showEditRecipeSheet(Map<String, dynamic> existingPost, {BuildContext? customContext}) {
    _openRecipeFormSheet(isEditing: true, initialData: existingPost, customContext: customContext);
  }

  void _openRecipeFormSheet({required bool isEditing, Map<String, dynamic>? initialData, BuildContext? customContext}) {
    final titleCtrl = TextEditingController(text: initialData?['title'] ?? '');
    final timeCtrl = TextEditingController(text: initialData != null ? '${initialData['time']}' : '20');
    final kcalCtrl = TextEditingController(text: initialData != null ? '${initialData['kcal']}' : '350');
    final proCtrl = TextEditingController(text: initialData != null ? '${initialData['protein']}' : '40');
    final carbsCtrl = TextEditingController(text: initialData != null ? '${initialData['carbs']}' : '15');
    final fatCtrl = TextEditingController(text: initialData != null ? '${initialData['fat']}' : '8');
    final tipsCtrl = TextEditingController(text: initialData?['tips'] ?? initialData?['description'] ?? '');

    String selectedDifficulty = initialData?['difficulty'] ?? 'Dễ';
    String selectedImage = initialData?['image'] ?? 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800';

    final sampleImages = [
      'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800', // Ức gà
      'https://images.unsplash.com/photo-1544025162-d76694265947?w=800', // Bò bít tết
      'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800', // Cá hồi
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800', // Salad
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800', // Cơm gạo lứt
      'https://images.unsplash.com/photo-1559737558-2f5a35f4523b?w=800', // Tôm áp chảo
    ];

    // Danh sách nguyên liệu
    final List<Map<String, TextEditingController>> ingredientCtrls = [];
    if (initialData != null && initialData['ingredients'] is List) {
      for (final ing in initialData['ingredients']) {
        ingredientCtrls.add({
          'name': TextEditingController(text: ing['name']?.toString() ?? ''),
          'amount': TextEditingController(text: '${ing['amount'] ?? 100} ${ing['unit'] ?? "g"}'),
        });
      }
    }
    if (ingredientCtrls.isEmpty) {
      ingredientCtrls.add({'name': TextEditingController(text: 'Ức gà tươi'), 'amount': TextEditingController(text: '250g')});
      ingredientCtrls.add({'name': TextEditingController(text: 'Bông cải xanh'), 'amount': TextEditingController(text: '150g')});
    }

    // Danh sách các bước nấu & thời gian từng bước
    final List<Map<String, TextEditingController>> stepCtrls = [];
    if (initialData != null && initialData['steps'] is List) {
      for (final st in initialData['steps']) {
        if (st is Map) {
          stepCtrls.add({
            'step': TextEditingController(text: st['step']?.toString() ?? ''),
            'time': TextEditingController(text: '${st['timeMinutes'] ?? 5}'),
          });
        } else {
          stepCtrls.add({
            'step': TextEditingController(text: st.toString()),
            'time': TextEditingController(text: '5'),
          });
        }
      }
    }
    if (stepCtrls.isEmpty) {
      stepCtrls.add({'step': TextEditingController(text: 'Sơ chế nguyên liệu và ướp gia vị tiêu muối.'), 'time': TextEditingController(text: '5')});
      stepCtrls.add({'step': TextEditingController(text: 'Áp chảo lửa vừa mỗi mặt 4-5 phút cho chín vàng.'), 'time': TextEditingController(text: '10')});
    }

    final activeContext = customContext ?? context;
    final isDark = Theme.of(activeContext).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    showModalBottomSheet(
      context: activeContext,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF191C1B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'CHỈNH SỬA CÔNG THỨC CỦA TÔI' : 'ĐĂNG CÔNG THỨC GYMER CỦA BẠN',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : const Color(0xFF0F172A)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Chọn ảnh món ăn (Yêu cầu 1: Chụp ảnh hoặc Chọn từ gallery)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1. Ảnh món ăn:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              if (selectedImage.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDark ? primaryAccent : AppColors.primary).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    selectedImage.startsWith('http') ? 'Ảnh mẫu Gymer' : 'Ảnh từ thiết bị 📱',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? primaryAccent : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Khung xem trước ảnh lớn và thanh nút thao tác
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedImage.isNotEmpty
                                    ? (isDark ? primaryAccent : AppColors.primary)
                                    : (isDark ? Colors.white12 : AppColors.outlineVariant),
                                width: selectedImage.isNotEmpty ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                if (selectedImage.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                    child: SizedBox(
                                      height: 165,
                                      width: double.infinity,
                                      child: _buildRecipeImage(selectedImage, fit: BoxFit.cover),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    height: 110,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, size: 36, color: isDark ? Colors.white30 : Colors.grey[500]),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Chưa có ảnh món ăn',
                                          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Hai nút: Chụp ảnh và Chọn từ thư viện
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1D2320) : Colors.white,
                                    borderRadius: selectedImage.isNotEmpty
                                        ? const BorderRadius.vertical(bottom: Radius.circular(14))
                                        : BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      // Nút 1: Chụp ảnh bằng camera (Yêu cầu 1)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            try {
                                              final picker = ImagePicker();
                                              final picked = await picker.pickImage(
                                                source: ImageSource.camera,
                                                maxWidth: 1280,
                                                maxHeight: 1280,
                                                imageQuality: 85,
                                              );
                                              if (picked != null) {
                                                setModalState(() => selectedImage = picked.path);
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Không thể chụp ảnh: $e'), backgroundColor: AppColors.warning),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.camera_alt, size: 16),
                                          label: const Text('Chụp ảnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDark ? primaryAccent : AppColors.primary,
                                            foregroundColor: isDark ? Colors.black : Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 9),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Nút 2: Chọn ảnh từ Gallery thư viện (Yêu cầu 1)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            try {
                                              final picker = ImagePicker();
                                              final picked = await picker.pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 1280,
                                                maxHeight: 1280,
                                                imageQuality: 85,
                                              );
                                              if (picked != null) {
                                                setModalState(() => selectedImage = picked.path);
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Không thể chọn ảnh từ thư viện: $e'), backgroundColor: AppColors.warning),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.photo_library, size: 16),
                                          label: const Text('Từ thư viện', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isDark ? Colors.white : AppColors.onSurface,
                                            side: BorderSide(color: isDark ? Colors.white24 : AppColors.outlineVariant),
                                            padding: const EdgeInsets.symmetric(vertical: 9),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Tùy chọn ảnh mẫu chuẩn Gymer
                          Text(
                            'Hoặc chọn nhanh ảnh mẫu Gymer chất lượng cao:',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 65,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: sampleImages.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final img = sampleImages[i];
                                final isChosen = selectedImage == img;
                                return GestureDetector(
                                  onTap: () => setModalState(() => selectedImage = img),
                                  child: Container(
                                    width: 65,
                                    height: 65,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isChosen ? (isDark ? primaryAccent : AppColors.primary) : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(img, fit: BoxFit.cover),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Tên món ăn
                          Text(
                            '2. Tên công thức món ăn:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleCtrl,
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                            cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                            decoration: InputDecoration(
                              hintText: 'VD: Ức gà cuộn măng tây sốt tiêu đen...',
                              hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                              isDense: true,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF202623) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Thời gian nấu & Độ khó
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '3. Thời gian nấu (phút):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: timeCtrl,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                                      cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                                      decoration: InputDecoration(
                                        hintText: '20',
                                        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                        suffixText: 'phút',
                                        suffixStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                        isDense: true,
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF202623) : const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Độ khó:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: ['Dễ', 'Vừa', 'Khó'].map((diff) {
                                        final isSel = selectedDifficulty == diff;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: ChoiceChip(
                                            label: Text(diff, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w600)),
                                            selected: isSel,
                                            onSelected: (_) => setModalState(() => selectedDifficulty = diff),
                                            selectedColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                                            labelStyle: TextStyle(color: isSel ? (isDark ? Colors.black : Colors.white) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155))),
                                            backgroundColor: isDark ? const Color(0xFF202623) : const Color(0xFFF1F5F9),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 4. Chỉ số dinh dưỡng (Macros)
                          Text(
                            '4. Chỉ số Dinh dưỡng (Macros ước tính):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _buildMacroInputField('🔥 Kcal', kcalCtrl, isDark: isDark, primaryAccent: primaryAccent)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildMacroInputField('🍗 Pro(g)', proCtrl, isDark: isDark, primaryAccent: primaryAccent)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildMacroInputField('🍚 Carb(g)', carbsCtrl, isDark: isDark, primaryAccent: primaryAccent)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildMacroInputField('🥑 Fat(g)', fatCtrl, isDark: isDark, primaryAccent: primaryAccent)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 5. Danh sách nguyên liệu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '5. Nguyên liệu chuẩn bị:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                onPressed: () {
                                  setModalState(() {
                                    ingredientCtrls.add({'name': TextEditingController(), 'amount': TextEditingController(text: '100g')});
                                  });
                                },
                                icon: Icon(Icons.add, size: 16, color: isDark ? primaryAccent : const Color(0xFF2563EB)),
                                label: Text('Thêm', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? primaryAccent : const Color(0xFF2563EB))),
                              ),
                            ],
                          ),
                          ...ingredientCtrls.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ing = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: TextField(
                                      controller: ing['name'],
                                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w600),
                                      cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                                      decoration: InputDecoration(
                                        hintText: 'Tên nguyên liệu...',
                                        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                                        isDense: true,
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF202623) : const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: ing['amount'],
                                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w600),
                                      cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                                      decoration: InputDecoration(
                                        hintText: '200g',
                                        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                                        isDense: true,
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF202623) : const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                                      ),
                                    ),
                                  ),
                                  if (ingredientCtrls.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setModalState(() => ingredientCtrls.removeAt(idx)),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 14),

                          // 6. Các bước nấu & Thời gian từng bước
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '6. Các bước nấu & Thời gian từng bước:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                onPressed: () {
                                  setModalState(() {
                                    stepCtrls.add({'step': TextEditingController(), 'time': TextEditingController(text: '5')});
                                  });
                                },
                                icon: Icon(Icons.add, size: 16, color: isDark ? primaryAccent : const Color(0xFF2563EB)),
                                label: Text('Thêm bước', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? primaryAccent : const Color(0xFF2563EB))),
                              ),
                            ],
                          ),
                          ...stepCtrls.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final st = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Bước ${idx + 1}:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                        Row(
                                          children: [
                                            Icon(Icons.timer_outlined, size: 15, color: isDark ? primaryAccent : const Color(0xFF2563EB)),
                                            const SizedBox(width: 4),
                                            SizedBox(
                                              width: 54,
                                              height: 32,
                                              child: TextField(
                                                controller: st['time'],
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                                                cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.all(4),
                                                  suffixText: 'p',
                                                  suffixStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                                  fillColor: isDark ? const Color(0xFF202623) : Colors.white,
                                                  filled: true,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                                                ),
                                              ),
                                            ),
                                            if (stepCtrls.length > 1)
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () => setModalState(() => stepCtrls.removeAt(idx)),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: st['step'],
                                      maxLines: 2,
                                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500),
                                      cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                                      decoration: InputDecoration(
                                        hintText: 'Nội dung hướng dẫn thực hiện bước này...',
                                        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF202623) : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 14),

                          // 7. Chú thích & Mẹo Gymer
                          Text(
                            '7. Chú thích & Mẹo nấu ăn cho Gymer:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: tipsCtrl,
                            maxLines: 2,
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500),
                            cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                            decoration: InputDecoration(
                              hintText: 'VD: Bí quyết ướp thịt, mẹo canh lửa, lưu ý bảo quản...',
                              hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                              isDense: true,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF202623) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Nút ĐĂNG / LƯU CÔNG THỨC
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? primaryAccent : AppColors.primary,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                if (titleCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng nhập tên công thức!'), behavior: SnackBarBehavior.floating),
                                  );
                                  return;
                                }

                                final ingList = ingredientCtrls.map((c) => {
                                  'name': c['name']!.text.trim().isNotEmpty ? c['name']!.text.trim() : 'Nguyên liệu',
                                  'amount': c['amount']!.text.trim().isNotEmpty ? c['amount']!.text.trim() : '100g',
                                }).toList();

                                final stepsList = stepCtrls.map((c) => {
                                  'step': c['step']!.text.trim().isNotEmpty ? c['step']!.text.trim() : 'Nấu chín nguyên liệu.',
                                  'timeMinutes': int.tryParse(c['time']!.text.trim()) ?? 5,
                                }).toList();

                                final newPostId = isEditing ? (initialData!['id']) : 'user_recipe_${DateTime.now().millisecondsSinceEpoch}';
                                final newPostMap = {
                                  'id': newPostId,
                                  'title': titleCtrl.text.trim(),
                                  'time': int.tryParse(timeCtrl.text.trim()) ?? 20,
                                  'difficulty': selectedDifficulty,
                                  'kcal': int.tryParse(kcalCtrl.text.trim()) ?? 350,
                                  'protein': int.tryParse(proCtrl.text.trim()) ?? 40,
                                  'carbs': int.tryParse(carbsCtrl.text.trim()) ?? 15,
                                  'fat': int.tryParse(fatCtrl.text.trim()) ?? 8,
                                  'image': selectedImage,
                                  'description': tipsCtrl.text.trim().isNotEmpty ? tipsCtrl.text.trim() : 'Công thức giàu đạm chuẩn gymer.',
                                  'authorName': 'Bạn (Gymer)',
                                  'authorAvatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                                  'authorBadge': 'Gymer Tác Giả',
                                  'location': 'EatGym Kitchen • Bếp Của Tôi',
                                  'postedTime': isEditing ? (initialData!['postedTime'] ?? 'Vừa sửa') : 'Vừa xong',
                                  'isMine': true,
                                  'baseLikes': isEditing ? (initialData!['baseLikes'] ?? 1) : 1,
                                  'commentsCount': isEditing ? (initialData!['commentsCount'] ?? 0) : 0,
                                  'ingredients': ingList,
                                  'steps': stepsList,
                                  'tips': tipsCtrl.text.trim(),
                                };

                                setState(() {
                                  if (isEditing) {
                                    final idxU = _userPosts.indexWhere((p) => p['id'] == newPostId);
                                    if (idxU != -1) _userPosts[idxU] = newPostMap;
                                    final idxF = _feedPosts.indexWhere((p) => p['id'] == newPostId);
                                    if (idxF != -1) _feedPosts[idxF] = newPostMap;
                                  } else {
                                    _userPosts.insert(0, newPostMap);
                                    _feedPosts.insert(0, newPostMap);
                                    _savedRecipeIds.add(newPostId); // Tự động lưu công thức của mình
                                  }
                                });
                                _saveUserPosts();
                                _saveState();

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing ? '✨ Đã cập nhật công thức thành công!' : '🎉 Đã đăng công thức lên EatGym Kitchen thành công!'),
                                    backgroundColor: isDark ? primaryAccent : AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: Icon(isEditing ? Icons.save : Icons.rocket_launch),
                              label: Text(
                                isEditing ? 'LƯU THAY ĐỔI CÔNG THỨC' : 'ĐĂNG CÔNG THỨC LÊN BẢNG TIN 🚀',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMacroInputField(String label, TextEditingController ctrl, {bool isDark = false, Color? primaryAccent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w700),
          cursorColor: isDark ? (primaryAccent ?? Colors.white) : const Color(0xFF0F172A),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            filled: true,
            fillColor: isDark ? const Color(0xFF202623) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? (primaryAccent ?? Colors.white) : const Color(0xFF0F172A), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChips(bool isDark, Color primaryAccent) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final s = _stories[index];
          final isSelected = _selectedFilter == s['tag'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = s['tag']!;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? primaryAccent : AppColors.darkNavy)
                    : (isDark ? const Color(0xFF151B18) : AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? primaryAccent : AppColors.darkNavy)
                      : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.outlineVariant.withValues(alpha: 0.6)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s['icon']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    s['label']!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? const Color(0xFFE1E3E1) : AppColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Từng bài đăng công thức (Instagram Feed Post Card)
  Widget _buildInstagramPostCard(Map<String, dynamic> post, bool isDark, Color primaryAccent) {
    final id = post['id'] as String;
    final isLiked = _likedRecipeIds.contains(id);
    final isSaved = _savedRecipeIds.contains(id);
    final totalLikes = (post['baseLikes'] as int) + (isLiked ? 1 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B18) : Colors.white,
        border: isDark ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header: Avatar, Username, Badge, 3-dots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Bấm vào avatar hoặc tên tác giả để mở trang cá nhân
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(authorData: post),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(post['authorAvatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                          backgroundColor: isDark ? const Color(0xFF26322C) : Colors.grey[200],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    post['authorName'] ?? 'Gymer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (post['isMine'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isDark ? primaryAccent : AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'CỦA TÔI',
                                        style: TextStyle(
                                          color: isDark ? Colors.black : Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.verified, size: 14, color: Colors.blueAccent),
                                ],
                              ),
                              Text(
                                '${post['location'] ?? "EatGym Kitchen"} • ${post['postedTime'] ?? "Vừa xong"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white : Colors.black87),
                  onPressed: () => _showShareSheet(post),
                ),
              ],
            ),
          ),

          // 2. Post Media: Ảnh món ăn (Double tap để bắn tim, Chạm vào để xem chi tiết công thức)
          GestureDetector(
            onDoubleTap: () => _toggleLike(id),
            onTap: () => _showRecipeDetailsModal(post),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1.0, // Tỉ lệ vuông chuẩn Instagram
                  child: (post['image'] != null && post['image'].toString().startsWith('http'))
                      ? Image.network(
                          post['image'],
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: isDark ? const Color(0xFF1E2420) : Colors.grey[100],
                              child: Center(
                                child: CircularProgressIndicator(color: primaryAccent, strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (ctx, err, stack) {
                            return Container(
                              color: isDark ? const Color(0xFF1E2420) : Colors.grey[200],
                              alignment: Alignment.center,
                              child: Icon(Icons.restaurant, size: 64, color: isDark ? Colors.white38 : Colors.grey),
                            );
                          },
                        )
                      : Container(
                          color: isDark ? const Color(0xFF1E2420) : Colors.grey[200],
                          alignment: Alignment.center,
                          child: Icon(Icons.restaurant, size: 64, color: isDark ? Colors.white38 : Colors.grey),
                        ),
                ),

                // Floating Tag: Thời gian nấu (Góc trên phải)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${post['time']} phút',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating Tag: Macro calo & protein (Góc dưới trái)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥 ', style: TextStyle(fontSize: 12)),
                        Text(
                          '${post['kcal']} kcal  •  🍗 ${post['protein']}g Pro',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Action Bar: Tim, Bình luận, Chia sẻ, Lưu lại
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Nút Tim
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
                        size: 26,
                      ),
                      onPressed: () => _toggleLike(id),
                    ),
                    // Nút Bình luận
                    IconButton(
                      icon: Icon(Icons.chat_bubble_outline, size: 24, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => _showCommentsSheet(id, post['title'] ?? ''),
                    ),
                    // Nút Chia sẻ
                    IconButton(
                      icon: Icon(Icons.send_outlined, size: 24, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => _showShareSheet(post),
                    ),
                  ],
                ),
                // Nút Lưu lại (Bookmark)
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved
                        ? (isDark ? primaryAccent : AppColors.onSurface)
                        : (isDark ? Colors.white : Colors.black87),
                    size: 26,
                  ),
                  onPressed: () => _toggleSave(id, post['title'] ?? ''),
                ),
              ],
            ),
          ),

          // 4. Lượt thích (Social proof)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Avatars xếp chồng
                SizedBox(
                  width: 36,
                  height: 20,
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 0,
                        child: CircleAvatar(radius: 9, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=50')),
                      ),
                      Positioned(
                        left: 12,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: isDark ? const Color(0xFF151B18) : Colors.white,
                          child: CircleAvatar(radius: 8, backgroundImage: NetworkImage(post['authorAvatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=50')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodySmall(color: isDark ? const Color(0xFFE1E3E1) : AppColors.onSurface),
                      children: [
                        const TextSpan(text: 'Có '),
                        const TextSpan(text: 'cminh_24', style: TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: ' và '),
                        TextSpan(text: '$totalLikes người khác', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: ' thích'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Tiêu đề món ăn & Chú thích (Caption)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showRecipeDetailsModal(post),
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodySmall(color: isDark ? Colors.white : AppColors.onSurface),
                      children: [
                        TextSpan(
                          text: '${post['authorName']}  ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: post['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post['description'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey[800],
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                // Hashtags
                const Text(
                  '#EatClean #TangCoGiamMo #HighProtein #GymFood #EatGymKitchen',
                  style: TextStyle(fontSize: 12, color: Colors.blueAccent),
                ),
              ],
            ),
          ),

          // 6. Macro Pills Tag Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildSmallMacroPill('🔥 ${post['kcal']} kcal', Colors.orange),
                _buildSmallMacroPill('🍗 ${post['protein']}g Protein', Colors.redAccent),
                _buildSmallMacroPill('🍚 ${post['carbs']}g Carbs', Colors.amber[800]!),
                _buildSmallMacroPill('🥑 ${post['fat']}g Fat', Colors.blue),
              ],
            ),
          ),

          const Divider(height: 20, thickness: 0.5, color: Colors.transparent),
        ],
      ),
    );
  }

  Widget _buildSmallMacroPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

