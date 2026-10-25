import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

import '../services/api_service.dart';

import '../services/ai/ai_service_factory.dart';

import '../services/ai/ingredient_normalizer.dart';

import '../widgets/voice_ingredient_sheet.dart';

import '../models/voice_ingredient_result.dart';

import 'cooking_timer_screen.dart';

import '../main.dart';

/// Helper tự động phân loại nguyên liệu vào Ngăn Đông hoặc Ngăn Mát

class FridgeClassifier {

  static const String freezer = 'freezer'; // Ngăn đông (-18°C)

  static const String cooler = 'cooler';   // Ngăn mát (4°C)

  static String classify(String name, {String? category}) {

    final lower = name.toLowerCase().trim();

    final catLower = (category ?? '').toLowerCase().trim();

    // Thịt, cá, hải sản, đồ đông lạnh -> Ngăn đông

    final freezerKeywords = [

      'thịt', 'bò', 'heo', 'gà', 'lợn', 'cá', 'tôm', 'mực', 'cua',

      'hải sản', 'sườn', 'băm', 'phi lê', 'nghêu', 'sò', 'ốc', 'vịt',

      'lạp xưởng', 'chả lụa', 'xúc xích', 'kem', 'đông lạnh', 'beef',

      'pork', 'chicken', 'fish', 'shrimp', 'crab', 'seafood', 'steak',

      'meat', 'salmon', 'tuna', 'chops', 'ribs', 'duck', 'lamb'

    ];

    for (final kw in freezerKeywords) {

      if (lower.contains(kw)) {

        return freezer;

      }

    }

    if (catLower == 'protein' && (lower.contains('thịt') || lower.contains('cá') || lower.contains('tôm'))) {

      return freezer;

    }

    // Mặc định rau củ, quả, trứng, sữa, nước sốt, gia vị, đậu hũ -> Ngăn mát

    return cooler;

  }

}

/// Màn hình Tủ Lạnh Thông Minh EatGym (Thay thế trang quét)

class SmartFridgeScreen extends StatefulWidget {

  // Đồng bộ với session của app

  static List<Map<String, dynamic>> sessionIngredients = [];

  const SmartFridgeScreen({super.key});

  @override

  State<SmartFridgeScreen> createState() => _SmartFridgeScreenState();

}

class _SmartFridgeScreenState extends State<SmartFridgeScreen> with SingleTickerProviderStateMixin {
  static List<Map<String, dynamic>>? _cachedAllRecipes;


  static const String _prefsKey = 'eatgym_smart_fridge_items_v4';

  List<Map<String, dynamic>> _fridgeItems = [];

  final Set<String> _selectedItemIds = {};

  bool _isLoading = true;

  bool _isFridgeDoorOpen = true; // Trạng thái mở cánh tủ lạnh

  late AnimationController _doorAnimController;

  late Animation<double> _doorAnimation;

  @override

