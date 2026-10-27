import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badges_and_report_model.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'badges_and_report_screen.dart';
import 'login_screen.dart';
import 'recipe_search_screen.dart';
import 'settings_screen.dart';
import 'update_body_stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? authorData;
  const ProfileScreen({super.key, this.authorData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  // Trạng thái Theo dõi (đối với trang cá nhân của người khác)
  bool _isFollowing = false;

  // Dữ liệu tùy chỉnh của người dùng (Bio, Link, Tên, Username)
  String _customBio = '';
  String _customLink = '';
  String _customName = '';
  String _customUsername = '';
  String _customGoal = '';

  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _savedPosts = [];
  List<Map<String, dynamic>> _likedPosts = [];
  Set<String> _likedRecipeIds = {};
  Set<String> _savedRecipeIds = {};

  static const String _userPostsKey = 'eatgym_user_created_recipes_v2';
  static const String _savedRecipesKey = 'eatgym_saved_recipes_ids_v1';
  static const String _likedRecipesKey = 'eatgym_liked_recipes_ids_v1';

  // Thông tin các đầu bếp nổi tiếng trên hệ thống EatGym
  static final Map<String, Map<String, String>> _knownChefs = {
    'chef_vietanh_eatclean': {
      'fullName': 'HLV Việt Anh (Eat Clean Pro)',
      'bio': 'Bếp trưởng EatGym Kitchen 👨‍🍳\nChia sẻ công thức Meal Prep chuẩn khoa học, tối ưu macros cho gymer siết mỡ tăng cơ. 🥑🍗',
      'link': 'eatgym.ai/chef/@chef_vietanh',
      'followers': '18.4K',
      'following': '142',
      'badge': 'HLV Dinh Dưỡng • NASM Certified',
    },
    'gymer_bepnha': {
      'fullName': 'Thu Hà (Gymer Bếp Nhà)',
      'bio': 'Hộp cơm văn phòng Eat Clean tiện lợi mỗi ngày cho dân tập gym 🍱💪\nNấu nhanh dưới 15 phút, cân bằng dưỡng chất, không ngấy!',
      'link': 'eatgym.ai/chef/@gymer_bepnha',
      'followers': '14.2K',
      'following': '98',
      'badge': 'EatClean Chef • Bếp Gymer',
    },
    'coach_nam_nutrition': {
      'fullName': 'Coach Nam (Fitness & Nutrition)',
      'bio': 'HLV Thể hình & Chuyên gia Dinh dưỡng Thể thao 🏋️‍♂️⚡\nTối ưu hóa Protein & Phục hồi cơ bắp đỉnh cao.',
      'link': 'eatgym.ai/coach/@coach_nam',
      'followers': '25.6K',
      'following': '180',
      'badge': 'Fitness Pro • Coach',
    },
    'fitfoodie_vietnam': {
      'fullName': 'Fit Foodie Vietnam',
      'bio': 'Ẩm thực Healthy chuẩn vị Việt Nam 🇻🇳🥗\nĂn ngon không sợ béo, thâm hụt calo lành mạnh mỗi ngày.',
      'link': 'eatgym.ai/channel/@fitfoodie_vn',
      'followers': '31.0K',
      'following': '210',
      'badge': 'Healthy Kitchen • Sáng Tạo',
    },
    'eatgym_official': {
      'fullName': 'EatGym Kitchen Official 🥦🤖',
      'bio': 'Kênh công thức nấu ăn thông minh chính thức từ EatGym App.\nTự động gợi ý thực đơn chuẩn macros theo nguyên liệu tủ lạnh của bạn.',
      'link': 'eatgym.ai/official',
      'followers': '54.2K',
      'following': '12',
      'badge': 'Bếp Trưởng EatGym AI',
    },
  };


  bool get _isMe {
    if (widget.authorData == null) return true;
    final isMine = widget.authorData!['isMine'] == true;
    final authorName = widget.authorData!['authorName']?.toString() ?? '';
    return isMine || authorName == 'Bạn (Gymer)' || authorName == 'Bạn';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileAndPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndPosts() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Đọc thông tin mô tả và tiểu sử tùy chỉnh đã lưu
      _customBio = prefs.getString('user_bio') ?? '';
      _customLink = prefs.getString('user_profile_link') ?? '';
      _customName = prefs.getString('user_full_name') ?? '';
      _customUsername = prefs.getString('user_custom_username') ?? '';
      _customGoal = prefs.getString('user_custom_goal') ?? '';

      // 1. Lấy thông tin user profile
      final profile = await ApiService.getLocalProfile();
      _userProfile = profile;

      // 2. Lấy dữ liệu công thức từ RecipeSearchScreenState hoặc SharedPreferences
      final recipeState = RecipeSearchScreen.recipeScreenKey.currentState;

      final savedList = prefs.getStringList(_savedRecipesKey) ?? [];
      final likedList = prefs.getStringList(_likedRecipesKey) ?? [];
      _savedRecipeIds = Set<String>.from(recipeState?.savedRecipeIds ?? savedList);
      _likedRecipeIds = Set<String>.from(recipeState?.likedRecipeIds ?? likedList);

      // Danh sách tất cả bài feed
      List<Map<String, dynamic>> allFeedPosts = [];
      if (recipeState != null && recipeState.feedPosts.isNotEmpty) {
        allFeedPosts = List<Map<String, dynamic>>.from(recipeState.feedPosts);
      }

      if (_isMe) {
        // TRANG CÁ NHÂN CỦA BẢN THÂN
        if (recipeState != null && recipeState.userPosts.isNotEmpty) {
          _userPosts = List<Map<String, dynamic>>.from(recipeState.userPosts);
        } else {
          final userPostsJson = prefs.getString(_userPostsKey);
          if (userPostsJson != null && userPostsJson.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(userPostsJson);
            _userPosts = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          } else {
            _userPosts = [
              {
                'id': 'user_recipe_sample_1',
                'title': 'Ức gà áp chảo sốt bơ tỏi của tôi',
                'time': 20,
                'difficulty': 'Dễ',
                'kcal': 360,
                'protein': 44,
                'carbs': 8,
                'fat': 10,
                'image': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
                'description': 'Công thức bí quyết áp chảo lửa vừa giúp ức gà giữ trọn độ mềm mọng nước, không bị khô xơ!',
                'authorName': 'Bạn (Gymer)',
                'authorAvatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                'authorBadge': 'Gymer Tác Giả',
                'location': 'EatGym Kitchen • Bếp Của Tôi',
                'postedTime': '1 ngày trước',
                'isMine': true,
                'baseLikes': 12,
                'commentsCount': 3,
                'ingredients': [
                  {'name': 'Ức gà tươi', 'amount': '250g'},
                  {'name': 'Bơ lạt Anchor', 'amount': '15g'},
                  {'name': 'Tỏi băm & tiêu', 'amount': '2 tép'},
                ],
                'steps': [
                  {'step': 'Khứa nhẹ bề mặt ức gà, ướp tiêu muối trong 5 phút.', 'timeMinutes': 5},
                  {'step': 'Làm nóng chảo, áp chảo mỗi mặt 4-5 phút cho vàng giòn.', 'timeMinutes': 10},
                  {'step': 'Cho bơ tỏi vào rưới đều lên bề mặt và tắt bếp.', 'timeMinutes': 5},
                ],
              }
            ];
          }
        }

        if (allFeedPosts.isEmpty) {
          allFeedPosts = List<Map<String, dynamic>>.from(_userPosts);
        }

        _savedPosts = allFeedPosts.where((p) => _savedRecipeIds.contains(p['id'])).toList();
        _likedPosts = allFeedPosts.where((p) => _likedRecipeIds.contains(p['id'])).toList();
      } else {
        // TRANG CÁ NHÂN CỦA NGƯỜI KHÁC / ĐẦU BẾP
        final authorName = widget.authorData!['authorName']?.toString() ?? 'chef_vietanh_eatclean';
        _isFollowing = prefs.getBool('follow_$authorName') ?? false;

        // 1. Công thức đã đăng của tác giả này
        final authorPosts = allFeedPosts.where((p) => p['authorName'] == authorName).toList();
        if (authorPosts.isNotEmpty) {
          _userPosts = authorPosts;
        } else {
          // Nếu feed chưa có đủ, nạp các công thức đặc trưng của tác giả
          _userPosts = [
            Map<String, dynamic>.from(widget.authorData!),
            ...allFeedPosts.take(3).map((p) {
              final copy = Map<String, dynamic>.from(p);
              copy['authorName'] = authorName;
              copy['authorAvatar'] = widget.authorData!['authorAvatar'];
              return copy;
            }),
          ];
        }

        // 2. Công thức đã lưu (Bộ sưu tập các món ăn tâm đắc của tác giả)
        _savedPosts = allFeedPosts.where((p) => p['authorName'] != authorName).take(6).toList();
        if (_savedPosts.isEmpty) {
          _savedPosts = List<Map<String, dynamic>>.from(_userPosts);
        }

        // 3. Món yêu thích nhất của tác giả
        _likedPosts = _userPosts.where((p) => (p['baseLikes'] as num? ?? 0) > 50).toList();
        if (_likedPosts.isEmpty) {
          _likedPosts = List<Map<String, dynamic>>.from(_userPosts);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onCreateRecipe() {
    final recipeState = RecipeSearchScreen.recipeScreenKey.currentState;
    if (recipeState != null) {
      recipeState.showCreateRecipeSheet(customContext: context);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadProfileAndPosts();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng mở tab FoodBlog trước để đồng bộ hệ thống công thức!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onOpenRecipeDetails(Map<String, dynamic> post) {
    final recipeState = RecipeSearchScreen.recipeScreenKey.currentState;
    if (recipeState != null) {
      recipeState.showRecipeDetails(post, customContext: context);
    } else {
      _showSimpleRecipeModal(post);
    }
  }

  void _showSimpleRecipeModal(Map<String, dynamic> post) {
    final ingredients = post['ingredients'] as List? ?? [];
    final steps = post['steps'] as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF191C1B) : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
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
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: _buildPostImage(post['image']),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                post['title'] ?? '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🔥 ${post['kcal'] ?? 350} kcal  •  🍗 ${post['protein'] ?? 35}g Protein  •  🍚 ${post['carbs'] ?? 15}g Carbs  •  🥑 ${post['fat'] ?? 8}g Fat',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? primaryAccent : AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                post['description'] ?? post['tips'] ?? 'Công thức nấu ăn chuẩn Eat Clean cho Gymer.',
                style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155)),
              ),
              if (ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Nguyên liệu:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                ...ingredients.map((ing) {
                  final name = ing['name'] ?? '';
                  final amount = ing['amount'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: isDark ? primaryAccent : AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(name.toString(), style: TextStyle(color: isDark ? const Color(0xFFE1E3E1) : null))),
                        Text(amount.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFE1E3E1) : null)),
                      ],
                    ),
                  );
                }),
              ],
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Các bước thực hiện:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                ...steps.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: isDark ? primaryAccent : AppColors.primary,
                            child: Text('${e.key + 1}', style: TextStyle(fontSize: 11, color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.value['step']?.toString() ?? '', style: TextStyle(color: isDark ? const Color(0xFFE1E3E1) : null))),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPostActionsSheet(Map<String, dynamic> post) {
    final isMine = post['isMine'] == true || _userPosts.any((p) => p['id'] == post['id'] && _isMe);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF191C1B) : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.visibility_outlined, color: isDark ? Colors.white : null),
              title: Text('Xem chi tiết công thức', style: TextStyle(color: isDark ? const Color(0xFFE1E3E1) : null)),
              onTap: () {
                Navigator.pop(ctx);
                _onOpenRecipeDetails(post);
              },
            ),
            if (isMine) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.orange),
                title: const Text('Chỉnh sửa công thức', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(ctx);
                  final recipeState = RecipeSearchScreen.recipeScreenKey.currentState;
                  recipeState?.showEditRecipeSheet(post, customContext: context);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) _loadProfileAndPosts();
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Gỡ công thức khỏi trang cá nhân', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePost(post['id']);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Chia sẻ bài đăng'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép liên kết công thức!'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(String id) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Xác nhận gỡ bài?'),
        content: const Text('Công thức này sẽ bị xóa khỏi trang cá nhân và bảng tin FoodBlog.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dCtx);
              final recipeState = RecipeSearchScreen.recipeScreenKey.currentState;
              recipeState?.deleteUserPost(id);

              setState(() {
                _userPosts.removeWhere((p) => p['id'] == id);
              });

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_userPostsKey, jsonEncode(_userPosts));

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gỡ bài đăng thành công!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Gỡ bài'),
          ),
        ],
      ),
    );
  }

  // Chức năng: Chỉnh sửa trang cá nhân (Sửa mô tả / bio, tên, username, website)
  void _showEditProfileModal() {
    final profile = _userProfile;
    final currentFullName = _customName.isNotEmpty
        ? _customName
        : (profile?['fullName'] ?? profile?['full_name'] ?? 'Minh Bi (Gymer Chef)');
    final currentUsername = _customUsername.isNotEmpty
        ? _customUsername
        : (profile?['username'] ?? 'minhbi_gymer');
    final currentBio = _customBio.isNotEmpty
        ? _customBio
        : (profile?['bio'] ?? profile?['description'] ?? 'Bếp ăn Gymer: Nấu nhanh, chuẩn macros, kỷ luật mỗi ngày 💪🥗');
    final currentLink = _customLink.isNotEmpty
        ? _customLink
        : (profile?['website']?.toString() ?? '');
    final currentGoal = _customGoal.isNotEmpty
        ? _customGoal
        : (profile?['fitnessGoal']?.toString() ?? 'Tăng cơ giảm mỡ');

    final nameController = TextEditingController(text: currentFullName);
    final usernameController = TextEditingController(text: currentUsername);
    final bioController = TextEditingController(text: currentBio);
    final linkController = TextEditingController(text: currentLink);
    String selectedGoal = currentGoal;

    final goals = [
      'Tăng cơ giảm mỡ',
      'Giảm cân giữ cơ',
      'Tăng cân tăng cơ',
      'Duy trì vóc dáng & Sức khỏe',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF191C1B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF191C1B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh kéo modal
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Top Header: [Hủy] - Chỉnh sửa trang cá nhân - [Lưu]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(bCtx),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Chỉnh sửa trang cá nhân',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        final newUsername = usernameController.text.trim();
                        final newBio = bioController.text.trim();
                        final newLink = linkController.text.trim();

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('user_full_name', newName);
                        await prefs.setString('user_custom_username', newUsername);
                        await prefs.setString('user_bio', newBio);
                        await prefs.setString('user_profile_link', newLink);
                        await prefs.setString('user_custom_goal', selectedGoal);

                        // Đồng bộ hồ sơ người dùng
                        final updatedProfile = Map<String, dynamic>.from(_userProfile ?? {});
                        updatedProfile['fullName'] = newName;
                        updatedProfile['username'] = newUsername;
                        updatedProfile['bio'] = newBio;
                        updatedProfile['description'] = newBio;
                        updatedProfile['website'] = newLink;
                        updatedProfile['fitnessGoal'] = selectedGoal;
                        await ApiService.saveLocalProfile(updatedProfile);

                        if (mounted) {
                          setState(() {
                            _customName = newName;
                            _customUsername = newUsername;
                            _customBio = newBio;
                            _customLink = newLink;
                            _customGoal = selectedGoal;
                            _userProfile = updatedProfile;
                          });
                          Navigator.pop(bCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✨ Đã cập nhật thông tin trang cá nhân thành công!'),
                              backgroundColor: Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Lưu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? primaryAccent : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),

                Divider(height: 16, color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),

                // Form chỉnh sửa cuộn được
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar và nút Đổi ảnh
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryAccent,
                                      primaryAccent.withValues(alpha: 0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryAccent.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? const Color(0xFF191C1B) : Colors.white,
                                  ),
                                  child: ClipOval(
                                    child: _buildAvatarImageWidget(
                                      SettingsService.instance.userAvatarNotifier.value,
                                      size: 72,
                                      primaryAccent: primaryAccent,
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                                    if (picked != null) {
                                      await SettingsService.instance.setUserAvatar(picked.path);
                                      setModalState(() {});
                                      if (mounted) setState(() {});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✨ Đã cập nhật ảnh đại diện mới thành công!'), behavior: SnackBarBehavior.floating),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Không thể chọn ảnh: $e'), behavior: SnackBarBehavior.floating),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  'Đổi ảnh đại diện',
                                  style: TextStyle(
                                    color: isDark ? primaryAccent : const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Trường 1: Tên hiển thị
                        Text(
                          'Tên hiển thị:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                          cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                          decoration: InputDecoration(
                            hintText: 'Nhập họ và tên...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                            isDense: true,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Trường 2: Tên người dùng (Username)
                        Text(
                          'Tên người dùng (Username):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: usernameController,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                          cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                          decoration: InputDecoration(
                            prefixText: '@ ',
                            prefixStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 14),
                            hintText: 'username',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                            isDense: true,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Trường 3: Tiểu sử / Mô tả trang cá nhân (Bio)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mô tả trang cá nhân (Tiểu sử / Bio):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Hỗ trợ xuống dòng • Tối đa 500 ký tự',
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: bioController,
                          minLines: 3,
                          maxLines: 6,
                          maxLength: 500,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w500),
                          cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                          decoration: InputDecoration(
                            hintText: 'Giới thiệu bản thân, phong cách nấu nướng Eat Clean, mục tiêu thể hình...\n• Hỗ trợ viết nhiều dòng tự do\n• Thể hiện cá tính Gymer',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            isDense: true,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Trường 4: Nhiều liên kết / Mạng xã hội
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Liên kết & Mạng xã hội:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Mỗi liên kết một dòng',
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: linkController,
                          minLines: 2,
                          maxLines: 5,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w600),
                          cursorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                          decoration: InputDecoration(
                            hintText: 'Nhập các liên kết (mỗi dòng 1 link):\nfacebook.com/username\ninstagram.com/username\ntiktok.com/@username\nyoutube.com/@channel',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                            isDense: true,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? primaryAccent : const Color(0xFF0F172A), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Trường 5: Mục tiêu thể hình
                        Text(
                          'Mục tiêu thể hình:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: goals.contains(selectedGoal) ? selectedGoal : goals.first,
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF1E2420) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                              items: goals.map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500)),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedGoal = val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),

                        // Lối tắt: Chỉnh sửa số đo 3 vòng & cân nặng (tiện lợi cho gymer)
                        InkWell(
                          onTap: () {
                            Navigator.pop(bCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UpdateBodyStatsScreen()),
                            ).then((_) => _loadProfileAndPosts());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.straighten_outlined, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Chỉnh sửa số đo 3 vòng & cân nặng',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Cập nhật chỉ số cơ thể, tỷ lệ mỡ, chiều cao...',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Đăng xuất tài khoản?'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi EatGym không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pop(dCtx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: AppColors.surfaceContainerLow,
        child: const Icon(Icons.restaurant, color: Colors.grey, size: 28),
      );
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceContainerLow,
          child: const Icon(Icons.restaurant, color: Colors.grey, size: 28),
        ),
      );
    }
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceContainerLow,
          child: const Icon(Icons.restaurant, color: Colors.grey, size: 28),
        ),
      );
    }
    return Container(
      color: AppColors.surfaceContainerLow,
      child: const Icon(Icons.restaurant, color: Colors.grey, size: 28),
    );
  }

  Widget _buildAvatarImageWidget(String url, {required double size, required Color primaryAccent, required bool isDark}) {
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: isDark ? const Color(0xFF151B18) : const Color(0xFFF1F5F9),
      child: Icon(Icons.person, color: primaryAccent, size: size * 0.45),
    );

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
      );
    }
    final file = File(url);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return fallback;
  }

  Widget _buildStatColumn(String count, String label, {bool isDark = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = _isMe;
    final profile = _userProfile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = SettingsService.instance.currentColor;

    // TÍNH TOÁN DỮ LIỆU HIỂN THỊ
    String displayName = '';
    String displayUsername = '';
    String displayAvatar = '';
    String displayBadge = '';
    String displayBio = '';
    String displayLink = '';
    String statPosts = '${_userPosts.length}';
    String statFollowers = '12.4K';
    String statFollowing = '148';

    if (isMe) {
      final baseFullName = profile?['fullName'] ?? profile?['full_name'] ?? 'Minh Bi (Gymer Chef)';
      displayName = _customName.isNotEmpty ? _customName : baseFullName;
      final rawUsername = (displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')).replaceAll(RegExp(r'[^a-z0-9_]'), '');
      displayUsername = _customUsername.isNotEmpty ? _customUsername : (rawUsername.isNotEmpty ? rawUsername : 'gymer_chef');
      displayAvatar = SettingsService.instance.userAvatarNotifier.value;
      displayBadge = 'Gymer Tác Giả • Master Chef';
      displayBio = _customBio.isNotEmpty
          ? _customBio
          : (profile?['bio'] ?? profile?['description'] ?? 'Bếp ăn Gymer: Nấu nhanh, chuẩn macros, kỷ luật mỗi ngày 💪🥗');
      // Tự do viết bio link: Không ép cứng eatgym.ai nếu người dùng chưa nhập
      displayLink = _customLink.isNotEmpty ? _customLink : (profile?['website']?.toString() ?? '');

      final badgeModel = BadgesAndReportModel.instance;
      final streak = badgeModel.streakDays > 0 ? badgeModel.streakDays : 7;
      statPosts = '${_userPosts.length}';
      statFollowers = '${_likedRecipeIds.length} đã tim';
      statFollowing = '$streak ngày';
    } else {
      final authorData = widget.authorData ?? {};
      final authorKey = authorData['authorName']?.toString() ?? 'chef_vietanh_eatclean';
      final chefInfo = _knownChefs[authorKey];

      displayUsername = authorKey;
      displayName = chefInfo?['fullName'] ?? authorData['authorName'] ?? 'Đầu Bếp EatGym';
      displayAvatar = authorData['authorAvatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';
      displayBadge = chefInfo?['badge'] ?? authorData['authorBadge'] ?? 'HLV Dinh Dưỡng';
      displayBio = chefInfo?['bio'] ?? 'Chia sẻ công thức nấu ăn Eat Clean lành mạnh, giàu protein cho cộng đồng Gymer 💪🥗';
      displayLink = chefInfo?['link'] ?? (authorData['link']?.toString() ?? '');
      statPosts = '${_userPosts.length}';
      statFollowers = chefInfo?['followers'] ?? '16.5K';
      statFollowing = chefInfo?['following'] ?? '120';
    }

    final weight = (profile?['weightKg'] as num?)?.toDouble() ?? 72.0;
    final height = (profile?['heightCm'] as num?)?.toDouble() ?? 175.0;
    final goal = _customGoal.isNotEmpty ? _customGoal : (profile?['fitnessGoal']?.toString() ?? 'Tăng cơ giảm mỡ');

    final bool isLbs = SettingsService.instance.unitWeightNotifier.value == 'lbs';
    final bool isFtIn = SettingsService.instance.unitHeightNotifier.value == 'ft_in';
    final String weightDisplay = isLbs ? '${(weight * 2.20462).toStringAsFixed(1)} lbs' : '${weight.toStringAsFixed(1)} kg';
    final String heightDisplay = isFtIn ? '${(height / 30.48).floor()} ft ${((height % 30.48) / 2.54).round()} in' : '${height.toStringAsFixed(0)} cm';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E0D) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0E0D) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe) ...[
              Icon(Icons.lock_outline, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A)),
              const SizedBox(width: 4),
            ],
            // Sử dụng Flexible + ellipsis để tên dài không bao giờ bị tràn/lỗi font
            Flexible(
              child: Text(
                displayUsername,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 15, color: Color(0xFF3897F0)),
            if (isMe) Icon(Icons.keyboard_arrow_down, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A)),
          ],
        ),
        actions: [
          if (isMe) ...[
            // NÚT [+] THÊM CÔNG THỨC (CỦA BẢN THÂN)
            IconButton(
              icon: Icon(Icons.add_box_outlined, size: 24, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              tooltip: 'Thêm công thức mới',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: _onCreateRecipe,
            ),
            // Nút Cài đặt hệ thống
            IconButton(
              icon: Icon(Icons.settings_outlined, size: 22, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              tooltip: 'Cài đặt hệ thống',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
            // Nút Đăng xuất
            IconButton(
              icon: Icon(Icons.logout_rounded, size: 21, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              tooltip: 'Đăng xuất',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: _confirmLogout,
            ),
            const SizedBox(width: 4),
          ] else ...[
            // Nút Chia sẻ trang cá nhân tác giả
            IconButton(
              icon: Icon(Icons.share_outlined, size: 22, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              tooltip: 'Chia sẻ trang cá nhân',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã sao chép liên kết trang cá nhân của @$displayUsername!'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // 1. DÒNG THÔNG TIN AVATAR + 3 CỘT STATS (INSTAGRAM STYLE)
                          Row(
                            children: [
                              // Avatar sạch sẽ, hiện đại (Đã bỏ viền story)
                              Container(
                                width: 84,
                                height: 84,
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryAccent, width: 2),
                                ),
                                child: ClipOval(
                                  child: _buildAvatarImageWidget(
                                    displayAvatar,
                                    size: 79,
                                    primaryAccent: primaryAccent,
                                    isDark: isDark,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 24),

                              // 3 Cột Stats: Bài viết, Người theo dõi / Đã tim, Đang theo dõi / Kỷ luật
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn(statPosts, 'Bài viết', isDark: isDark),
                                    _buildStatColumn(statFollowers, isMe ? 'Đã tim' : 'Người theo dõi', isDark: isDark),
                                    _buildStatColumn(statFollowing, isMe ? 'Kỷ luật' : 'Đang theo dõi', isDark: isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 2. PHẦN TIỂU SỬ (BIO) & MÔ TẢ (Chữ đậm, sắc nét, không bị mờ)
                          Text(
                            displayName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),

                          // Huy hiệu Gym Rank / Chef Title
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.military_tech, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  displayBadge,
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),

                          if (isMe) ...[
                            const SizedBox(height: 6),
                            Text(
                              '🎯 Mục tiêu: $goal • $weightDisplay • $heightDisplay',
                              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155), fontWeight: FontWeight.w500),
                            ),
                          ],

                          const SizedBox(height: 6),

                          // Bio slogan / Mô tả trang cá nhân (Hỗ trợ nhiều dòng, màu đậm sắc nét)
                          Text(
                            displayBio,
                            style: TextStyle(fontSize: 13, height: 1.45, color: isDark ? const Color(0xFFE1E3E1) : const Color(0xFF1E293B)),
                          ),

                          // Danh sách nhiều liên kết (Multiple Bio Links)
                          Builder(
                            builder: (context) {
                              final List<String> rawLinks = displayLink
                                  .split('\n')
                                  .expand((l) => l.split(','))
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();

                              if (rawLinks.isEmpty) {
                                if (!isMe) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: GestureDetector(
                                    onTap: _showEditProfileModal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_link, size: 15, color: isDark ? primaryAccent : const Color(0xFF2563EB)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+ Thêm liên kết (Bio Link)',
                                          style: TextStyle(fontSize: 12.5, color: isDark ? primaryAccent : const Color(0xFF2563EB), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: rawLinks.map((link) {
                                    IconData linkIcon = Icons.link_rounded;
                                    Color linkColor = isDark ? primaryAccent : const Color(0xFF2563EB);
                                    final lower = link.toLowerCase();
                                    if (lower.contains('facebook') || lower.contains('fb.com')) {
                                      linkIcon = Icons.facebook;
                                      linkColor = const Color(0xFF1877F2);
                                    } else if (lower.contains('instagram') || lower.contains('instagr.am')) {
                                      linkIcon = Icons.camera_alt_outlined;
                                      linkColor = const Color(0xFFE1306C);
                                    } else if (lower.contains('youtube') || lower.contains('youtu.be')) {
                                      linkIcon = Icons.play_circle_fill_rounded;
                                      linkColor = const Color(0xFFFF0000);
                                    } else if (lower.contains('tiktok')) {
                                      linkIcon = Icons.music_note_rounded;
                                      linkColor = isDark ? const Color(0xFFE1E3E1) : const Color(0xFF0F172A);
                                    }

                                    return InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Đang mở liên kết: $link',
                                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF0F172A),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF151B18) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(linkIcon, size: 14, color: linkColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              link,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: linkColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          // 3. DÃY NÚT HÀNH ĐỘNG (INSTAGRAM PROFILE BUTTONS)
                          if (isMe)
                            Row(
                              children: [
                                // Nút 1: CHỈNH SỬA TRANG CÁ NHÂN
                                Expanded(
                                  flex: 5,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                      side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
                                      padding: const EdgeInsets.symmetric(vertical: 8.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _showEditProfileModal,
                                    child: Text('Chỉnh sửa trang cá nhân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Nút 2: [+] Thêm công thức
                                Expanded(
                                  flex: 4,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                                      foregroundColor: isDark ? Colors.black : Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 8.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _onCreateRecipe,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Thêm công thức', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Nút 3: Báo cáo y khoa / PDF icon
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.assignment_outlined, size: 20, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    tooltip: 'Huy hiệu & Báo cáo PDF',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const BadgesAndReportScreen(isSubPage: true)),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                // Nút 1: Theo dõi / Đang theo dõi
                                Expanded(
                                  flex: 5,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFollowing
                                          ? (isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC))
                                          : (isDark ? primaryAccent : const Color(0xFF0F172A)),
                                      foregroundColor: _isFollowing
                                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                          : (isDark ? Colors.black : Colors.white),
                                      elevation: 0,
                                      side: _isFollowing
                                          ? BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1))
                                          : BorderSide.none,
                                      padding: const EdgeInsets.symmetric(vertical: 8.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      final authorKey = widget.authorData?['authorName'] ?? 'chef';
                                      setState(() {
                                        _isFollowing = !_isFollowing;
                                      });
                                      await prefs.setBool('follow_$authorKey', _isFollowing);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(_isFollowing ? 'Đã theo dõi @$displayUsername' : 'Đã hủy theo dõi @$displayUsername'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: _isFollowing
                                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                            : (isDark ? Colors.black : Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Nút 2: Nhắn tin
                                Expanded(
                                  flex: 4,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                      side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
                                      padding: const EdgeInsets.symmetric(vertical: 8.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đang mở hộp thoại trò chuyện với @$displayUsername...'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Text('Nhắn tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Nút 3: Chia sẻ
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.share_outlined, size: 20, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    tooltip: 'Chia sẻ tác giả',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã sao chép liên kết trang @$displayUsername!'), behavior: SnackBarBehavior.floating),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),

                  // 5. STICKY TAB BAR: [▦ Công thức đã đăng] [🔖 Công thức đã lưu] [♡ Món yêu thích]
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _InstagramTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                        indicatorWeight: 2,
                        labelColor: isDark ? primaryAccent : const Color(0xFF0F172A),
                        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.grid_on_sharp, size: 22),
                            text: 'Đã đăng',
                          ),
                          Tab(
                            icon: Icon(Icons.bookmark_border, size: 22),
                            text: 'Đã lưu',
                          ),
                          Tab(
                            icon: Icon(Icons.favorite_border, size: 22),
                            text: 'Đã tim',
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: CÔNG THỨC ĐÃ ĐĂNG
                  _buildPostsGrid(_userPosts, isMyPostsTab: true, authorName: displayName),

                  // TAB 2: CÔNG THỨC ĐÃ LƯU
                  _buildSavedPostsGrid(authorName: displayName),

                  // TAB 3: MÓN ĐÃ TIM
                  _buildLikedPostsGrid(authorName: displayName),
                ],
              ),
            ),
    );
  }

  /// Tab 1: Grid công thức đã đăng (Chuẩn Instagram Profile)
  Widget _buildPostsGrid(List<Map<String, dynamic>> posts, {required bool isMyPostsTab, required String authorName}) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.onSurface, width: 2),
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 38, color: AppColors.onSurface),
              ),
              const SizedBox(height: 16),
              Text(
                _isMe ? 'Chia sẻ công thức đầu tiên' : 'Chưa có công thức đã đăng',
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isMe
                    ? 'Khi bạn sáng tạo công thức nấu ăn, chúng sẽ xuất hiện ở đây trên trang cá nhân của bạn.'
                    : '$authorName chưa đăng tải công thức nấu ăn nào.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (_isMe) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: _onCreateRecipe,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm công thức ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, idx) {
        final post = posts[idx];
        final protein = post['protein'] ?? 40;
        final likes = post['baseLikes'] ?? 1;

        return GestureDetector(
          onTap: () => _onOpenRecipeDetails(post),
          onLongPress: () => _showPostActionsSheet(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPostImage(post['image']),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⚡ ${protein}g P',
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.favorite, size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            '$likes',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab 2: Grid công thức đã lưu (Yêu cầu 2: thấy công thức đã lưu cả bản thân và người khác)
  Widget _buildSavedPostsGrid({required String authorName}) {
    if (_savedPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(Icons.bookmark_border, size: 38, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có công thức đã lưu',
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isMe
                    ? 'Nhấn biểu tượng lưu 🔖 trên bất kỳ công thức nào ở FoodBlog để lưu lại đây.'
                    : '$authorName chưa lưu bộ sưu tập công thức nào.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      itemCount: _savedPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, idx) {
        final post = _savedPosts[idx];
        return GestureDetector(
          onTap: () => _onOpenRecipeDetails(post),
          onLongPress: () => _showPostActionsSheet(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPostImage(post['image']),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bookmark, size: 13, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    post['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab 3: Grid món ăn đã tim (Favorites)
  Widget _buildLikedPostsGrid({required String authorName}) {
    if (_likedPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 2),
                ),
                child: const Icon(Icons.favorite_border, size: 38, color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có món ăn đã tim',
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isMe
                    ? 'Bấm biểu tượng tim ❤️ trên các bài đăng ở tab FoodBlog để lưu các món yêu thích vào đây!'
                    : '$authorName chưa có món ăn yêu thích nào.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      itemCount: _likedPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, idx) {
        final post = _likedPosts[idx];
        return GestureDetector(
          onTap: () => _onOpenRecipeDetails(post),
          onLongPress: () => _showPostActionsSheet(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPostImage(post['image']),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, size: 13, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InstagramTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _InstagramTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1.0;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0B0E0D) : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 0.5, color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
          tabBar,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_InstagramTabBarDelegate oldDelegate) {
    return true;
  }
}
