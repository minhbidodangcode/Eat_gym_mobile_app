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
        
        final rawIngredients = r['ingredients'] ?? r['matchedIngredients'];
        List<String> ings = [];
        if (rawIngredients is List && rawIngredients.isNotEmpty) {
          for (final item in rawIngredients) {
            if (item is Map) {
              final name = item['name']?.toString() ?? item['ingredient_name']?.toString() ?? '';
              final amount = item['amount']?.toString() ?? '';
              final unit = item['unit']?.toString() ?? '';
              if (name.isNotEmpty) {
                if (amount.isNotEmpty) {
                  ings.add('$name ($amount$unit)');
                } else {
                  ings.add(name);
                }
              }
            } else if (item != null && item.toString().trim().isNotEmpty) {
              ings.add(item.toString().trim());
            }
          }
        }

        // Nếu database chưa có danh sách nguyên liệu bóc tách, trích xuất từ tên món ăn
        if (ings.isEmpty) {
          final words = title.replaceAll(RegExp(r'^(Bánh mì|Salad|Cơm|Cháo|Súp|Canh|Thịt)\s+', caseSensitive: false), '');
          final parts = words.split(RegExp(r'\s+(kẹp|trộn|với|xào|hấp|luộc|nướng|áp chảo|ăn kèm|sốt)\s+', caseSensitive: false));
          for (final p in parts) {
            final clean = p.trim();
            if (clean.length > 2 && !ings.contains(clean)) {
              ings.add('$clean (vừa đủ)');
            }
          }
          if (ings.isEmpty && ingredient.trim().isNotEmpty) {
            ings.add('$ingredient (khẩu phần gymer)');
          }
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
