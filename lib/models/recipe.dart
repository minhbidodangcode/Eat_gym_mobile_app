class Recipe {
  final String name;
  final List<String> ingredients;
  final List<String> steps;
  final int? durationMinutes;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.steps,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ingredients': ingredients,
      'steps': steps,
      'durationMinutes': durationMinutes,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'] as String,
      ingredients: List<String>.from(json['ingredients'] as List),
      steps: List<String>.from(json['steps'] as List),
      durationMinutes: json['durationMinutes'] as int?,
    );
  }

  @override
  String toString() {
    return 'Recipe(name: $name, duration: ${durationMinutes ?? "N/A"}m, ingredients: ${ingredients.length} items)';
  }
}
