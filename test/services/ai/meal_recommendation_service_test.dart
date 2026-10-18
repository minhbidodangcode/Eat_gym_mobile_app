import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymer_app/models/food_recognition_result.dart';
import 'package:gymer_app/models/recipe.dart';
import 'package:gymer_app/services/ai/food_recognition_service.dart';
import 'package:gymer_app/services/ai/recipe_service.dart';
import 'package:gymer_app/services/ai/meal_recommendation_service.dart';

class MockFoodRecognitionService implements FoodRecognitionService {
  List<FoodRecognitionResult> results = [];
  @override
  Future<List<FoodRecognitionResult>> recognizeIngredients(File image, {double confidence = 0.25}) async {
    return results;
  }
}

class MockRecipeService implements RecipeService {
  Map<String, List<Recipe>> mockData = {};
  @override
  Future<List<Recipe>> getRecipesByIngredient(String ingredient) async {
    return mockData[ingredient] ?? [];
  }
}

void main() {
  late MockFoodRecognitionService mockRecognition;
  late MockRecipeService mockRecipe;
  late MealRecommendationService service;

  setUp(() {
    mockRecognition = MockFoodRecognitionService();
    mockRecipe = MockRecipeService();
    service = MealRecommendationService(
      foodRecognitionService: mockRecognition,
      recipeService: mockRecipe,
    );
  });

  test('Test 1: Only ingredients with confidence >= 0.4 are used', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken Breast', confidence: 0.91),
      FoodRecognitionResult(foodName: 'Yellow Onion', confidence: 0.87),
      FoodRecognitionResult(foodName: 'Mushroom', confidence: 0.35),
    ];

    mockRecipe.mockData = {
      'Ức gà không da': [Recipe(name: 'Chicken Soup', ingredients: ['Ức gà không da'], steps: [])],
      'Hành tây': [Recipe(name: 'Onion Rings', ingredients: ['Hành tây'], steps: [])],
      'Nấm mỡ trắng': [Recipe(name: 'Mushroom Risotto', ingredients: ['Nấm mỡ trắng'], steps: [])],
    };

    final result = await service.recommendMeals(File('dummy.jpg'));

    expect(result.recipes.length, 2);
    expect(result.recipes.any((r) => r.name == 'Chicken Soup'), true);
    expect(result.recipes.any((r) => r.name == 'Onion Rings'), true);
    expect(result.recipes.any((r) => r.name == 'Mushroom Risotto'), false);
    expect(result.recognizedIngredients.length, 2);
  });

  test('Test 2: All confidence < 0.4 returns empty list', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken', confidence: 0.39),
    ];
    final result = await service.recommendMeals(File('dummy.jpg'));
    expect(result.recipes, isEmpty);
    expect(result.recognizedIngredients, isEmpty);
  });

  test('Test 3: Recipes are unique even if matching multiple ingredients', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken', confidence: 0.9),
      FoodRecognitionResult(foodName: 'Onion', confidence: 0.9),
    ];

    final sharedRecipe = Recipe(name: 'Shared Dish', ingredients: ['Ức gà không da', 'hành tây'], steps: []);
    mockRecipe.mockData = {
      'Ức gà không da': [sharedRecipe],
      'Hành tây': [sharedRecipe],
    };

    final result = await service.recommendMeals(File('dummy.jpg'));
    expect(result.recipes.length, 1);
    expect(result.recipes.first.name, 'Shared Dish');
  });

  test('Test 4: Recipes with more matches are ranked higher', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken', confidence: 0.9),
      FoodRecognitionResult(foodName: 'Onion', confidence: 0.9),
    ];

    final recipe1 = Recipe(name: 'Just Chicken', ingredients: ['Ức gà không da'], steps: [], durationMinutes: 10);
    final recipe2 = Recipe(name: 'Chicken & Onion', ingredients: ['Ức gà không da', 'hành tây'], steps: [], durationMinutes: 10);

    mockRecipe.mockData = {
      'Ức gà không da': [recipe1, recipe2],
      'Hành tây': [recipe2],
    };

    final result = await service.recommendMeals(File('dummy.jpg'));
    
    expect(result.recipes.length, 2);
    expect(result.recipes[0].name, 'Chicken & Onion'); // Score 2 (same duration)
    expect(result.recipes[1].name, 'Just Chicken');    // Score 1
  });

  test('Test 5: Only recipes under 15 minutes are recommended', () async {
    mockRecognition.results = [
      FoodRecognitionResult(foodName: 'Chicken Breast', confidence: 0.85),
    ];

    mockRecipe.mockData = {
      'Ức gà không da': [
        Recipe(name: 'Quick Chicken Salad', ingredients: ['Ức gà không da'], steps: [], durationMinutes: 10),
        Recipe(name: '15-Min Stir Fry', ingredients: ['Ức gà không da'], steps: [], durationMinutes: 15),
        Recipe(name: 'Slow Roast Chicken', ingredients: ['Ức gà không da'], steps: [], durationMinutes: 45),
      ],
    };

    final result = await service.recommendMeals(File('dummy.jpg'), maxDurationMinutes: 15);

    expect(result.recipes.length, 2);
    expect(result.recipes.any((r) => r.name == 'Quick Chicken Salad'), true);
    expect(result.recipes.any((r) => r.name == '15-Min Stir Fry'), true);
    expect(result.recipes.any((r) => r.name == 'Slow Roast Chicken'), false);
  });
}
