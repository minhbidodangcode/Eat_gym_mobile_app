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
    int maxDurationMinutes = 15,
  }) async {
    // 1. Nhận diện nguyên liệu từ ảnh (Gọi 1 lần duy nhất)
    final recognitionResults = await foodRecognitionService.recognizeIngredients(image);

    // 2. Lọc confidence >= 0.4 (Confidence Score > 40%)
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
          // 5. Lọc gợi ý công thức dưới 15 phút (durationMinutes <= 15)
          if (recipe.durationMinutes != null && recipe.durationMinutes! > maxDurationMinutes) {
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

    // 6. Xếp hạng Recipe theo mức độ phù hợp (Score)
    final scoredRecipes = allRecipes.map((recipe) {
      int score = 0;
      final recipeIngredientsLower = recipe.ingredients
          .map((i) => i.toLowerCase())
          .toList();

      for (var aiIng in normalizedIngredients) {
        final aiIngLower = aiIng.toLowerCase();
        
        // Kiểm tra xem nguyên liệu AI có trong danh sách nguyên liệu của Recipe không
        bool isMatch = recipeIngredientsLower.any((recipeIng) =>
            recipeIng.contains(aiIngLower) || aiIngLower.contains(recipeIng));
        
        if (isMatch) {
          score++;
        }
      }
      return _ScoredRecipe(recipe, score);
    }).toList();

    // Sort giảm dần theo score
    scoredRecipes.sort((a, b) => b.score.compareTo(a.score));

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
