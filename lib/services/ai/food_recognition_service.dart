import 'dart:io';
import '../../models/food_recognition_result.dart';

abstract class FoodRecognitionService {
  Future<List<FoodRecognitionResult>> recognizeIngredients(File image);
}