  void initState() {

    super.initState();

    _doorAnimController = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 600),

    );

    _doorAnimation = CurvedAnimation(

      parent: _doorAnimController,

      curve: Curves.easeInOutBack,

    );

    _doorAnimController.value = 1.0; // Mặc định mở cửa

    _loadFridgeItems();

  }

  @override

  void dispose() {

    _doorAnimController.dispose();

    super.dispose();

  }

  /// Tải danh sách nguyên liệu từ bộ nhớ máy hoặc pre-seed

  Future<void> _loadFridgeItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final loaded = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        final updatedList = <Map<String, dynamic>>[];

        for (var item in loaded) {
          var n = (item['name'] ?? '').toString().trim();
          var lower = n.toLowerCase();

          // 0. Bỏ Nhãn hộp
          if (lower.contains('nhãn hộp')) {
            continue;
          }

          // 1. Đổi hết heo -> lợn
          if (lower.contains('heo')) {
            n = n.replaceAll('heo', 'lợn').replaceAll('Heo', 'Lợn');
            item['name'] = n;
            lower = n.toLowerCase();
          }

          // 2. Đổi thơm -> dứa (trừ dầu mè thơm)
          if (lower.contains('thơm') && !lower.contains('dầu mè')) {
            n = n.replaceAll('thơm', 'dứa').replaceAll('Thơm', 'Dứa');
            item['name'] = n;
            lower = n.toLowerCase();
          }

          // 3. Chuẩn hóa tên chung chung
          if (lower == 'nước ngọt') {
            item['name'] = 'CocaCola';
            item['icon'] = '🥤';
            item['unit'] = 'lon';
            item['kcalPer100g'] = 42;
          } else if (lower == 'nước sốt') {
            item['name'] = 'Sốt cà chua';
            item['icon'] = '🥫';
            item['unit'] = 'hũ';
            item['kcalPer100g'] = 80;
          } else if (lower == 'hải sản') {
            item['name'] = 'Mực ống tươi';
            item['icon'] = '🦑';
            item['kcalPer100g'] = 85;
          } else if (lower == 'cá') {
            item['name'] = 'Phi lê cá hồi';
            item['icon'] = '🐟';
            item['kcalPer100g'] = 208;
          } else if (lower == 'tôm') {
            item['name'] = 'Tôm thẻ tươi';
            item['icon'] = '🦐';
            item['kcalPer100g'] = 99;
          } else if (lower == 'thịt bò') {
            item['name'] = 'Thịt thăn bò';
            item['icon'] = '🥩';
          } else if (lower == 'thịt heo' || lower == 'thịt lợn') {
            item['name'] = 'Thịt nạc lợn';
            item['icon'] = '🐖';
          }

          // 4. Chuẩn hóa icon theo tên nguyên liệu cụ thể
          final detected = IngredientNormalizer.detectIcon(item['name'] ?? '');
          if (detected != '🥗') {
            item['icon'] = detected;
          } else if (item['icon'] == null || item['icon'].toString().isEmpty) {
            item['icon'] = detected;
          }
          updatedList.add(item);
        }

        _fridgeItems = updatedList;
        _saveFridgeItems();
      } else {
        // Khởi tạo sẵn một số món mẫu phổ biến trong tủ lạnh gymer (tên cụ thể, icon chuẩn)
        _fridgeItems = [
          // Ngăn đông (Hàng 1)
          {
            'id': 'f_1',
            'name': 'Thịt thăn bò',
            'icon': '🥩',
            'weight': 500,
            'unit': 'g',
            'compartment': FridgeClassifier.freezer,
            'kcalPer100g': 142,
            'protein': 26,
            'carbs': 0,
            'fat': 3.5,
          },
          {
            'id': 'f_2',
            'name': 'Thịt nạc lợn',
            'icon': '🐖',
            'weight': 400,
            'unit': 'g',
            'compartment': FridgeClassifier.freezer,
            'kcalPer100g': 143,
            'protein': 26,
            'carbs': 0,
            'fat': 3.5,
          },
          {
            'id': 'f_3',
            'name': 'Ức gà tươi',
            'icon': '🍗',
            'weight': 600,
            'unit': 'g',
            'compartment': FridgeClassifier.freezer,
            'kcalPer100g': 120,
            'protein': 26,
            'carbs': 0,
            'fat': 1.5,
          },
          {
            'id': 'f_4',
            'name': 'Phi lê cá hồi',
            'icon': '🐟',
            'weight': 350,
            'unit': 'g',
            'compartment': FridgeClassifier.freezer,
            'kcalPer100g': 208,
            'protein': 22,
            'carbs': 0,
            'fat': 13,
          },

          // Ngăn đông (Hàng 2)
          {
            'id': 'f_5',
            'name': 'Tôm thẻ tươi',
            'icon': '🦐',
            'weight': 300,
            'unit': 'g',
            'compartment': FridgeClassifier.freezer,
            'kcalPer100g': 99,
            'protein': 24,
            'carbs': 0.2,
            'fat': 0.3,
          },
          {
            'id': 'f_6',
            'name': 'Mực ống tươi',
            'icon': '🦑',
            'weight': 300,
            'unit': 'g',
            'compartment': FridgeClassifier.freezer,
            'kcalPer100g': 85,
            'protein': 18,
            'carbs': 1.4,
            'fat': 1.1,
          },
          {
            'id': 'f_7',
            'name': 'Đá viên tinh khiết',
            'icon': '🧊',
            'weight': 1,
            'unit': 'khay',
            'compartment': FridgeClassifier.freezer,
            'kcalPer100g': 0,
            'protein': 0,
            'carbs': 0,
            'fat': 0,
          },
          {
            'id': 'f_8',
            'name': 'Kem sữa chua',
            'icon': '🍦',
            'weight': 1,
            'unit': 'hộp',
            'compartment': FridgeClassifier.freezer,
            'kcalPer100g': 120,
            'protein': 3.5,
            'carbs': 18,
            'fat': 3.0,
          },

          // Ngăn mát - Kệ 1 (Sữa trứng protein)
          {
            'id': 'c_1',
            'name': 'Trứng gà ta',
            'icon': '🥚',
            'weight': 10,
            'unit': 'quả',
            'compartment': FridgeClassifier.cooler,
            'kcalPer100g': 155,
            'protein': 13,
            'carbs': 1.1,
            'fat': 11,
          },
          {
            'id': 'c_2',
            'name': 'Sữa tươi tiệt trùng',
            'icon': '🥛',
            'weight': 1000,
            'unit': 'ml',
            'compartment': FridgeClassifier.cooler,
            'kcalPer100g': 60,
            'protein': 3.2,
            'carbs': 4.8,
            'fat': 3.3,
          },
          {
            'id': 'c_3',
            'name': 'Phô mai lát',
            'icon': '🧀',
            'weight': 200,
            'unit': 'g',
            'compartment': FridgeClassifier.cooler,
            'kcalPer100g': 350,
            'protein': 20,
            'carbs': 2.0,
            'fat': 28,
          },
          {
            'id': 'c_4',
            'name': 'Bơ lạt',
            'icon': '🧈',
            'weight': 200,
            'unit': 'g',
            'compartment': FridgeClassifier.cooler,
            'kcalPer100g': 717,
            'protein': 0.8,
            'carbs': 0.1,
            'fat': 81,
          },

          // Ngăn mát - Kệ 2 (Đồ uống & Sốt tương)
          {
            'id': 'c_5',
            'name': 'Tương cà chua',
            'icon': '🥫',
            'weight': 1,
            'unit': 'chai',
            'compartment': FridgeClassifier.cooler,
            'kcalPer100g': 102,
            'protein': 1.2,
            'carbs': 24,
            'fat': 0.2,
          },
          {
            'id': 'c_6',
            'name': 'Sữa chua dâu',
            'icon': '🍓',
            'weight': 4,
            'unit': 'hũ',
            'compartment': FridgeClassifier.cooler,
            'kcalPer100g': 85,
            'protein': 3.5,
            'carbs': 14,
            'fat': 1.5,
          },
          {
            'id': 'c_7',
            'name': 'Sốt cà chua',
            'icon': '🥫',
            'weight': 1,
            'unit': 'hũ',
            'compartment': FridgeClassifier.cooler,
            'kcalPer100g': 80,
            'protein': 1.5,
            'carbs': 14,
            'fat': 1.0,
          },
          {
            'id': 'c_8',
            'name': 'CocaCola',
            'icon': '🥤',
            'weight': 2,
            'unit': 'lon',
            'compartment': FridgeClassifier.cooler,
            'kcalPer100g': 42,
            'protein': 0,
            'carbs': 10.6,
            'fat': 0,
          },

          // Ngăn mát - Hộc rau quả trái (Rau xanh & Củ)
          {
            'id': 'v_1',
            'name': 'Bông cải xanh',
            'icon': '🥦',
            'weight': 1,
            'unit': 'cây',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 0,
            'kcalPer100g': 34,
            'protein': 2.8,
            'carbs': 7,
            'fat': 0.4,
          },
          {
            'id': 'v_2',
            'name': 'Cải thìa',
            'icon': '🥬',
            'weight': 1,
            'unit': 'bó',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 0,
            'kcalPer100g': 13,
            'protein': 1.5,
            'carbs': 2.2,
            'fat': 0.2,
          },
          {
            'id': 'v_3',
            'name': 'Cà chua bi',
            'icon': '🍅',
            'weight': 500,
            'unit': 'g',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 0,
            'kcalPer100g': 18,
            'protein': 0.9,
            'carbs': 3.9,
            'fat': 0.2,
          },
          {
            'id': 'v_4',
            'name': 'Cà rốt',
            'icon': '🥕',
            'weight': 1,
            'unit': 'củ',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 0,
            'kcalPer100g': 41,
            'protein': 0.9,
            'carbs': 10,
            'fat': 0.2,
          },
          {
            'id': 'v_5',
            'name': 'Tỏi',
            'icon': '🧄',
            'weight': 1,
            'unit': 'củ',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 0,
            'kcalPer100g': 149,
            'protein': 6.4,
            'carbs': 33,
            'fat': 0.5,
          },

          // Ngăn mát - Hộc rau quả phải (Trái cây & Hành củ)
          {
            'id': 'v_6',
            'name': 'Hành tây',
            'icon': '🧅',
            'weight': 1,
            'unit': 'củ',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 1,
            'kcalPer100g': 40,
            'protein': 1.1,
            'carbs': 9,
            'fat': 0.1,
          },
          {
            'id': 'v_7',
            'name': 'Táo đỏ',
            'icon': '🍎',
            'weight': 1,
            'unit': 'quả',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 1,
            'kcalPer100g': 52,
            'protein': 0.3,
            'carbs': 14,
            'fat': 0.2,
          },
          {
            'id': 'v_8',
            'name': 'Chuối tiêu',
            'icon': '🍌',
            'weight': 1,
            'unit': 'nải',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 1,
            'kcalPer100g': 89,
            'protein': 1.1,
            'carbs': 23,
            'fat': 0.3,
          },
          {
            'id': 'v_9',
            'name': 'Cam sành',
            'icon': '🍊',
            'weight': 1,
            'unit': 'quả',
            'compartment': FridgeClassifier.cooler,
            'isDrawer': true,
            'drawerIndex': 1,
            'kcalPer100g': 47,
            'protein': 0.9,
            'carbs': 12,
            'fat': 0.1,
          },
        ];

        _saveFridgeItems();
      }
    } catch (_) {}

    _syncToGlobalSession();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _saveFridgeItems() async {

    try {

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_prefsKey, jsonEncode(_fridgeItems));

    } catch (_) {}

    _syncToGlobalSession();

  }

  void _syncToGlobalSession() {

    SmartFridgeScreen.sessionIngredients = List<Map<String, dynamic>>.from(_fridgeItems);

    CameraScanContent.sessionIngredients = List<Map<String, dynamic>>.from(_fridgeItems);

  }

  void _toggleItemSelection(String id) {

    setState(() {

      if (_selectedItemIds.contains(id)) {

        _selectedItemIds.remove(id);

      } else {

        _selectedItemIds.add(id);

      }

    });

  }

  void _selectAllInCompartment(String compartment) {

    final items = _fridgeItems.where((i) => i['compartment'] == compartment).toList();

    final allSelected = items.every((i) => _selectedItemIds.contains(i['id']));

    setState(() {

      for (final item in items) {

        if (allSelected) {

          _selectedItemIds.remove(item['id']);

        } else {

          _selectedItemIds.add(item['id'] as String);

        }

      }

    });

  }

  void _addItemToFridge({

    required String name,

    required String icon,

    required int weight,

    String unit = 'g',

    String? explicitCompartment,

    int? kcal,

    int? protein,

    int? carbs,

    int? fat,

  }) {

    final details = IngredientNormalizer.getIngredientDetails(name);

    final comp = explicitCompartment ?? FridgeClassifier.classify(name);

    final newItem = {

      'id': 'fridge_${DateTime.now().millisecondsSinceEpoch}_${_fridgeItems.length}',

      'name': details['vi']?.toString() ?? name,

      'icon': details['icon']?.toString() ?? icon,

      'weight': weight,

      'unit': unit,

      'compartment': comp,

      'kcalPer100g': kcal ?? (details['kcal'] as num?)?.toInt() ?? 100,

      'protein': protein ?? (details['protein'] as num?)?.toInt() ?? 15,

      'carbs': carbs ?? (details['carbs'] as num?)?.toInt() ?? 5,

      'fat': fat ?? (details['fat'] as num?)?.toInt() ?? 3,

    };

    setState(() {

      _fridgeItems.insert(0, newItem);

      _selectedItemIds.add(newItem['id'] as String); // Tự động chọn món vừa thêm

    });

    _saveFridgeItems();

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(

          'Đã cất ${newItem['icon']?.toString().startsWith('assets/') == true ? '' : '${newItem['icon']} '}${newItem['name']} vào ${comp == FridgeClassifier.freezer ? "❄️ NGĂN ĐÔNG" : "🍃 NGĂN MÁT"}!',

        ),

        backgroundColor: comp == FridgeClassifier.freezer ? Colors.lightBlue : AppColors.primary,

        behavior: SnackBarBehavior.floating,

        duration: const Duration(seconds: 2),

      ),

    );

  }

  /// Lấy icon chuẩn xác cho nguyên liệu, tự động sửa icon lỗi hoặc mặc định salad
  String _getItemIcon(Map<String, dynamic> item) {
    final currentIcon = item['icon']?.toString();
    if (currentIcon != null && (currentIcon.startsWith('assets/') || currentIcon.endsWith('.png'))) {
      return currentIcon;
    }
    final name = (item['name'] ?? '').toString();
    final detected = IngredientNormalizer.detectIcon(name);
    if (detected != '🥗') {
      return detected;
    }
    if (currentIcon != null && currentIcon.isNotEmpty) {
      return currentIcon;
    }
    return '🥗';
  }

  Widget _buildItemIconWidget(Map<String, dynamic> item, {double size = 22}) {
    final name = (item['name'] ?? '').toString().toLowerCase();
    final icon = _getItemIcon(item);
    String? assetPath;

    if (icon.startsWith('assets/') || icon.endsWith('.png')) {
      assetPath = icon;
    } else if (name.contains('thanh long')) {
      assetPath = 'assets/icons/thanh_long.png';
    } else if (name.contains('dầu ô liu') || name.contains('olive')) {
      assetPath = 'assets/icons/dau_o_liu.png';
    } else if (name.contains('dầu mè') || name.contains('dầu ăn') || name.contains('dầu thực vật') || (name.contains('dầu') && !name.contains('hào'))) {
      assetPath = 'assets/icons/dau_an.png';
    } else if (name.contains('hạnh nhân') || name.contains('almond')) {
      assetPath = 'assets/icons/hat_hanh_nhan.png';
    } else if (name.contains('óc chó') || name.contains('walnut')) {
      assetPath = 'assets/icons/hat_oc_cho.png';
    } else if (name.contains('hạt điều') || name.contains('cashew')) {
      assetPath = 'assets/icons/hat_dieu.png';
    } else if (name.contains('hạt chia') || name.contains('chia')) {
      assetPath = 'assets/icons/hat_chia.png';
    } else if ((name.contains('mè') || name.contains('vừng') || name.contains('sesame')) && !name.contains('cá') && !name.contains('dầu')) {
      assetPath = 'assets/icons/me.png';
    } else if (name.contains('xì dầu') || name.contains('nước tương') || name.contains('soy sauce')) {
      assetPath = 'assets/icons/xi_dau.png';
    } else if (name.contains('ớt')) {
      assetPath = 'assets/icons/ot_tuoi.png';
    } else if (name.contains('tương cà') || name.contains('ketchup')) {
      assetPath = 'assets/icons/tuong_ca.png';
    } else if (name.contains('tương ớt') || name.contains('chili sauce') || name.contains('sriracha')) {
      assetPath = 'assets/icons/tuong_ot.png';
    } else if (name.contains('tương đen') || name.contains('hoisin')) {
      assetPath = 'assets/icons/tuong_den.png';
    } else if (name.contains('sốt mayonnaise') || name.contains('sốt mè rang') || name.contains('mayo')) {
      assetPath = 'assets/icons/sot_mayo.png';
    } else if (name.contains('sả')) {
      assetPath = 'assets/icons/sa.png';
    } else if (name.contains('rượu')) {
      assetPath = 'assets/icons/ruou_trang.png';
    } else if (name.contains('dầu hào')) {
      assetPath = 'assets/icons/dau_hao.png';
    } else if (name.contains('ngó sen')) {
      assetPath = 'assets/icons/ngo_sen.png';
    } else if (name.contains('măng tây')) {
      assetPath = 'assets/icons/mang_tay.png';
    } else if (name.contains('bắp cải trắng') || (name.contains('bắp cải') && !name.contains('tím'))) {
      assetPath = 'assets/icons/bap_cai_trang.png';
    } else if (name.contains('nấm hương') || name.contains('nấm đông cô') || name.contains('shiitake')) {
      assetPath = 'assets/icons/nam_huong.png';
    } else if (name.contains('nước mắm') || name.contains('fish sauce')) {
      assetPath = 'assets/icons/nuoc_mam.png';
    } else if (name.contains('giấm táo') || name.contains('apple cider')) {
      assetPath = 'assets/icons/giam_tao.png';
    } else if (name.contains('cari') || name.contains('cà ri') || name.contains('curry')) {
      assetPath = 'assets/icons/cari_bot.png';
    } else if (name.contains('nấm kim châm')) {
      assetPath = 'assets/icons/nam_kim_cham.png';
    } else if (name.contains('nấm rơm')) {
      assetPath = 'assets/icons/nam_rom.png';
    } else if (name.contains('nấm đùi gà')) {
      assetPath = 'assets/icons/nam_dui_ga.png';
    } else if (name.contains('giá đỗ')) {
      assetPath = 'assets/icons/gia_do.png';
    } else if (name.contains('bắp cải tím')) {
      assetPath = 'assets/icons/bap_cai_tim.png';
    } else if (name.contains('vải hộp') || name.contains('vải đóng hộp')) {
      assetPath = 'assets/icons/vai_hop.png';
    } else if (name.contains('khoai tây chiên')) {
      assetPath = 'assets/icons/khoai_tay_chien.png';
    } else if (name.contains('khoai tây') || name.contains('potato')) {
      assetPath = 'assets/icons/khoai_tay.png';
    } else if (name.contains('khoai môn') || name.contains('taro')) {
      assetPath = 'assets/icons/khoai_mon.png';
    } else if (name.contains('dứa đóng hộp') || name.contains('dứa hộp')) {
      assetPath = 'assets/icons/dua_hop.png';
    } else if (name.contains('củ sắn') || name.contains('khoai mì')) {
      assetPath = 'assets/icons/cu_san.png';
    } else if (name.contains('mứt đu đủ')) {
      assetPath = 'assets/icons/mut_du_du.png';
    } else if (name.contains('củ từ')) {
      assetPath = 'assets/icons/cu_tu.png';
    } else if (name.contains('wrap')) {
      assetPath = 'assets/icons/banh_wrap.png';
    } else if (name.contains('đậu hũ chiên')) {
      assetPath = 'assets/icons/dau_hu_chien.png';
    } else if (name.contains('đậu hũ') || name.contains('đậu phụ') || name.contains('tofu')) {
      assetPath = 'assets/icons/dau_phu.png';
    } else if (name.contains('mắm tôm') || name.contains('shrimp paste')) {
      assetPath = 'assets/icons/mam_tom.png';
    } else if (name.contains('bột sắn dây') || name.contains('bột sắn')) {
      assetPath = 'assets/icons/bot_san_day.png';
    } else if (name.contains('bánh đúc')) {
      assetPath = 'assets/icons/banh_duc.png';
    } else if (name.contains('bún gạo lứt')) {
      assetPath = 'assets/icons/bun_gao_lut.png';
    } else if (name.contains('miến')) {
      assetPath = 'assets/icons/mien_dong.png';
    } else if (name.contains('bún')) {
      assetPath = 'assets/icons/bun.png';
    } else if (name.contains('hoa chuối')) {
      assetPath = 'assets/icons/hoa_chuoi.png';
    } else if (name.contains('whey') || name.contains('isolate')) {
      assetPath = 'assets/icons/whey_protein.png';
    } else if (name.contains('thịt lợn hộp') || name.contains('thịt heo hộp') || name.contains('spam')) {
      assetPath = 'assets/icons/thit_lon_hop.png';
    } else if (name.contains('thịt bò hộp') || name.contains('bò hộp') || name.contains('corned beef')) {
      assetPath = 'assets/icons/thit_bo_hop.png';
    } else if (name.contains('pate') || name.contains('pa-tê')) {
      assetPath = 'assets/icons/pate.png';
    } else if (name.contains('nem chua')) {
      assetPath = 'assets/icons/nem_chua.png';
    } else if (name.contains('lạp xưởng') || name.contains('lạp sườn')) {
      assetPath = 'assets/icons/lap_xuong.png';
    } else if (name.contains('lươn')) {
      assetPath = 'assets/icons/luon.png';
    } else if (name.contains('lòng lợn') || name.contains('lòng heo') || name.contains('phèo')) {
      assetPath = 'assets/icons/long_lon.png';
    } else if (name.contains('cá trích hộp') || name.contains('cá thu hộp') || name.contains('cá ngừ hộp') || (name.contains('cá') && name.contains('hộp'))) {
      assetPath = 'assets/icons/ca_hop.png';
    } else if (name.contains('phồng tôm')) {
      assetPath = 'assets/icons/banh_phong_tom.png';
    } else if (name.contains('chả lụa') || name.contains('giò lụa')) {
      assetPath = 'assets/icons/cha_lua.png';
    } else if (name.contains('chả quế')) {
      assetPath = 'assets/icons/cha_que.png';
    } else if (name.contains('chà bông') || name.contains('ruốc thịt') || name.contains('ruốc')) {
      assetPath = 'assets/icons/cha_bong.png';
    } else if (name.contains('gan gà')) {
      assetPath = 'assets/icons/con_ga.png';
    } else if (name.contains('gan vịt')) {
                  assetPath = 'assets/icons/con_vit.png';
    } else if (name.contains('thịt gà hộp') || (name.contains('gà') && name.contains('hộp'))) {
      assetPath = 'assets/icons/thit_lon_hop.png';
    } else if (name.contains('bánh phở') || name.contains('phở')) {
      assetPath = 'assets/icons/banh_pho.png';
    } else if (name.contains('giá đỗ')) {
      assetPath = 'assets/icons/gia_do.png';
    } else if (name.contains('nem chua')) {
      assetPath = 'assets/icons/nem_chua.png';
    } else if (name.contains('chả bò')) {
      assetPath = 'assets/icons/cha_bo.png';
    } else if (name.contains('thịt vịt') || name.contains('vịt')) {
      assetPath = 'assets/icons/con_vit.png';
    } else if (name.contains('coca') || name.contains('pepsi')) {
      assetPath = 'assets/icons/cocacola.png';
    } else if (name.contains('xoài') || name.contains('mango')) {
      assetPath = 'assets/icons/xoai.png';
    } else if (name.contains('ba khía')) {
      assetPath = 'assets/icons/ba_khia.png';
    } else if (name.contains('trứng vịt')) {
      assetPath = 'assets/icons/trung_vit.png';
    } else if (name.contains('trứng') || name.contains('egg')) {
      assetPath = 'assets/icons/trung_ga.png';
    } else if (name.contains('xúc xích')) {
      assetPath = 'assets/icons/xuc_xich.png';
    } else if (name.contains('cải bó xôi') || name.contains('chân vịt') || name.contains('spinach')) {
      assetPath = 'assets/icons/cai_bo_xoi.png';
    } else if (name.contains('ớt chuông')) {
      assetPath = 'assets/icons/ot_chuong.png';
    } else if (name.contains('bánh tráng')) {
      assetPath = 'assets/icons/banh_trang.png';
    } else if (!name.contains('hộp') && !name.contains('sữa') && (name.contains('thịt bò') || name.contains('bắp bò') || name.contains('gầu bò') || name.contains('thăn bò') || name.contains('bò'))) {
      assetPath = 'assets/icons/con_bo.png';
    } else if (name.contains('gan bò') || name.contains('cật bò') || name.contains('bao tử bò') || name.contains('óc bò') || name.contains('đuôi bò')) {
      assetPath = 'assets/icons/con_bo.png';
    } else if (name.contains('gan lợn') || name.contains('gan heo') || name.contains('cật lợn') || name.contains('cật heo') || name.contains('bao tử lợn') || name.contains('bao tử heo') || name.contains('óc lợn') || name.contains('óc heo')) {
      assetPath = 'assets/icons/thit_lon.png';
    } else if (!name.contains('hộp') && (name.contains('thịt lợn') || name.contains('thịt heo') || name.contains('đầu lợn') || name.contains('đầu heo') || name.contains('đuôi lợn') || name.contains('đuôi heo') || name.contains('tai lợn') || name.contains('tai heo') || name.contains('sườn lợn') || name.contains('sườn non lợn') || name.contains('sườn heo') || name.contains('ba chỉ') || name.contains('ba rọi') || name.contains('giò lợn') || name.contains('giò heo') || name.contains('giò thủ') || name.contains('da lợn') || name.contains('da heo') || name.contains('dăm bông lợn') || name.contains('dăm bông heo') || name.contains('nạc heo') || name.contains('nạc lợn'))) {
      assetPath = 'assets/icons/thit_lon.png';
    }

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text('🥗', style: TextStyle(fontSize: size)),
      );
    }
    return Text(icon, style: TextStyle(fontSize: size));
  }

  void _showEditItemDialog(Map<String, dynamic> item) {

    final weightCtrl = TextEditingController(text: item['weight'].toString());

    String currentComp = item['compartment'] ?? FridgeClassifier.cooler;

    showDialog(

      context: context,

      builder: (ctx) => StatefulBuilder(

        builder: (context, setDlgState) => AlertDialog(

          backgroundColor: AppColors.surface,

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

          title: Row(

            children: [

              _buildItemIconWidget(item, size: 28),

              const SizedBox(width: 8),

              Expanded(

                child: Text(item['name'] ?? '', style: AppTypography.titleMedium(color: AppColors.onSurface)),

              ),

            ],

          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              TextField(

                controller: weightCtrl,

                keyboardType: TextInputType.number,

                decoration: InputDecoration(

                  labelText: 'Khối lượng (${item['unit'] ?? "g"})',

                  suffixText: item['unit'] ?? 'g',

                  filled: true,

                  fillColor: AppColors.surfaceContainerLow,

                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                ),

              ),

              const SizedBox(height: 16),

              const Text('Ngăn tủ lưu trữ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),

              const SizedBox(height: 8),

              Row(

                children: [

                  Expanded(

                    child: ChoiceChip(

                      label: const Text('❄️ Ngăn đông'),

                      selected: currentComp == FridgeClassifier.freezer,

                      selectedColor: Colors.lightBlue.withValues(alpha: 0.3),

                      onSelected: (val) {

                        if (val) setDlgState(() => currentComp = FridgeClassifier.freezer);

                      },

                    ),

                  ),

                  const SizedBox(width: 8),

                  Expanded(

                    child: ChoiceChip(

                      label: const Text('🍃 Ngăn mát'),

                      selected: currentComp == FridgeClassifier.cooler,

                      selectedColor: AppColors.primary.withValues(alpha: 0.3),

                      onSelected: (val) {

                        if (val) setDlgState(() => currentComp = FridgeClassifier.cooler);

                      },

                    ),

                  ),

                ],

              ),

            ],

          ),

          actions: [

            TextButton(

              onPressed: () {

                setState(() {

                  _fridgeItems.removeWhere((i) => i['id'] == item['id']);

                  _selectedItemIds.remove(item['id']);

                });

                _saveFridgeItems();

                Navigator.pop(ctx);

              },

              style: TextButton.styleFrom(foregroundColor: AppColors.fire),

              child: const Text('Bỏ khỏi tủ'),

            ),

            TextButton(

              onPressed: () => Navigator.pop(ctx),

              child: const Text('Hủy'),

            ),

            ElevatedButton(

              style: ElevatedButton.styleFrom(

                backgroundColor: AppColors.primary,

                foregroundColor: AppColors.onPrimary,

              ),

              onPressed: () {

                final newW = int.tryParse(weightCtrl.text) ?? item['weight'];

                setState(() {

                  item['weight'] = newW;

                  item['compartment'] = currentComp;

                });

                _saveFridgeItems();

                Navigator.pop(ctx);

              },

              child: const Text('Lưu'),

            ),

          ],

        ),

      ),

    );

  }

  /// Menu bấm nút "Thêm nguyên liệu" với 4 phương thức

  void _showAddMethodSelectionSheet() {

    showModalBottomSheet(

      context: context,

      backgroundColor: AppColors.surface,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (sheetCtx) {

        return SafeArea(

          child: Padding(

            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                Container(

                  width: 40,

                  height: 4,

                  decoration: BoxDecoration(

                    color: AppColors.outlineVariant,

                    borderRadius: BorderRadius.circular(2),

                  ),

                ),

                const SizedBox(height: 16),

                Text(

                  'THÊM NGUYÊN LIỆU VÀO TỦ LẠNH',

                  style: GoogleFonts.spaceGrotesk(

                    fontWeight: FontWeight.bold,

                    fontSize: 15,

                    color: AppColors.onSurface,

                    letterSpacing: 0.5,

                  ),

                ),

                const SizedBox(height: 6),

                Text(

                  'Hệ thống sẽ tự động phân loại vào Ngăn đông hoặc Ngăn mát',

                  style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),

                  textAlign: TextAlign.center,

                ),

                const SizedBox(height: 20),

                // 1. Nhập tay

                _buildAddOptionTile(

                  icon: Icons.edit_note,

                  color: Colors.orange,

                  title: 'Nhập tay thủ công',

                  subtitle: 'Tìm trong 340+ nguyên liệu hoặc gõ tên món',

                  onTap: () {

                    Navigator.pop(sheetCtx);

                    _showManualAddDialog();

                  },

                ),

                const SizedBox(height: 10),

                // 2. Thêm bằng giọng nói

                _buildAddOptionTile(

                  icon: Icons.mic,

                  color: Colors.redAccent,

                  title: 'Thêm bằng giọng nói',

                  subtitle: 'Nói: "300g ức gà, 2 quả trứng, nửa ký thịt bò..."',

                  onTap: () {

                    Navigator.pop(sheetCtx);

                    _openVoiceInput();

                  },

                ),

                const SizedBox(height: 10),

                // 3. Thêm bằng chụp ảnh

                _buildAddOptionTile(

                  icon: Icons.camera_alt,

                  color: AppColors.primary,

                  title: 'Thêm bằng chụp ảnh (Camera)',

                  subtitle: 'Chụp ảnh món ăn / nguyên liệu, Gemini 3.8 Flash phân tích',

                  onTap: () {

                    Navigator.pop(sheetCtx);

                    _pickAndProcessImage(ImageSource.camera);

                  },

                ),

                const SizedBox(height: 10),

                // 4. Thêm từ ảnh trong gallery

                _buildAddOptionTile(

                  icon: Icons.photo_library,

                  color: Colors.blueAccent,

                  title: 'Thêm từ ảnh trong Thư viện (Gallery)',

                  subtitle: 'Chọn hình ảnh có sẵn trong máy để nhận diện',

                  onTap: () {

                    Navigator.pop(sheetCtx);

                    _pickAndProcessImage(ImageSource.gallery);

                  },

                ),

                const SizedBox(height: 12),

              ],

            ),

          ),

        );

      },

    );

  }

  Widget _buildAddOptionTile({

    required IconData icon,

    required Color color,

    required String title,

    required String subtitle,

    required VoidCallback onTap,

  }) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(16),

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(

          color: AppColors.surfaceContainerLow,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),

        ),

        child: Row(

          children: [

            Container(

              width: 44,

              height: 44,

              decoration: BoxDecoration(

                color: color.withValues(alpha: 0.15),

                borderRadius: BorderRadius.circular(12),

              ),

              child: Icon(icon, color: color, size: 24),

            ),

            const SizedBox(width: 14),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),

                  ),

                  const SizedBox(height: 2),

                  Text(

                    subtitle,

                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),

                  ),

                ],

              ),

            ),

            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),

          ],

        ),

      ),

    );

  }

  /// 1. Nhập tay

  void _showManualAddDialog() async {
    List<Map<String, dynamic>> dbIngredients = [];
    try {
      dbIngredients = await ApiService.getIngredients();
    } catch (_) {}
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ManualAddIngredientSheet(
        dbIngredients: dbIngredients,
        onAddItem: (item) {
          _addItemToFridge(
            name: item['name'] ?? '',
            icon: item['icon'] ?? '🥗',
            weight: 150,
            kcal: (item['kcalPer100g'] as num?)?.toInt(),
            protein: (item['protein'] as num?)?.toInt(),
            carbs: (item['carbs'] as num?)?.toInt(),
            fat: (item['fat'] as num?)?.toInt(),
          );
        },
        buildItemIcon: _buildItemIconWidget,
      ),
    );
  }

  void _openVoiceInput() {

    VoiceIngredientSheet.show(

      context: context,

      onConfirm: (List<VoiceIngredientResult> results) {

        if (results.isEmpty) return;

        for (final r in results) {

          _addItemToFridge(

            name: r.name,

            icon: r.icon,

            weight: r.weight,

            unit: r.unit,

            explicitCompartment: FridgeClassifier.classify(r.name),

            kcal: r.kcalPer100g,

            protein: r.protein.toInt(),

            carbs: r.carbs.toInt(),

            fat: r.fat.toInt(),

          );

        }

      },

    );

  }

  /// 3 & 4. Chụp ảnh hoặc chọn từ Thư viện qua Gemini AI

  Future<void> _pickAndProcessImage(ImageSource source) async {

    final picker = ImagePicker();

    final XFile? file = await picker.pickImage(source: source);

    if (file == null) return;

    if (!mounted) return;

    // Loading Dialog

    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (_) => Center(

        child: Card(

          color: AppColors.surface,

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

          child: Padding(

            padding: const EdgeInsets.all(24.0),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                const CircularProgressIndicator(color: AppColors.primary),

                const SizedBox(height: 16),

                Text(

                  'Gemini 3.8 Flash đang quét nguyên liệu...',

                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 15),

                ),

                const SizedBox(height: 6),

                const Text(

                  'Tự động phân loại Ngăn Đông ❄️ và Ngăn Mát 🍃',

                  style: TextStyle(fontSize: 12, color: Colors.grey),

                ),

              ],

            ),

          ),

        ),

      ),

    );

    try {

      final aiService = AIServiceFactory.createFoodRecognitionService();

      final detections = await aiService.recognizeIngredients(File(file.path), confidence: 0.25);

      if (mounted) Navigator.pop(context); // Close loading

      if (detections.isEmpty) {

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(

              content: Text('Không nhận diện được nguyên liệu thực phẩm trong ảnh. Hãy thử chụp góc sáng hơn!'),

              backgroundColor: AppColors.warning,

            ),

          );

        }

        return;

      }

      int addedCount = 0;

      for (final d in detections) {

        if (d.confidence >= 0.25) {

          _addItemToFridge(

            name: d.foodName,

            icon: '🥗',

            weight: 150,

          );

          addedCount++;

        }

      }

      if (mounted && addedCount > 0) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text('✨ Gemini AI đã nhận diện và cất $addedCount nguyên liệu vào tủ lạnh thành công!'),

            backgroundColor: AppColors.primary,

          ),

        );

      }

    } catch (e) {

      if (mounted) Navigator.pop(context);

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Lỗi quét AI: $e'), backgroundColor: AppColors.fire),

        );

      }

    }

  }

  /// Nút 2: "Tạo công thức" từ các món đã chọn trong tủ

  void _createRecipesFromSelected() {

    List<Map<String, dynamic>> itemsToUse = [];

    if (_selectedItemIds.isNotEmpty) {

      itemsToUse = _fridgeItems.where((i) => _selectedItemIds.contains(i['id'])).toList();

    } else {

      // Nếu chưa chọn món nào, hỏi người dùng có muốn lấy tất cả món trong tủ

      itemsToUse = List.from(_fridgeItems);

    }

    if (itemsToUse.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Tủ lạnh chưa có nguyên liệu nào. Hãy bấm "Thêm nguyên liệu" trước nhé!'),

          backgroundColor: AppColors.warning,

        ),

      );

      return;

    }

    final ingNames = itemsToUse.map((i) => i['name'].toString()).toList();

    showDialog(

      context: context,

      builder: (dialogCtx) => AlertDialog(

        backgroundColor: AppColors.surface,

        surfaceTintColor: AppColors.surface,

        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Column(

          children: [

            Row(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                const Icon(Icons.restaurant_menu, color: AppColors.primary),

                const SizedBox(width: 8),

                Text(

                  'CÔNG THỨC TỪ TỦ LẠNH',

                  style: GoogleFonts.spaceGrotesk(

                    fontWeight: FontWeight.bold,

                    letterSpacing: 1.2,

                    fontSize: 16,

                    color: AppColors.onSurface,

                  ),

                ),

              ],

            ),

            const SizedBox(height: 6),

            Text(

              'Từ ${itemsToUse.length} nguyên liệu bạn đã chọn trong tủ 🧊',

              style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),

            ),

          ],

        ),

        contentPadding: const EdgeInsets.all(16),

        content: SizedBox(

          width: double.maxFinite,

          height: 420,

          child: FutureBuilder<List<Map<String, dynamic>>>(

            future: _fetchOrFallbackRecipes(ingNames),

            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {

                return const Center(

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      CircularProgressIndicator(color: AppColors.primary),

                      SizedBox(height: 12),

                      Text('Đang tạo công thức tối ưu dinh dưỡng...'),

                    ],

                  ),

                );

              }

              final recipes = snapshot.data ?? [];

              if (recipes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.soup_kitchen_outlined, size: 54, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có công thức phù hợp với ${itemsToUse.length} nguyên liệu đã chọn.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy chọn thêm nguyên liệu nấu ăn khác từ tủ (thịt, cá, trứng, rau củ...) để gợi ý món ăn chuẩn gymer nhé!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(

                itemCount: recipes.length,

                separatorBuilder: (context, index) => const SizedBox(height: 10),

                itemBuilder: (ctx, idx) {
                  final r = recipes[idx];
                  final title = r['title'] ?? 'Món ăn dinh dưỡng';
                  final kcal = r['kcal'] ?? 350;
                  final time = r['time'] ?? 15;
                  final protein = r['protein'] ?? 30;
                  final matchCount = r['matchingCount'] ?? itemsToUse.length;
                  final isSavedInKitchen = r['isSavedInKitchen'] == true;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CookingTimerScreen(recipe: r),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        // Nổi bật đặc biệt nếu là công thức đã lưu bên Nấu Ăn (Yêu cầu 6)
                        color: isSavedInKitchen
                            ? const Color(0xFFFEF3C7).withValues(alpha: 0.6)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSavedInKitchen
                              ? const Color(0xFFF59E0B)
                              : AppColors.outlineVariant.withValues(alpha: 0.5),
                          width: isSavedInKitchen ? 2.0 : 1.0,
                        ),
                        boxShadow: isSavedInKitchen
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isSavedInKitchen) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bookmark, size: 11, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    '⭐ ĐÃ LƯU TRONG BỘ SƯU TẬP NẤU ĂN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSavedInKitchen
                                      ? const Color(0xFFFDE68A)
                                      : AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(isSavedInKitchen ? '⭐' : '🍳', style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSavedInKitchen ? const Color(0xFF92400E) : AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text('🔥 $kcal kcal', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        const SizedBox(width: 8),
                                        Text('🍗 ${protein}g Pro', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        const SizedBox(width: 8),
                                        Text('⏱️ $time p', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Khớp $matchCount nguyên liệu từ tủ!',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSavedInKitchen ? const Color(0xFFD97706) : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: isSavedInKitchen ? const Color(0xFFD97706) : Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  /// Lấy danh sách công thức gợi ý theo Cách 3:
  /// - Phân loại nguyên liệu cốt lõi (thịt, cá, trứng, rau, đậu, tinh bột...) vs gia vị / đồ phụ
  /// - Món ăn bắt buộc phải khớp ít nhất 1 nguyên liệu cốt lõi (không gợi ý món chỉ vì có mắm/muối/tiêu/dầu)
  /// - Ưu tiên món đã lưu trong bộ sưu tập lên đầu tiên
  /// - Giới hạn lấy Top 30 món ăn xuất sắc nhất (nhẹ RAM, 0% giật lag, tốc độ phản hồi tức thì)
  Future<List<Map<String, dynamic>>> _fetchOrFallbackRecipes(List<String> ingNames) async {
    final prefs = await SharedPreferences.getInstance();
    // Danh sách ID các công thức người dùng THỰC SỰ ĐÃ LƯU bên Nấu Ăn (Bookmark)
    final savedIds = (prefs.getStringList('eatgym_saved_recipes_ids_v1') ?? []).toSet();
    
    // Tải các công thức do người dùng tự đăng bên trang Nấu ăn (nếu có)
    List<Map<String, dynamic>> userRecipes = [];
    try {
      final userJson = prefs.getString('eatgym_user_created_recipes_v2');
      if (userJson != null && userJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(userJson);
        userRecipes = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    // Lấy toàn bộ kho công thức chuẩn từ Database Backend (dùng chung 100% với trang Nấu Ăn)
    List<Map<String, dynamic>> allRecipes = [];
    if (_cachedAllRecipes != null && _cachedAllRecipes!.isNotEmpty) {
      allRecipes = _cachedAllRecipes!;
    } else {
      try {
        final fetched = await ApiService.getRecipes();
        if (fetched.isNotEmpty) {
          _cachedAllRecipes = fetched;
          allRecipes = fetched;
        }
      } catch (_) {}
    }

    final pool = <Map<String, dynamic>>[...userRecipes, ...allRecipes];
    if (pool.isEmpty) return [];

    bool isCondiment(String name) {
      final n = IngredientNormalizer.removeDiacritics(name.toLowerCase()).trim();
      const condiments = [
        'nuoc mam', 'xi dau', 'nuoc tuong', 'dau an', 'dau me', 'dau o liu',
        'dau thuc vat', 'dau hao', 'giam', 'tuong ca', 'tuong ot', 'tuong den',
        'mayonnaise', 'sot ', 'sot', 'muoi', 'tieu', 'duong', 'bot ngot', 'hat nem',
        'cocacola', 'pepsi', 'nuoc ngot', 'da vien', 'ruou'
      ];
      return condiments.any((c) => n.contains(c));
    }

    String cleanItemName(String name) {
      final stripped = name.replaceAll(RegExp(r'(tươi|nạc|phi lê|đóng hộp|hộp|xay|khô)'), '').trim();
      return IngredientNormalizer.removeDiacritics((stripped.isNotEmpty ? stripped : name).toLowerCase());
    }

    // 1. Phân loại nguyên liệu trong tủ thành Nguyên liệu chính và Gia vị / Đồ phụ
    final List<MapEntry<String, String>> coresClean = [];
    final List<MapEntry<String, String>> condsClean = [];

    for (final rawName in ingNames) {
      final cName = cleanItemName(rawName);
      if (isCondiment(rawName)) {
        condsClean.add(MapEntry(rawName, cName));
      } else {
        coresClean.add(MapEntry(rawName, cName));
      }
    }

    final List<Map<String, dynamic>> matchedList = [];

    // 2. So khớp nhanh với kho công thức
    for (final r in pool) {
      final title = (r['title'] ?? '').toString();
      final ings = (r['ingredients'] as List? ?? []);
      
      // Chuẩn hóa trước toàn bộ văn bản của món ăn 1 lần
      final ingNamesJoined = ings.map((ing) {
        if (ing is Map) return (ing['name'] ?? '').toString();
        return ing.toString();
      }).join(' ');
      final rText = IngredientNormalizer.removeDiacritics('$title $ingNamesJoined'.toLowerCase());

      int coreMatches = 0;
      int condMatches = 0;

      for (final entry in coresClean) {
        if (rText.contains(entry.value)) {
          coreMatches++;
        }
      }

      // ĐIỀU KIỆN CỐT LÕI CỦA CÁCH 3:
      // Món ăn BẮT BUỘC phải khớp ít nhất 1 nguyên liệu chính!
      // (Không bao giờ gợi ý món ăn chỉ vì có mắm, muối, tiêu, dầu ăn hay đá viên)
      if (coreMatches == 0) {
        continue;
      }

      for (final entry in condsClean) {
        if (rText.contains(entry.value)) {
          condMatches++;
        }
      }

      final totalMatches = coreMatches + condMatches;
      final mapped = Map<String, dynamic>.from(r);
      final rId = (mapped['id'] ?? '').toString();
      final isSaved = savedIds.contains(rId);

      // Điểm số xếp hạng:
      // - Đã lưu trong bộ sưu tập: +1000 điểm (luôn đứng đầu danh sách)
      // - Mỗi nguyên liệu chính khớp: +10 điểm
      // - Mỗi gia vị khớp: +1 điểm (điểm thưởng)
      final score = (isSaved ? 1000 : 0) + (coreMatches * 10) + condMatches;

      mapped['matchingCount'] = totalMatches;
      mapped['coreMatches'] = coreMatches;
      mapped['score'] = score;
      mapped['isSavedInKitchen'] = isSaved;
      mapped['kcal'] = mapped['kcal'] ?? 350;
      mapped['time'] = mapped['time'] ?? mapped['cooking_time_min'] ?? 15;
      mapped['protein'] = mapped['protein'] ?? mapped['protein_g'] ?? 25;
      matchedList.add(mapped);
    }

    // 3. Sắp xếp danh sách theo điểm số từ cao xuống thấp
    matchedList.sort((a, b) {
      final aScore = (a['score'] as int?) ?? 0;
      final bScore = (b['score'] as int?) ?? 0;
      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      }
      final aTime = (a['time'] as int?) ?? 20;
      final bTime = (b['time'] as int?) ?? 20;
      return aTime.compareTo(bTime);
    });

    // 4. GIỚI HẠN TOP 30 MÓN ĂN XUẤT SẮC NHẤT (CÁCH 3)
    // Giữ RAM nhẹ tênh, render siêu mượt 60 FPS, không còn tình trạng quay đơ lag
    return matchedList.take(30).toList();
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final freezerItems = _fridgeItems.where((i) => i['compartment'] == FridgeClassifier.freezer).toList();
    final coolerItems = _fridgeItems.where((i) => i['compartment'] != FridgeClassifier.freezer).toList();

    // Chia các món thành từng ngăn/kệ, mỗi kệ 4 món
    final freezerShelves = _chunkItems(freezerItems, 4);
    final coolerShelves = _chunkItems(coolerItems, 4);

    final selectedCount = _selectedItemIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Nền sáng sạch sẽ, tôn dáng chiếc tủ lạnh retro
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),

            // KHUNG MINH HỌA TỦ LẠNH MỞ CÁNH TRÁI (Không còn thanh filter chip thừa)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HAI CÁNH TỦ MỞ BÊN TRÁI (Cánh ngăn đông trên + Cánh ngăn mát dưới)
                    _buildLeftSwungDoors(freezerShelves.length, coolerShelves.length),
                    const SizedBox(width: 4),

                    // TOÀN BỘ KHOANG CHÍNH TRONG TỦ LẠNH VỚI NHIỀU NGĂN KỆ RỘNG RÃI
                    Expanded(
                      child: _buildFridgeCabinet(
                        freezerShelves: freezerShelves,
                        coolerShelves: coolerShelves,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // THANH ĐIỀU KHIỂN DƯỚI ĐÁY: NÚT TẠO CÔNG THỨC & NÚT THÊM NGUYÊN LIỆU MÀU CAM
            _buildBottomActionBar(selectedCount),
          ],
        ),
      ),
    );
  }

  /// Hàm chia danh sách nguyên liệu thành các hàng kệ (mỗi kệ 4 món)
  List<List<Map<String, dynamic>>> _chunkItems(List<Map<String, dynamic>> list, int size) {
    final List<List<Map<String, dynamic>>> chunks = [];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  /// Hai cánh tủ lạnh đang mở rộng bên trái
  Widget _buildLeftSwungDoors(int freezerShelfCount, int coolerShelfCount) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          // Cánh trên (Cửa ngăn đông)
          Expanded(
            flex: 38,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4A82AB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(8),
                ),
                border: Border.all(color: const Color(0xFF1D3E56), width: 2.4),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 9,
                    right: 4,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF90CDF4), width: 1.4),
                      ),
                      child: Center(
                        child: Container(
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBAE6FD),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tay nắm dọc cánh cửa
                  Positioned(
                    left: 2,
                    top: 24,
                    bottom: 24,
                    width: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFF1D3E56), width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Khoảng hở giữa 2 cánh cửa (khớp với thanh ngăn cách của tủ)
          const SizedBox(height: 10),

          // Cánh dưới (Cửa ngăn mát có nhiều khay cửa)
          Expanded(
            flex: 62,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4A82AB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(16),
                ),
                border: Border.all(color: const Color(0xFF1D3E56), width: 2.4),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 9,
                    right: 4,
                    top: 12,
                    bottom: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFE0B2), width: 1.4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            height: 11,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBAE6FD),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                            ),
                          ),
                          Container(
                            height: 11,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBAE6FD),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                            ),
                          ),
                          Container(
                            height: 11,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBAE6FD),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tay nắm dọc cánh cửa
                  Positioned(
                    left: 2,
                    top: 36,
                    bottom: 36,
                    width: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFF1D3E56), width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Toàn bộ vỏ và khoang trong của chiếc tủ lạnh
  Widget _buildFridgeCabinet({
    required List<List<Map<String, dynamic>>> freezerShelves,
    required List<List<Map<String, dynamic>>> coolerShelves,
  }) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4A82AB), // Màu xanh retro của vỏ ngoài tủ
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFF1D3E56), width: 2.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. KHOANG NGĂN ĐÔNG (Màu xanh đá tuyết, có nhũ băng và hoa tuyết)
                Expanded(
                  flex: 38,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE0F2FE),
                          Color(0xFFCFE8FC),
                          Color(0xFFBAE6FD),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      border: Border.all(color: const Color(0xFF1D3E56), width: 1.8),
                    ),
                    child: Stack(
                      children: [
                        // Hoa tuyết trang trí ở các góc
                        const Positioned(
                          left: 4,
                          top: 14,
                          child: Text('❄️', style: TextStyle(fontSize: 10, color: Color(0xFF7DD3FC))),
                        ),
                        const Positioned(
                          right: 4,
                          top: 14,
                          child: Text('❄️', style: TextStyle(fontSize: 10, color: Color(0xFF7DD3FC))),
                        ),

                        // Nhũ băng rủ xuống từ nóc ngăn đông (Icicles)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 14,
                          child: CustomPaint(
                            painter: IciclesPainter(),
                          ),
                        ),

                        // Các hàng kệ thức ăn ngăn đông (scroll mượt nếu có nhiều món)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: freezerShelves.map((shelf) {
                                return Column(
                                  children: [
                                    _buildShelfRow(shelf),
                                    _buildWhiteShelfBar(),
                                    const SizedBox(height: 6),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. THANH NGĂN CÁCH GIỮA HAI NGĂN
                Container(
                  height: 10,
                  color: const Color(0xFF3B729E),
                  foregroundDecoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: const Color(0xFF1D3E56), width: 1.4),
                    ),
                  ),
                ),

                // 3. KHOANG NGĂN MÁT (Màu kem ấm áp, chia nhiều tầng kệ rộng rãi, rau củ và thực phẩm xếp chung)
                Expanded(
                  flex: 62,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EE), // Màu kem sữa thơm ngon
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      border: Border.all(color: const Color(0xFF1D3E56), width: 1.8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: coolerShelves.map((shelf) {
                            return Column(
                              children: [
                                _buildShelfRow(shelf),
                                _buildWhiteShelfBar(isWarm: true),
                                const SizedBox(height: 8),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // HAI CHÂN ĐẾ TỦ LẠNH DƯỚI ĐÁY
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 20),
              width: 24,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF1D3E56),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 20),
              width: 24,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF1D3E56),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Hàng nguyên liệu trên kệ (4 món mỗi hàng)
  Widget _buildShelfRow(List<Map<String, dynamic>> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(4, (index) {
        if (index < items.length) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _buildShelfItem(items[index]),
            ),
          );
        } else {
          return const Expanded(child: SizedBox());
        }
      }),
    );
  }

  /// Thanh kệ đỡ màu trắng
  Widget _buildWhiteShelfBar({bool isWarm = false}) {
    return Container(
      height: 4.5,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: isWarm
                ? const Color(0xFFD4A373).withValues(alpha: 0.3)
                : const Color(0xFF7DD3FC).withValues(alpha: 0.45),
            blurRadius: 2.5,
            offset: const Offset(0, 1.5),
          ),
        ],
        border: Border.all(
          color: isWarm ? const Color(0xFFFFE0B2) : const Color(0xFFBAE6FD),
          width: 0.9,
        ),
      ),
    );
  }

  /// Widget từng món ăn trên kệ (Icon nhỏ gọn gàng, chữ sắc nét, chọn hiện xanh)
  Widget _buildShelfItem(Map<String, dynamic> item) {
    final isSelected = _selectedItemIds.contains(item['id']);

    return GestureDetector(
      onTap: () => _toggleItemSelection(item['id']),
      onLongPress: () => _showEditItemDialog(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFDCFCE7) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                    width: 1.8,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _buildItemIconWidget(item, size: 24),
                ),
              ),

              // Huy hiệu số lượng x1, x2 ở góc dưới phải
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF94A3B8), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'x${item['weight'] ?? 1}',
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),

              // Dấu tích xanh khi chọn
              if (isSelected)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            item['name']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF15803D) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh điều khiển dưới đáy (Nút Tạo công thức & Nút tròn cam thêm nguyên liệu như ảnh)
  Widget _buildBottomActionBar(int selectedCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nút Tạo công thức
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _createRecipesFromSelected,
                icon: const Icon(Icons.restaurant_menu, size: 20),
                label: Text(
                  selectedCount > 0
                      ? 'Tạo công thức ($selectedCount món)'
                      : 'Tạo công thức (Tất cả)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nút Thêm nguyên liệu tròn màu cam nổi bật như trong ảnh
          Material(
            color: const Color(0xFFF97316),
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showAddMethodSelectionSheet,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ các nhũ băng rủ xuống từ nóc ngăn đông (Icicles)
class IciclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    const segments = 10;
    final segWidth = size.width / segments;
    for (int i = segments; i >= 0; i--) {
      final x = i * segWidth;
      final dripHeight = (i % 3 == 0) ? 14.0 : (i % 2 == 0 ? 8.0 : 11.0);
      path.lineTo(x + segWidth * 0.5, dripHeight);
      path.lineTo(x, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _ManualAddIngredientSheet extends StatefulWidget {
  final List<Map<String, dynamic>> dbIngredients;
  final Function(Map<String, dynamic>) onAddItem;
  final Widget Function(Map<String, dynamic>, {double size}) buildItemIcon;

  const _ManualAddIngredientSheet({
    required this.dbIngredients,
    required this.onAddItem,
    required this.buildItemIcon,
  });

  @override
  State<_ManualAddIngredientSheet> createState() => _ManualAddIngredientSheetState();
}

class _ManualAddIngredientSheetState extends State<_ManualAddIngredientSheet> {
  late final TextEditingController _searchCtrl;
  late final TextEditingController _customNameCtrl;
  String _query = '';
  final Set<Map<String, dynamic>> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _customNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.dbIngredients.where((i) {
      final n = (i['name'] ?? '').toString();
      return IngredientNormalizer.matchesSearch(n, _query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        left: 16,
        right: 16,
        top: 14,
      ),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhập tay nguyên liệu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_selectedItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF16A34A)),
                  ),
                  child: Text(
                    'Đã chọn ${_selectedItems.length} món',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              setState(() {
                _query = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nguyên liệu (thịt, rau, trứng, cá...)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _query = '';
                        });
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Không thấy trong từ điển? Thêm trực tiếp:'),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                            controller: _customNameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Nhập tên món (ví dụ: Nạc dăm lợn)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_customNameCtrl.text.trim().isNotEmpty) {
                              final name = _customNameCtrl.text.trim();
                              final customDetails = IngredientNormalizer.getIngredientDetails(name);
                              widget.onAddItem({
                                'name': name,
                                'icon': customDetails['icon']?.toString() ?? '🥗',
                                'weight': 150,
                              });
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm món này vào tủ lạnh'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (_, idx) {
                      final item = filtered[idx];
                      final isSelected = _selectedItems.contains(item);
                      final comp = FridgeClassifier.classify(item['name'] ?? '');
                      final isFreezer = comp == FridgeClassifier.freezer;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedItems.remove(item);
                            } else {
                              _selectedItems.add(item);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDCFCE7)
                                : AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF16A34A)
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              widget.buildItemIcon(item, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name']?.toString() ?? '',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 14,
                                        color: isSelected ? const Color(0xFF14532D) : AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: isFreezer
                                                ? Colors.lightBlue.withValues(alpha: 0.2)
                                                : Colors.green.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isFreezer ? '❄️ Ngăn đông' : '🍃 Ngăn mát',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isFreezer ? Colors.blue[800] : Colors.green[800],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item['kcalPer100g']} kcal/100g',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF16A34A) : Colors.grey.withValues(alpha: 0.5),
                                    width: 1.6,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedItems.isNotEmpty ? AppColors.primary : Colors.grey[400],
                foregroundColor: Colors.white,
                elevation: _selectedItems.isNotEmpty ? 2 : 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _selectedItems.isNotEmpty
                  ? () {
                      for (final item in _selectedItems) {
                        widget.onAddItem(item);
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm ${_selectedItems.length} món vào tủ lạnh!'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _selectedItems.isNotEmpty
                    ? 'Thêm ${_selectedItems.length} nguyên liệu đã chọn'
                    : 'Chọn các món để thêm vào tủ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
