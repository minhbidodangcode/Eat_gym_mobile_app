import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'cooking_timer_screen.dart';
import '../services/api_service.dart';

class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';
  bool _isLoading = true;
  List<Map<String, dynamic>> _recipes = [];

  final List<String> _filters = ['Tất cả', 'Tăng cơ', 'Giảm mỡ', 'Ít calo', 'Ăn chay', 'Dưới 15 phút'];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await ApiService.getRecipes();
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _displayTitle(String rawTitle) {
    return rawTitle.replaceFirst(RegExp(r'^[\u{1F300}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\s]+', unicode: true), '').trim();
  }

  Widget _buildRecipeLeading(Map<String, dynamic> recipe) {
    if (recipe['icon'] != null && recipe['icon'].toString().trim().isNotEmpty) {
      return Text(recipe['icon'].toString().trim(), style: const TextStyle(fontSize: 30));
    }
    final title = (recipe['title'] ?? '').toString();
    final emojiMatch = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])').firstMatch(title);
    if (emojiMatch != null) {
      return Text(emojiMatch.group(0)!, style: const TextStyle(fontSize: 30));
    }
    final lower = title.toLowerCase();
    if (lower.contains('gà')) return const Text('🍗', style: TextStyle(fontSize: 30));
    if (lower.contains('bò')) return const Text('🥩', style: TextStyle(fontSize: 30));
    if (lower.contains('heo') || lower.contains('lợn') || lower.contains('sườn') || lower.contains('giò')) return const Text('🍖', style: TextStyle(fontSize: 30));
    if (lower.contains('cá')) return const Text('🐟', style: TextStyle(fontSize: 30));
    if (lower.contains('tôm')) return const Text('🦐', style: TextStyle(fontSize: 30));
    if (lower.contains('trứng')) return const Text('🍳', style: TextStyle(fontSize: 30));
    if (lower.contains('phở') || lower.contains('bún') || lower.contains('mì') || lower.contains('miến') || lower.contains('bánh canh')) return const Text('🍜', style: TextStyle(fontSize: 30));
    if (lower.contains('canh') || lower.contains('súp') || lower.contains('soup')) return const Text('🍲', style: TextStyle(fontSize: 30));
    if (lower.contains('cháo') || lower.contains('yến mạch')) return const Text('🥣', style: TextStyle(fontSize: 30));
    if (lower.contains('cơm') || lower.contains('gạo')) return const Text('🍚', style: TextStyle(fontSize: 30));
    if (lower.contains('xôi')) return const Text('🍙', style: TextStyle(fontSize: 30));
    if (lower.contains('salad') || lower.contains('rau') || lower.contains('cải')) return const Text('🥗', style: TextStyle(fontSize: 30));
    if (lower.contains('nấm')) return const Text('🍄', style: TextStyle(fontSize: 30));
    if (lower.contains('đậu')) return const Text('🌱', style: TextStyle(fontSize: 30));
    if (lower.contains('bánh mì') || lower.contains('sandwich') || lower.contains('wrap')) return const Text('🥪', style: TextStyle(fontSize: 30));
    if (lower.contains('khoai') || lower.contains('bắp')) return const Text('🍠', style: TextStyle(fontSize: 30));
    if (lower.contains('sinh tố') || lower.contains('smoothie')) return const Text('🥤', style: TextStyle(fontSize: 30));
    return const Text('🍽️', style: TextStyle(fontSize: 30));
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    final ingredients = recipe['ingredients'] as List? ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recipe['title'] ?? '',
                    style: AppTypography.headline(color: AppColors.onSurface).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (recipe['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      recipe['description'],
                      style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Macro cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge('Calo', '${recipe['kcal']} kcal', AppColors.fire),
                      _buildMacroBadge('Protein', '${recipe['protein']}g', AppColors.primary),
                      _buildMacroBadge('Carbs', '${recipe['carbs']}g', Colors.orange),
                      _buildMacroBadge('Chất béo', '${recipe['fat']}g', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Nguyên liệu cần có (${ingredients.length})', style: AppTypography.titleMedium(color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  ...ingredients.map((ing) {
                    final name = ing['name'] ?? '';
                    final amount = ing['amount'] ?? '';
                    final unit = ing['unit'] ?? '';
                    final notes = ing['notes'] != null ? ' (${ing['notes']})' : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text('$name$notes', style: AppTypography.bodyMedium(color: AppColors.onSurface))),
                          Text('$amount $unit', style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  if (recipe['instructions'] != null) ...[
                    const SizedBox(height: 20),
                    Text('Cách thực hiện', style: AppTypography.titleMedium(color: AppColors.onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recipe['instructions'],
                        style: AppTypography.bodyMedium(color: AppColors.onSurface),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.timer_outlined),
                      label: const Text('BẮT ĐẦU NẤU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CookingTimerScreen(recipe: recipe),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _stripVietnamese(String text) {
    var result = text.toLowerCase();
    result = result.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    result = result.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    result = result.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    result = result.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    result = result.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    result = result.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    result = result.replaceAll(RegExp(r'[đ]'), 'd');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final queryNorm = _stripVietnamese(_searchQuery.trim());
    var filteredRecipes = _recipes.where((r) {
      final title = (r['title'] ?? '').toString();
      final titleNorm = _stripVietnamese(title);
      final tags = (r['tags'] as List? ?? []).map((t) => t.toString()).toList();
      bool matchSearch = queryNorm.isEmpty || titleNorm.contains(queryNorm) || title.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchFilter = _selectedFilter == 'Tất cả' || tags.contains(_selectedFilter);
      return matchSearch && matchFilter;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm món ăn, nguyên liệu...',
              prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedFilter = filter),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          Text('Kết quả (${filteredRecipes.length})', style: AppTypography.titleMedium(color: AppColors.onSurface)),
          const SizedBox(height: 12),

          // Recipe List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRecipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: AppColors.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy món ăn phù hợp',
                              style: AppTypography.bodyMedium(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _loadRecipes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tải lại'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecipes,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = filteredRecipes[index];
                            final tags = (recipe['tags'] as List? ?? []).map((t) => t.toString()).where((t) => t != 'Tất cả').toList();
                            return GestureDetector(
                              onTap: () => _showRecipeDetails(recipe),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.outlineVariant),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: _buildRecipeLeading(recipe),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayTitle(recipe['title'] ?? ''),
                                            style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${recipe['kcal']} kcal • ${recipe['time']} phút • ${recipe['protein']}g Pro',
                                            style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
                                          ),
                                          if (tags.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 4,
                                              children: tags.map((t) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceContainerHigh,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(t, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                                              )).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
