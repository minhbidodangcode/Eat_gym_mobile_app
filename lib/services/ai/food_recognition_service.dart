import 'dart:io';
import '../../models/food_recognition_result.dart';

abstract class FoodRecognitionService {
  Future<List<FoodRecognitionResult>> recognizeIngredients(File image, {double confidence = 0.25});

  /// Nhận diện đĩa thức ăn đã nấu chín, bóc tách tên món, khối lượng gram và 4 chỉ số Macro
  Future<Map<String, dynamic>> recognizeCookedDish(File image);
}
