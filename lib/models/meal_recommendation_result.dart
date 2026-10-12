import 'food_recognition_result.dart';
import 'recipe.dart';

class MealRecommendationResult {
  final List<FoodRecognitionResult> recognizedIngredients;
  final List<Recipe> recipes;

  MealRecommendationResult({
    required this.recognizedIngredients,
    required this.recipes,
  });
}
