class VoiceIngredientResult {
  final String name;
  final String rawSpokenText;
  final String icon;
  int weight;
  final String unit;
  final int kcalPer100g;
  final double protein;
  final double carbs;
  final double fat;
  final String category;
  bool isSelected;

  VoiceIngredientResult({
    required this.name,
    required this.rawSpokenText,
    required this.icon,
    this.weight = 100,
    this.unit = 'g',
    required this.kcalPer100g,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.category = 'other',
    this.isSelected = true,
  });

  int get totalCalories => ((kcalPer100g * weight) / 100).round();
  double get totalProtein => ((protein * weight) / 100);
  double get totalCarbs => ((carbs * weight) / 100);
  double get totalFat => ((fat * weight) / 100);

  Map<String, dynamic> toIngredientItem() {
    return {
      'name': name,
      'icon': icon,
      'weight': weight,
      'kcalPer100g': kcalPer100g,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'category': category,
    };
  }

  // Tương thích ngược
  Map<String, dynamic> toCartItem() => toIngredientItem();

  Map<String, dynamic> toInventoryItem() {
    return {
      'name': name,
      'quantity': weight,
      'unit': unit,
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'category': category,
      'icon': icon,
    };
  }
}
