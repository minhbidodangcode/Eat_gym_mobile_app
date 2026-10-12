import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/recipe.dart';
import '../recipe_service.dart';

class TheMealDBRecipeService implements RecipeService {
  final String _baseUrl = "https://www.themealdb.com/api/json/v1/1";

  @override
  Future<List<Recipe>> getRecipesByIngredient(String ingredient) async {
    try {
      // 1. Tìm kiếm danh sách món ăn theo nguyên liệu
      final filterUrl = Uri.parse("$_baseUrl/filter.php?i=$ingredient");
      final filterResponse = await http.get(filterUrl);

      if (filterResponse.statusCode != 200) {
        throw Exception("TheMealDB Filter API error: ${filterResponse.statusCode}");
      }

      final filterData = json.decode(filterResponse.body);
      final List? meals = filterData['meals'];

      if (meals == null || meals.isEmpty) {
        return [];
      }

      // 2. Lấy chi tiết từng món ăn
      final List<Recipe> recipes = [];
      
      // Giới hạn số lượng món ăn để tránh quá tải API test (ví dụ 5 món đầu tiên)
      final limitedMeals = meals.take(5).toList();

      for (var meal in limitedMeals) {
        try {
          final idMeal = meal['idMeal'];
          if (idMeal == null) continue;

          final recipe = await _fetchRecipeDetails(idMeal.toString());
          if (recipe != null) {
            recipes.add(recipe);
          }
        } catch (e) {
          // Bỏ qua món ăn lỗi và tiếp tục
          continue;
        }
      }

      return recipes;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Failed to get recipes from TheMealDB: $e");
    }
  }

  Future<Recipe?> _fetchRecipeDetails(String idMeal) async {
    final lookupUrl = Uri.parse("$_baseUrl/lookup.php?i=$idMeal");
    final response = await http.get(lookupUrl);

    if (response.statusCode != 200) {
      return null;
    }

    final data = json.decode(response.body);
    final List? meals = data['meals'];

    if (meals == null || meals.isEmpty) {
      return null;
    }

    final mealData = meals.first;

    // Parse ingredients & measures
    final List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = mealData['strIngredient$i'];
      final measure = mealData['strMeasure$i'];

      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        if (measure != null && measure.toString().trim().isNotEmpty) {
          ingredients.add("${ingredient.toString().trim()} - ${measure.toString().trim()}");
        } else {
          ingredients.add(ingredient.toString().trim());
        }
      }
    }

    // Parse steps (chia instructions theo dòng hoặc dấu chấm nếu cần, ở đây lấy nguyên bản)
    final instructions = mealData['strInstructions']?.toString() ?? "";
    final steps = instructions
        .split(RegExp(r'\r\n|\n|\r'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Estimate duration from instructions if available
    final duration = estimateDurationMinutes(instructions);

    return Recipe(
      name: mealData['strMeal']?.toString() ?? "Unknown Recipe",
      ingredients: ingredients,
      steps: steps,
      durationMinutes: duration,
    );
  }

  /// Phân tích thời gian nấu từ mô tả công thức (strInstructions)
  static int estimateDurationMinutes(String instructions) {
    if (instructions.trim().isEmpty) return 15;

    // Nếu có chứa từ chỉ giờ (hour/hr/tiếng) -> chắc chắn > 15 phút
    final hourRegex = RegExp(r'\b(\d+)\s*(?:hour|hours|hr|hrs|tiếng|giờ)\b', caseSensitive: false);
    if (hourRegex.hasMatch(instructions)) {
      final match = hourRegex.firstMatch(instructions);
      final hours = int.tryParse(match?.group(1) ?? '1') ?? 1;
      return hours * 60;
    }

    // Tìm tất cả các từ chỉ phút: ví dụ "10 mins", "5-10 minutes", "15 min", "12 phút"
    final minMatches = RegExp(r'\b(\d+)(?:-(\d+))?\s*(?:min|mins|minute|minutes|phút)\b', caseSensitive: false)
        .allMatches(instructions);

    if (minMatches.isNotEmpty) {
      int maxOrTotalMin = 0;
      for (final match in minMatches) {
        final val = int.tryParse(match.group(2) ?? match.group(1) ?? '0') ?? 0;
        // Lấy thời gian công đoạn dài nhất hoặc tổng thời gian nấu
        if (val > maxOrTotalMin) {
          maxOrTotalMin = val;
        }
      }
      if (maxOrTotalMin > 0) {
        return maxOrTotalMin;
      }
    }

    final lower = instructions.toLowerCase();
    // Các phương pháp nấu lâu
    if (lower.contains('bake') || lower.contains('roast') || lower.contains('stew') || lower.contains('simmer for 30') || lower.contains('marinate overnight')) {
      return 35;
    }

    // Các món nhanh, trộn salad, xào nhanh, sinh tố
    return 12;
  }
}

