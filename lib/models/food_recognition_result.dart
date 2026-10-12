class FoodRecognitionResult {
  final String foodName;
  final double confidence;

  FoodRecognitionResult({
    required this.foodName,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'confidence': confidence,
    };
  }

  factory FoodRecognitionResult.fromJson(Map<String, dynamic> json) {
    return FoodRecognitionResult(
      foodName: json['foodName'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'FoodRecognitionResult(foodName: $foodName, confidence: $confidence)';
}
