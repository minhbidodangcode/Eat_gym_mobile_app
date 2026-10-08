import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'cooking_timer_screen.dart';

class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';

  final List<String> _filters = ['Tất cả', 'Tăng cơ', 'Giảm mỡ', 'Ít calo', 'Ăn chay', 'Dưới 15 phút'];

  final List<Map<String, dynamic>> _recipes = [
    {
      'title': '🍗 Ức gà áp chảo sốt cam',
      'kcal': 450,
      'time': 20,
      'tags': ['Tăng cơ'],
      'image': Icons.set_meal,
    },
    {
      'title': '🥗 Salad gà & bông cải xanh',
      'kcal': 320,
      'time': 15,
      'tags': ['Giảm mỡ', 'Ít calo', 'Dưới 15 phút'],
      'image': Icons.eco,
    },
    {
      'title': '🍲 Soup gà rau củ giải nhiệt',
      'kcal': 280,
      'time': 30,
      'tags': ['Ít calo'],
      'image': Icons.soup_kitchen,
    },
    {
      'title': '🌯 Wrap gà ngũ cốc',
      'kcal': 380,
      'time': 10,
      'tags': ['Tăng cơ', 'Dưới 15 phút'],
      'image': Icons.fastfood,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Lọc công thức
    var filteredRecipes = _recipes.where((r) {
      bool matchSearch = r['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchFilter = _selectedFilter == 'Tất cả' || (r['tags'] as List).contains(_selectedFilter);
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
                    label: Text(filter, style: TextStyle(
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
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
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return GestureDetector(
                  onTap: () {
                    // Mở trang nấu ăn
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: SafeArea(child: CookingTimerScreen()),
                        )
                      ),
                    );
                  },
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
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(recipe['image'] as IconData, size: 32, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recipe['title'], style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${recipe['kcal']} kcal • ${recipe['time']} phút', style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                children: (recipe['tags'] as List<String>).map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(t, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                                )).toList(),
                              ),
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
        ],
      ),
    );
  }
}
