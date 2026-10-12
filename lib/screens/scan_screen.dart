import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../services/ai/ai_service_factory.dart';
import '../services/ai/meal_recommendation_service.dart';
import '../services/ai/providers/themealdb_recipe_service.dart';

// Nội dung chính của màn hình Quét
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isFlashOn = false;
  bool _isLoading = false;
  File? _selectedImage;
  List<Recipe> _recommendedRecipes = [];
  List<String> _detectedIngredients = [];

  // Khởi tạo AI Services
  late final MealRecommendationService _recommendationService;

  @override
  void initState() {
    super.initState();
    _recommendationService = MealRecommendationService(
      foodRecognitionService: AIServiceFactory.createFoodRecognitionService(),
      recipeService: TheMealDBRecipeService(),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isLoading = true;
        _recommendedRecipes = [];
        _detectedIngredients = [];
      });

      try {
        // Gọi service nhận diện (Confidence > 80%) và gợi ý công thức dưới 15 phút
        final result = await _recommendationService.recommendMeals(
          _selectedImage!,
          minConfidence: 0.8,
          maxDurationMinutes: 15,
        );

        if (!mounted) return;

        setState(() {
          _recommendedRecipes = result.recipes;
          _detectedIngredients = result.recognizedIngredients
              .map((r) => r.foodName)
              .toList();
          _isLoading = false;
        });

        if (_recommendedRecipes.isNotEmpty) {
          _showRecipesDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy nguyên liệu hoặc công thức phù hợp')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }


  void _simulateCapture() {
    _pickImage(ImageSource.camera);
  }

  void _pickFromGallery() {
    _pickImage(ImageSource.gallery);
  }

  void _showRecipesDialog() {
    if (_recommendedRecipes.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Column(
          children: [
            const Text(
              'CÔNG THỨC GỢI Ý',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 30, height: 2, color: const Color(0xFFE5E7EB)),
          ],
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2),
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2),
            ),
          ),
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recommendedRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _recommendedRecipes[index];
              return _buildRecipeItem(
                title: recipe.name,
                info: "${recipe.durationMinutes ?? '--'} phút • ${recipe.ingredients.length} nguyên liệu",
                tag: index == 0 ? "Phù hợp nhất" : "Gợi ý",
                onTap: () => _showRecipeDetailDialog(recipe),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRecipeDetailDialog(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Column(
          children: [
            Text(
              recipe.name.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                fontSize: 16,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "${recipe.durationMinutes ?? '--'} PHÚT",
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(width: 30, height: 2, color: const Color(0xFFE5E7EB)),
          ],
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2),
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NGUYÊN LIỆU',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 8),
                ...recipe.ingredients.map((ing) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text("• $ing", style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                    )),
                const SizedBox(height: 20),
                const Text(
                  'CÁCH LÀM',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 8),
                ...recipe.steps.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text("${entry.key + 1}. ${entry.value}", style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeItem({required String title, required String info, required String tag, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, // Nền item màu trắng để nổi bật trên nền xám sáng của popup
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(info, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(6)),
              child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNutritionDetailDialog(String title) {
    // Logic 4: Popup chi tiết dinh dưỡng (Placeholder)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'CHI TIẾT ${title.toUpperCase()}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.all(10),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF9CA3AF), width: 2),
              right: BorderSide(color: Color(0xFF9CA3AF), width: 2),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Chưa có dữ liệu dinh dưỡng',
                  style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Status Pill Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? const Color(0xFFF59E0B) : const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI VISION 4.2 • ${_isLoading ? "PROCESSING" : "READY"}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF111827), letterSpacing: 0.5),
                ),
                const Spacer(),
                const Icon(Icons.videocam_outlined, color: Color(0xFF6B7280), size: 18),
                const SizedBox(width: 12),
                const Icon(Icons.close, color: Color(0xFF6B7280), size: 18),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Khối Camera
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE5E7EB), Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
                        ),
                      ),
                      child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.restaurant_outlined, size: 80, color: Color(0xFFD1D5DB)),
                          ),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: _pickFromGallery,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: const Icon(Icons.image_outlined, color: Color(0xFF111827), size: 20),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('GALLERY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: _simulateCapture,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF111827), width: 3),
                              ),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(color: Color(0xFF111827), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, color: Color(0xFF4B5563), size: 14),
                                  const SizedBox(width: 4),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('AI ANALYSIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                                      Text(_isLoading ? 'PROCESSING' : 'READY', style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Khối kết quả
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Đã nhận diện', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        const Spacer(),
                        if (_recommendedRecipes.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                            child: const Text('CHỈNH SỬA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _detectedIngredients.isEmpty
                          ? [const Text("Vui lòng quét để nhận diện", style: TextStyle(color: Colors.grey, fontSize: 13))]
                          : _detectedIngredients.map((ing) => Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Text("• $ing", style: const TextStyle(fontWeight: FontWeight.w600)),
                            )).toList(),
                      ),
                    ),


                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNutritionClickable(
                          label: "NĂNG LƯỢNG", value: "--", unit: "KCAL",
                          onTap: () => _showNutritionDetailDialog("Năng lượng"),
                        ),
                        _buildNutritionClickable(
                          label: "PROTEIN", value: "--", unit: "--",
                          onTap: () => _showNutritionDetailDialog("Protein"),
                        ),
                        _buildNutritionClickable(
                          label: "CARBS", value: "--", unit: "--",
                          onTap: () => _showNutritionDetailDialog("Carbs"),
                        ),
                        _buildNutritionClickable(
                          label: "CHẤT BÉO", value: "--", unit: "--",
                          onTap: () => _showNutritionDetailDialog("Chất béo"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _showRecipesDialog,
                        child: const Text('Tạo công thức phù hợp', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionClickable({required String label, required String value, required String unit, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                Text(unit, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
