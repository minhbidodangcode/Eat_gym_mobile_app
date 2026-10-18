import 'food_recognition_service.dart';
import 'recipe_service.dart';
import 'providers/local_docker_food_recognition_service.dart';
import 'providers/roboflow_food_recognition_service.dart';
import 'providers/eatgym_backend_recipe_service.dart';

class AIServiceFactory {
  /// Mặc định sử dụng Local Docker AI Service (FastAPI + YOLOv8)
  /// Có thể chuyển sang Roboflow nếu truyền useRoboflow = true
  static FoodRecognitionService createFoodRecognitionService({bool useRoboflow = false}) {
    if (useRoboflow) {
      return RoboflowFoodRecognitionService(
        apiKey: const String.fromEnvironment('ROBOFLOW_API_KEY'),
      );
    }
    return LocalDockerFoodRecognitionService();
  }

  /// Khởi tạo Recipe Service kết nối với CSDL 4,008 món ăn EatGym
  static RecipeService createRecipeService() {
    return EatGymBackendRecipeService();
  }
}

