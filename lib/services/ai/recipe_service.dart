import '../../models/recipe.dart';

abstract class RecipeService {
  Future<List<Recipe>> getRecipesByIngredient(String ingredient);
}
