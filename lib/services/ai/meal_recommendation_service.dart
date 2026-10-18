import 'dart:io';
import '../../models/recipe.dart';
import '../../models/meal_recommendation_result.dart';
import 'food_recognition_service.dart';
import 'ingredient_normalizer.dart';
import 'recipe_service.dart';

class MealRecommendationService {
  final FoodRecognitionService foodRecognitionService;
  final RecipeService recipeService;

  MealRecommendationService({
    required this.foodRecognitionService,
    required this.recipeService,
  });

  Future<MealRecommendationResult> recommendMeals(
    File image, {
    double minConfidence = 0.4,
    int? maxDurationMinutes,
  }) async {
    // 1. Nhận diện nguyên liệu từ ảnh (Gọi 1 lần duy nhất với confidence threshold)
    final recognitionResults = await foodRecognitionService.recognizeIngredients(image, confidence: minConfidence);

    // 2. Lọc confidence >= minConfidence
    final filteredResults = recognitionResults
        .where((result) => result.confidence >= minConfidence)
        .toList();

    if (filteredResults.isEmpty) {
      return MealRecommendationResult(
        recognizedIngredients: [],
        recipes: [],
      );
    }

    // 3. Chuẩn hóa tên nguyên liệu để tìm kiếm
    final normalizedIngredients = filteredResults
        .map((result) => IngredientNormalizer.normalize(result.foodName))
        .toSet() // Dùng Set để tránh tìm kiếm trùng lặp
        .toList();

    // 4. Tìm kiếm Recipe cho từng nguyên liệu
    final Map<String, Recipe> uniqueRecipes = {};
    
    for (var ingredient in normalizedIngredients) {
      try {
        final recipes = await recipeService.getRecipesByIngredient(ingredient);
        for (var recipe in recipes) {
          // Bỏ lọc cố định <= 15p: chỉ lọc nếu có yêu cầu cụ thể
          if (maxDurationMinutes != null &&
              recipe.durationMinutes != null &&
              recipe.durationMinutes! > maxDurationMinutes) {
            continue;
          }
          // Loại bỏ duplicate dựa trên tên món ăn
          uniqueRecipes[recipe.name] = recipe;
        }
      } catch (e) {
        // Bỏ qua lỗi của một nguyên liệu và tiếp tục
        continue;
      }
    }

    final allRecipes = uniqueRecipes.values.toList();

    // 5. Xếp hạng Recipe theo thời gian nấu từ thấp đến cao (durationMinutes ASC)
    final scoredRecipes = allRecipes.map((recipe) {
      int score = 0;
      final recipeIngredientsLower = recipe.ingredients
          .map((i) => i.toLowerCase())
          .toList();

      for (var aiIng in normalizedIngredients) {
        final aiIngLower = aiIng.toLowerCase();
        
        bool isMatch = recipeIngredientsLower.any((recipeIng) =>
            recipeIng.contains(aiIngLower) || aiIngLower.contains(recipeIng));
        
        if (isMatch) {
          score++;
        }
      }
      return _ScoredRecipe(recipe, score);
    }).toList();

    // Sắp xếp thời gian nấu từ thấp tới cao, nếu bằng nhau thì ưu tiên món khớp nhiều nguyên liệu hơn
    scoredRecipes.sort((a, b) {
      final aTime = a.recipe.durationMinutes ?? 999;
      final bTime = b.recipe.durationMinutes ?? 999;
      final timeComp = aTime.compareTo(bTime);
      if (timeComp != 0) return timeComp;
      return b.score.compareTo(a.score);
    });

    return MealRecommendationResult(
      recognizedIngredients: filteredResults,
      recipes: scoredRecipes.map((sr) => sr.recipe).toList(),
    );
  }
}

class _ScoredRecipe {
  final Recipe recipe;
  final int score;
  _ScoredRecipe(this.recipe, this.score);
}
