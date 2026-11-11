import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import 'cooking_timer_screen.dart';
import 'recipe_search_screen.dart';
import 'scan_screen.dart';

class SearchExploreScreen extends StatefulWidget {
  const SearchExploreScreen({super.key});

  @override
  State<SearchExploreScreen> createState() => _SearchExploreScreenState();
}

class _SearchExploreScreenState extends State<SearchExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0; // 0: FoodBlogs, 1: Món ăn, 2: Nguyên liệu
  String _selectedMacroFilter = 'Tất cả';
  String _selectedSuggestion = '';
  List<Map<String, dynamic>> _results = [];

  final List<String> _segmentedTabs = ['FoodBlogs', 'Món ăn', 'Nguyên liệu'];
  
  final List<String> _macroFilters = [
    'Tất cả',
    'High Protein (>30g)',
    'Low Carb (<20g)',
    'Calo < 500 kcal',
    'Dưới 20 phút',
  ];

  final List<String> _gymSuggestions = [
    'Ức gà',
    'Bò xào',
    'Yến mạch',
    'Salad',
    'Sinh tố whey',
    'Cá hồi',
  ];

  // Danh sách mẫu chuẩn EatGym theo thiết kế Figma
  final List<Map<String, dynamic>> _mockResults = [
    {
      'id': 'mock_1',
      'title': 'Bò xào măng tây tiêu đen',
      'category': 'Món ăn',
      'calories': 420,
      'protein': 45.0,
      'carbs': 12.0,
      'fat': 10.0,
      'time': '15 phút',
      'badge': 'HIGH PROTEIN',
      'badgeColor': Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800',
      'author': 'HLV Tuấn Anh',
      'description': 'Món ăn giàu đạm hỗ trợ phục hồi và phát triển cơ bắp tối đa sau buổi tập chân nặng.',
    },
    {
      'id': 'mock_2',
      'title': 'Yến mạch ngâm qua đêm chuối quế',
      'category': 'FoodBlogs',
      'calories': 380,
      'protein': 22.0,
      'carbs': 55.0,
      'fat': 6.0,
      'time': '5 phút',
      'badge': 'CLEAN CARB',
      'badgeColor': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=800',
      'author': 'Mai Linh EatClean',
      'description': 'Bữa sáng nhanh gọn nạp carb phức hợp hấp thu chậm, giữ năng lượng ổn định cả ngày.',
    },
    {
      'id': 'mock_3',
      'title': 'Pancake chuối yến mạch protein',
      'category': 'Món ăn',
      'calories': 410,
      'protein': 32.0,
      'carbs': 48.0,
      'fat': 8.0,
      'time': '20 phút',
      'badge': 'TĂNG CƠ',
      'badgeColor': Color(0xFFF97316),
      'image': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800',
      'author': 'Gymmer Pro',
      'description': 'Bánh pancake thơm xốp không đường bột tinh luyện, bổ sung 1 scoop whey protein isolate.',
    },
    {
      'id': 'mock_4',
      'title': 'Salad ức gà áp chảo sốt mè rang',
      'category': 'Món ăn',
      'calories': 350,
      'protein': 40.0,
      'carbs': 15.0,
      'fat': 9.0,
      'time': '15 phút',
      'badge': 'GIẢM MỠ',
      'badgeColor': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800',
      'author': 'Chef Nam Fit',
      'description': 'Ức gà mềm ngọt thơm mùi lá thyme, kết hợp xà lách Romaine giòn ngọt và sốt mè thanh nhẹ.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _results = List.from(_mockResults);
    _loadApiRecipes();
  }

  Future<void> _loadApiRecipes() async {
    try {
      final recipes = await ApiService.getRecipes();
      if (recipes.isNotEmpty && mounted) {
        setState(() {
          final apiItems = recipes.take(15).map((r) {
            final title = r['title'] ?? r['name'] ?? 'Món ăn Gymer';
            final calories = (r['calories'] is num) ? (r['calories'] as num).round() : 350;
            final protein = (r['protein'] is num) ? (r['protein'] as num).toDouble() : 30.0;
            return {
              'id': r['id']?.toString() ?? '',
              'title': title,
              'category': 'Món ăn',
              'calories': calories,
              'protein': protein,
              'carbs': (r['carbs'] is num) ? (r['carbs'] as num).toDouble() : 25.0,
              'fat': (r['fat'] is num) ? (r['fat'] as num).toDouble() : 8.0,
              'time': '${r['cooking_time'] ?? 20} phút',
              'badge': protein >= 35 ? 'HIGH PROTEIN' : 'BALANCED',
              'badgeColor': protein >= 35 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              'image': RecipeImageDatabase.resolveImage(title, existingImage: r['image_url']),
              'author': r['author'] ?? 'Cộng đồng EatGym',
              'description': r['description'] ?? 'Công thức chuẩn macro dinh dưỡng cho người tập thể hình.',
            };
          }).toList();

          _results = [..._mockResults, ...apiItems];
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredResults {
    return _results.where((item) {
      // 1. Lọc theo search input
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final desc = (item['description'] ?? '').toString().toLowerCase();
        if (!title.contains(query) && !desc.contains(query)) return false;
      }

      // 2. Lọc theo suggestion chip
      if (_selectedSuggestion.isNotEmpty) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        if (!title.contains(_selectedSuggestion.toLowerCase())) return false;
      }

      // 3. Lọc theo Macro
      if (_selectedMacroFilter == 'High Protein (>30g)') {
        final protein = (item['protein'] as num?)?.toDouble() ?? 0.0;
        if (protein < 30.0) return false;
      } else if (_selectedMacroFilter == 'Low Carb (<20g)') {
        final carbs = (item['carbs'] as num?)?.toDouble() ?? 0.0;
        if (carbs >= 20.0) return false;
      } else if (_selectedMacroFilter == 'Calo < 500 kcal') {
        final calo = (item['calories'] as num?)?.toDouble() ?? 999.0;
        if (calo >= 500.0) return false;
      } else if (_selectedMacroFilter == 'Dưới 20 phút') {
        final timeStr = item['time']?.toString() ?? '';
        final minutes = int.tryParse(RegExp(r'\d+').firstMatch(timeStr)?.group(0) ?? '99') ?? 99;
        if (minutes > 20) return false;
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadApiRecipes,
          color: primaryAccent,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. THANH TÌM KIẾM TƯƠNG TÁC (Interactive Search Input Bar - fill: #ECF5FE)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECF5FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF000000),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm công thức, món ăn, gymer...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF5B5F63),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setState(() {});
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. SEGMENTED TABS SELECTOR (Tabs: FoodBlogs | Món ăn | Nguyên liệu - fill: #E6EFF8)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6EFF8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: List.generate(_segmentedTabs.length, (index) {
                        final isSelected = _selectedTabIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF0F172A) : const Color(0xFF000000))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                _segmentedTabs[index],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // 3. BỘ LỌC MACRO & THỜI GIAN (Macro & Time Filter Pill Badges)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _macroFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _macroFilters[index];
                      final isSelected = _selectedMacroFilter == filter;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMacroFilter = isSelected ? 'Tất cả' : filter;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF000000))
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E9F2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filter,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF5B5F63)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. GỢI Ý GYMER THỊNH HÀNH (Trending / Gym Suggestions)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'GỢI Ý GYMER THỊNH HÀNH',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _gymSuggestions.map((sug) {
                          final isSelected = _selectedSuggestion == sug;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSuggestion = isSelected ? '' : sug;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? Colors.white : const Color(0xFF000000))
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFECF5FE)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2)),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                sug,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. BANNER DISCOVERY HELPER (Quick Action Drawer: Bắt đầu tính Macro & Scan AI)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECF5FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFF000000),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quét món ăn AI & Tính Macro',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Chụp ảnh món ăn để ước tính ngay calo và protein',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScanScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : const Color(0xFF000000),
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Quét',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. TIÊU ĐỀ KẾT QUẢ TÌM KIẾM (Search Results Header: SẮP XẾP: TỐI ƯU MACRO)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SẮP XẾP: TỐI ƯU MACRO',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                        ),
                      ),
                      Text(
                        '${_filteredResults.length} kết quả',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 7. DANH SÁCH THẺ MÓN ĂN (Results Cards Stack)
              if (_filteredResults.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy công thức phù hợp',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B5F63),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _filteredResults[index];
                      return _buildRecipeCard(item, isDark);
                    },
                    childCount: _filteredResults.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> item, bool isDark) {
    final title = item['title'] ?? '';
    final calories = item['calories'] ?? 350;
    final protein = item['protein'] ?? 30.0;
    final carbs = item['carbs'] ?? 20.0;
    final fat = item['fat'] ?? 8.0;
    final time = item['time'] ?? '15 phút';
    final badge = item['badge'] ?? 'FITNESS';
    final badgeColor = item['badgeColor'] as Color? ?? const Color(0xFF10B981);
    final image = item['image'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () {
          // Mở màn hình nấu ăn Cooking Timer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CookingTimerScreen(
                recipe: {
                  'id': item['id'],
                  'title': title,
                  'calories': calories,
                  'protein': protein,
                  'carbs': carbs,
                  'fat': fat,
                  'time': 20,
                  'cooking_time_min': 20,
                },
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E9F2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh món ăn
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image != null && image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              // Thông tin chi tiết
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge nhãn & Thời gian
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Tên món ăn
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Macro tags: Calo | Protein | Carb | Fat
                    Row(
                      children: [
                        _buildMacroPill('$calories kcal', isDark ? Colors.white70 : const Color(0xFF0F172A), isDark),
                        const SizedBox(width: 6),
                        _buildMacroPill('${protein}g đạm', const Color(0xFF10B981), isDark),
                        const SizedBox(width: 6),
                        _buildMacroPill('${carbs}g carb', const Color(0xFF3B82F6), isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPill(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
