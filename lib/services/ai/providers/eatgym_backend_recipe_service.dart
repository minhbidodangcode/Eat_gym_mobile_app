import '../../../models/recipe.dart';
import '../recipe_service.dart';
import '../../api_service.dart';

/// Recipe service kết nối trực tiếp với backend EatGym (PostgreSQL - 4,008 món ăn thể hình)
class EatGymBackendRecipeService implements RecipeService {
  @override
  Future<List<Recipe>> getRecipesByIngredient(String ingredient) async {
    try {
      final backendRecipes = await ApiService.suggestRecipes([ingredient]);
      return backendRecipes.map((r) {
        final title = (r['title'] ?? r['name'] ?? 'Món ăn').toString();
        final time = (r['time'] ?? r['cooking_time_min'] ?? 15) as int;
        
        final rawMatched = r['matchedIngredients'];
        List<String> ings = [];
        if (rawMatched is List) {
          ings = rawMatched.map((i) => i.toString()).toList();
        }

        final instructions = (r['instructions'] ?? '').toString();
        List<String> steps = [];
        if (instructions.isNotEmpty) {
          steps = instructions
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if (steps.isEmpty) {
          steps = ['Sơ chế nguyên liệu sạch sẽ', 'Chế biến theo khẩu vị và mục tiêu gym'];
        }

        return Recipe(
          name: title,
          ingredients: ings,
          steps: steps,
          durationMinutes: time,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
