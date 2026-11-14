import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/chat_message.dart';
import '../services/ai/nutrigym_chat_service.dart';
import '../services/ai/ingredient_normalizer.dart';
import '../services/api_service.dart';
import '../services/meal_plan_service.dart';
import '../main.dart'; // Để truy cập CameraScanContent.sessionIngredients
import 'meal_prep_screen.dart';
import 'weekly_meal_planner_screen.dart';

class NutriGymChatbotScreen extends StatefulWidget {
  static List<ChatMessage> sessionMessages = [];

  const NutriGymChatbotScreen({super.key});

  @override
  State<NutriGymChatbotScreen> createState() => _NutriGymChatbotScreenState();
}

class _NutriGymChatbotScreenState extends State<NutriGymChatbotScreen> with SingleTickerProviderStateMixin {
  List<ChatMessage> get _messages => NutriGymChatbotScreen.sessionMessages;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _liveTranscript = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static final List<Map<String, String>> quickQuestionCards = [
    {
      'icon': '🍱',
      'title': 'Lên lịch Meal Prep',
      'subtitle': 'Tùy chỉnh mục tiêu, bệnh lý, dị ứng, số ngày và chế độ nấu',
      'prompt': 'Lên lịch Meal Prep',
    },
    {
      'icon': '🥗',
      'title': 'Lập thực đơn theo mục tiêu',
      'subtitle': 'Thiết kế thực đơn tăng cơ giảm mỡ chuẩn khoa học',
      'prompt': 'Lập thực đơn theo mục tiêu',
    },
    {
      'icon': '🥩',
      'title': 'Thực phẩm nào giàu đạm nhất?',
      'subtitle': 'Bảng so sánh các nguồn Protein hàng đầu cho gymer',
      'prompt': 'Thực phẩm nào giàu đạm nhất?',
    },
    {
      'icon': '💪',
      'title': 'Cần nạp bao nhiêu protein để tăng cơ?',
      'subtitle': 'Tính lượng gram protein theo cân nặng thể hình',
      'prompt': 'Cần nạp bao nhiêu protein để tăng cơ?',
    },
    {
      'icon': '⚡',
      'title': 'Bữa ăn trước & sau khi tập gym',
      'subtitle': 'Bí quyết nạp năng lượng & phục hồi cơ bắp',
      'prompt': 'Bữa ăn trước khi tập gym nên ăn gì?',
    },
    {
      'icon': '🧪',
      'title': 'Hướng dẫn uống Creatine chuẩn khoa học',
      'subtitle': 'Liều lượng, thời điểm uống và lưu ý quan trọng',
      'prompt': 'Hướng dẫn uống Creatine',
    },
    {
      'icon': '🎙️',
      'title': 'Thêm nguyên liệu bằng giọng nói / chữ',
      'subtitle': 'Bóc tách 300g ức gà và 3 quả trứng vào danh sách',
      'prompt': 'Thêm 300g ức gà và 3 quả trứng',
    },
  ];

  final List<String> _quickPrompts = [
    '🍱 Lên lịch Meal Prep',
    '🥗 Lập thực đơn theo mục tiêu',
    '🥩 Thực phẩm giàu đạm nhất',
    '💪 Cần bao nhiêu protein/ngày?',
    '⚡ Ăn gì trước khi tập?',
    '🏆 Ăn gì sau khi tập?',
    '🧪 Hướng dẫn uống Creatine',
    '🎙️ Thêm 300g ức gà và 3 trứng',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
    if (_messages.isEmpty) {
      _addInitialBotGreeting();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
              if (_liveTranscript.trim().isNotEmpty) {
                _sendMessage(_liveTranscript.trim());
                _liveTranscript = '';
              }
            }
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) {
        setState(() => _speechEnabled = available);
      }
    } catch (_) {}
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_liveTranscript.trim().isNotEmpty) {
        _sendMessage(_liveTranscript.trim());
        _liveTranscript = '';
      }
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng cấp quyền micro để sử dụng giọng nói')),
          );
        }
        return;
      }
    }

    setState(() {
      _isListening = true;
      _liveTranscript = '';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _liveTranscript = result.recognizedWords;
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          localeId: 'vi_VN',
          listenFor: const Duration(seconds: 25),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _addInitialBotGreeting() {
    _messages.add(
      ChatMessage.botText(
        'Xin chào Gymer! 🏋️‍♂️ Tôi là **NutriGym AI Assistant**.\n\n'
        'Tôi có thể bóc tách nguyên liệu bạn nói vào danh sách, gợi ý công thức món ăn giàu đạm, '
        'lập kế hoạch thực đơn theo tủ lạnh hoặc mục tiêu tăng cơ giảm mỡ, và giải đáp mọi thắc mắc thể hình. Bạn cần hỗ trợ gì hôm nay?'
      ),
    );
  }

  Future<void> _sendMessage(String text, {Map<String, dynamic>? customMealPlanOptions}) async {
    final rawText = text.trim();
    if (rawText.isEmpty && customMealPlanOptions == null) return;

    if (customMealPlanOptions == null &&
        (rawText.toLowerCase().contains('lên lịch meal prep') ||
         rawText.toLowerCase().contains('tùy chọn meal prep') ||
         rawText.toLowerCase().contains('meal prep') ||
         rawText.toLowerCase().contains('lập thực đơn theo mục tiêu') ||
         rawText.toLowerCase().contains('lập thực đơn mới theo mục tiêu') ||
         rawText.toLowerCase().contains('thực đơn theo mục tiêu') ||
         rawText.toLowerCase().contains('tùy chọn lập') ||
         rawText.toLowerCase().contains('carb cycling') ||
         rawText.toLowerCase().contains('lập meal prep') ||
         rawText.toLowerCase().contains('lập kế hoạch meal prep'))) {
      _startMealPlanInteractiveQuestionnaire(rawText);
      return;
    }

    // Bỏ emoji ở đầu nếu bấm từ gợi ý câu hỏi để truy vấn AI sạch và chuẩn xác
    final cleaned = rawText.replaceFirst(RegExp(r'^[^\w\s\dÀ-ỹ]+'), '').trim();
    final actualQuery = cleaned.isNotEmpty ? cleaned : rawText;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage.user(rawText));
      _isTyping = true;
    });
    _scrollToBottom();

    // Gọi AI Service xử lý tin nhắn kèm danh sách nguyên liệu hiện có trong session
    final botResponse = await NutriGymChatService.processMessage(
      actualQuery,
      availableIngredients: CameraScanContent.sessionIngredients,
      customMealPlanOptions: customMealPlanOptions,
    );

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(botResponse);
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Thêm nguyên liệu từ tin nhắn bot vào danh sách tab Nguyên liệu (CameraScanContent.sessionIngredients)
  void _addIngredientsToScanSession(ChatMessage msg) {
    if (msg.ingredients == null || msg.ingredients!.isEmpty) return;

    for (final r in msg.ingredients!) {
      final existingIdx = CameraScanContent.sessionIngredients.indexWhere(
        (i) => i['name'].toString().toLowerCase() == r.name.toLowerCase(),
      );
      if (existingIdx >= 0) {
        CameraScanContent.sessionIngredients[existingIdx]['weight'] = r.weight;
      } else {
        CameraScanContent.sessionIngredients.add(r.toIngredientItem());
      }
    }

    setState(() {
      msg.isActionDone = true;
      _messages.add(
        ChatMessage.botText('🥗 Đã thêm thành công **${msg.ingredients!.length} nguyên liệu** vào tab Nguyên liệu!'),
      );
    });
    _scrollToBottom();
  }

  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ 2';
      case 2: return 'Thứ 3';
      case 3: return 'Thứ 4';
      case 4: return 'Thứ 5';
      case 5: return 'Thứ 6';
      case 6: return 'Thứ 7';
      case 7: return 'Chủ nhật';
      default: return 'Thứ $weekday';
    }
  }

  // Xác nhận và lưu kế hoạch thực đơn vào Trang Lịch (MealPlanService)
  Future<void> _saveConfirmedMealPlan(ChatMessage msg) async {
    final data = msg.mealPlanData;
    if (data == null) return;

    final days = data['days'] as List? ?? [];
    final List<MealPlan> plansToSave = [];
    final now = DateTime.now();

    for (int dayIdx = 0; dayIdx < days.length; dayIdx++) {
      final day = days[dayIdx] as Map<String, dynamic>;
      final targetDate = now.add(Duration(days: dayIdx));
      final weekdayStr = _getWeekdayName(targetDate.weekday);
      final dateFormatted = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}';
      final dayName = '$weekdayStr ($dateFormatted)';
      final dateStr = dateFormatted;
      final isMealPrep = day['isMealPrep'] == true;
      final cookType = day['cookType']?.toString() ?? (isMealPrep ? 'Meal Prep' : 'Nấu tươi');
      final notes = day['notes']?.toString();
      final prepDate = targetDate;

      // Tính giờ rã đông nếu là meal prep đông lạnh hoặc có defrostAlert
      DateTime? thawAt;
      if (isMealPrep || day['defrostAlert'] != null) {
        final thawDate = targetDate.subtract(const Duration(days: 1));
        thawAt = DateTime(thawDate.year, thawDate.month, thawDate.day, 20, 0);
        if (thawAt.isBefore(now)) {
          thawAt = now.add(const Duration(hours: 2));
        }
      }

      final meals = day['meals'] as List? ?? [];
      for (int mealIdx = 0; mealIdx < meals.length; mealIdx++) {
        final meal = meals[mealIdx] as Map<String, dynamic>;
        final typeStr = meal['type']?.toString().toLowerCase() ?? '';
        String mappedType = 'lunch';
        if (typeStr.contains('sáng')) {
          mappedType = 'breakfast';
        } else if (typeStr.contains('trưa')) {
          mappedType = 'lunch';
        } else if (typeStr.contains('tối')) {
          mappedType = 'dinner';
        } else if (typeStr.contains('phụ')) {
          mappedType = 'snack';
        }

        plansToSave.add(
          MealPlan(
            id: 'plan_${now.millisecondsSinceEpoch}_${dayIdx}_$mealIdx',
            name: meal['name']?.toString() ?? 'Món ăn',
            servings: 1,
            mealType: mappedType,
            prepDate: prepDate,
            storedFrozen: isMealPrep,
            thawAt: thawAt,
            dayName: dayName,
            dateStr: dateStr,
            kcal: (meal['kcal'] as num?)?.toInt(),
            protein: (meal['protein'] as num?)?.toInt(),
            carbs: (meal['carbs'] as num?)?.toInt(),
            fat: (meal['fat'] as num?)?.toInt(),
            cookType: cookType,
            notes: notes,
          ),
        );
      }
    }

    await MealPlanService.savePlans(plansToSave);

    if (mounted) {
      setState(() {
        data['isConfirmedAndSaved'] = true;
        msg.isActionDone = true;
        _messages.add(
          ChatMessage.botText(
            '🎉 **Đã lưu thành công ${plansToSave.length} bữa ăn vào Trang Lịch!**\n\n'
            'Hệ thống đã tự động kích hoạt thông báo nhắc rã đông lúc 20:00 tối trước ngày ăn. Bạn có thể mở Trang Lịch để theo dõi ngay!',
          ),
        );
      });
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🍱 Đã đồng bộ thực đơn vào Trang Lịch thành công!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'XEM LỊCH',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MealPrepScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  void _showRecipeDetailsDialog(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(recipe['icon']?.toString() ?? '🍲', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                recipe['title']?.toString() ?? 'Chi tiết món ăn',
                style: AppTypography.titleMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Macro badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('🔥 ${recipe['kcal'] ?? 0} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('💪 ${recipe['protein'] ?? 0}g đạm', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                    Text('⏱️ ${recipe['time'] ?? 15}p', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (recipe['description'] != null && recipe['description'].toString().isNotEmpty) ...[
                Text(recipe['description'].toString(), style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
              ],
              Text('Hướng dẫn chế biến:', style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                recipe['instructions']?.toString() ?? 'Đang cập nhật hướng dẫn cho món ăn này...',
                style: AppTypography.bodySmall(color: AppColors.onSurface),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.outline, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NutriGym AI',
                  style: AppTypography.titleSmallBold(color: AppColors.onSurface),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Trực tuyến · Trợ lý Dinh Dưỡng',
                      style: AppTypography.labelBold(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            tooltip: 'Tùy chọn lập Meal Prep',
            onPressed: () => _showMealPrepOptionsSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: () {
              setState(() {
                NutriGymChatbotScreen.sessionMessages.clear();
                _addInitialBotGreeting();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Danh sách tin nhắn hội thoại
            Expanded(
              child: ListView.builder(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  final msg = _messages[index];
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return _buildMessageItem(
                    msg,
                    isFirstGreeting: index == 0 && !msg.isUser && _messages.length == 1,
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Live speech transcript indicator
            if (_isListening)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      ),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.fire,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _liveTranscript.isEmpty ? 'Đang lắng nghe bạn nói...' : '"$_liveTranscript"',
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.onSurface),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleListening,
                      child: const Text('Dừng', style: TextStyle(color: AppColors.fire, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // 2. Thanh gợi ý câu hỏi nhanh (Quick Prompts)
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  height: 42,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _quickPrompts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final prompt = _quickPrompts[idx];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendMessage(prompt),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2824) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? AppColors.primary.withValues(alpha: 0.35) : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              prompt,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // 3. Thanh nhập liệu (Text Input + Microphone Button)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.outline)),
              ),
              child: Row(
                children: [
                  // Nút Micro thu âm trực tiếp
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, child) => Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: child,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isListening ? AppColors.fire : AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic_none_rounded,
                          color: _isListening ? Colors.white : AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Khung nhập câu lệnh
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Hỏi dinh dưỡng hoặc lên thực đơn...',
                        hintStyle: AppTypography.bodyDefault(color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.outline),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút Gửi
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg, {bool isFirstGreeting = false, bool isDark = false}) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      );
    }

    // Tin nhắn của Bot
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.smart_toy, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khung văn bản chính của bot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: AppColors.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(color: AppColors.onSurface, fontSize: 14, height: 1.4),
                  ),
                ),

                // Danh sách câu hỏi gợi ý khi bắt đầu cuộc trò chuyện
                if (isFirstGreeting) ...[
                  const SizedBox(height: 12),
                  _buildWelcomeSuggestions(isDark),
                ],

                // 1. Khối hành động nguyên liệu bóc tách được
                if (msg.type == ChatMessageType.ingredientsAction && msg.ingredients != null) ...[
                  const SizedBox(height: 8),
                  _buildIngredientsActionCard(msg),
                ],

                // 2. Khối thẻ gợi ý công thức nấu ăn
                if (msg.type == ChatMessageType.recipeSuggestions && msg.recipes != null) ...[
                  const SizedBox(height: 8),
                  _buildRecipeSuggestionsList(msg.recipes!),
                ],

                // 3. Khối đề xuất Kế hoạch Thực Đơn Thông Minh (Meal Plan Proposal)
                if (msg.type == ChatMessageType.mealPlanProposal && msg.mealPlanData != null) ...[
                  const SizedBox(height: 8),
                  _buildMealPlanProposalCard(msg),
                ],

                // 4. Khối câu hỏi tương tác chọn tùy chọn lập kế hoạch (Interactive Questionnaire)
                if (msg.type == ChatMessageType.interactiveQuestionnaire && msg.questionnaireData != null) ...[
                  const SizedBox(height: 8),
                  _buildInteractiveQuestionnaireCard(msg),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSuggestions(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'GỢI Ý CÂU HỎI PHỔ BIẾN CHO GYMER',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.primary : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...quickQuestionCards.map((q) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _sendMessage(q['prompt']!),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2622) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF26322B) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(q['icon']!, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q['title']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                q['subtitle']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LẬP LỊCH MEAL PREP & CARB CYCLING TƯƠNG TÁC (QUESTION WIZARD TRONG CHAT)
  // ---------------------------------------------------------------------------
  Future<void> _startMealPlanInteractiveQuestionnaire(String userPrompt) async {
    final profile = await ApiService.getLocalProfile();
    final prefs = await SharedPreferences.getInstance();

    String selectedGoal = profile?['fitnessGoal']?.toString() ?? prefs.getString('user_custom_goal') ?? 'Tăng cơ giảm mỡ';
    if (selectedGoal == 'hypertrophy' || selectedGoal == 'bulking') selectedGoal = 'Tăng cơ';
    if (selectedGoal == 'cutting' || selectedGoal == 'fat_loss') selectedGoal = 'Giảm mỡ';
    if (selectedGoal == 'maintenance') selectedGoal = 'Duy trì vóc dáng';


    final rawMedical = prefs.getStringList('medical_history') ??
        (profile?['medicalHistory'] != null ? List<String>.from(profile!['medicalHistory']) : <String>[]);
    final rawAllergies = prefs.getStringList('food_allergies') ??
        prefs.getStringList('user_allergies') ??
        (profile?['allergies'] != null ? List<String>.from(profile!['allergies']) : <String>[]);

    final List<String> selectedMedical = rawMedical.where((m) => !m.toLowerCase().contains('không có')).toList();
    if (selectedMedical.isEmpty) selectedMedical.add('Không có tiền sử bệnh');

    final List<String> selectedAllergies = rawAllergies.where((a) => !a.toLowerCase().contains('không có')).toList();
    if (selectedAllergies.isEmpty) selectedAllergies.add('Không có dị ứng');

    final bool isGoalFocused = userPrompt.toLowerCase().contains('mục tiêu');
    final String wizardTitle = isGoalFocused ? 'LẬP THỰC ĐƠN THEO MỤC TIÊU' : 'LÊN LỊCH MEAL PREP';

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage.user(userPrompt));
      _messages.add(
        ChatMessage(
          id: 'questionnaire_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Vui lòng chọn các tùy chọn phù hợp trước khi tôi lập bảng thực đơn chi tiết:',
          isUser: false,
          timestamp: DateTime.now(),
          type: ChatMessageType.interactiveQuestionnaire,
          questionnaireData: {
            'wizardTitle': wizardTitle,
            'currentStep': 0,
            'goal': null, // Bắt đầu chưa tick để người dùng tự chọn
            'daysCount': null,
            'prepMode': null,
            'sourceMode': null,
            'forceFromFridge': null,
            'medicalHistory': selectedMedical,
            'allergies': selectedAllergies,
          },
        ),
      );
    });
    _scrollToBottom();
  }

  Widget _buildFoodIconWidget(String icon, {double size = 20}) {
    if (icon.startsWith('assets/') || icon.endsWith('.png')) {
      return Image.asset(
        icon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Text('🥗', style: TextStyle(fontSize: size * 0.85)),
      );
    }
    return Text(icon, style: TextStyle(fontSize: size * 0.85));
  }

  Widget _buildInteractiveQuestionnaireCard(ChatMessage msg) {
    final qData = msg.questionnaireData!;
    final isDone = msg.isActionDone;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int currentStep = (qData['currentStep'] as num?)?.toInt() ?? 0;
    if (isDone) currentStep = 4;

    String? currentGoal = qData['goal']?.toString();
    int? currentDays = (qData['daysCount'] is num) ? (qData['daysCount'] as num).toInt() : null;
    String? currentPrepMode = qData['prepMode']?.toString();
    bool? forceFridge = qData['forceFromFridge'] as bool?;
    String? currentSourceMode = qData['sourceMode']?.toString();
    if (currentSourceMode == null && forceFridge != null) {
      currentSourceMode = forceFridge ? 'fridge_only' : 'market_only';
    }
    final List medical = (qData['medicalHistory'] as List?) ?? ['Không có tiền sử bệnh'];
    final List allergies = (qData['allergies'] as List?) ?? ['Không có dị ứng'];

    String prepTitle = 'Kết hợp Meal Prep & Tươi';
    if (currentPrepMode == 'carb_cycling') prepTitle = 'Carb Cycling';
    if (currentPrepMode == 'full_prep') prepTitle = '100% Cấp đông';
    if (currentPrepMode == 'fresh') prepTitle = 'Nấu tươi mỗi bữa';

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2420) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.outlineVariant,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header với bước hiện tại
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          qData['wizardTitle']?.toString() ?? 'LÊN LỊCH MEAL PREP & THỰC ĐƠN',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          currentStep >= 4
                              ? '✨ Đã hoàn tất khảo sát & thiết lập kế hoạch'
                              : '🎯 Bước ${currentStep + 1}/4: Trả lời từng câu hỏi để AI thiết kế',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: currentStep >= 4 ? const Color(0xFF10B981) : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Hiển thị tóm tắt các lựa chọn đã chọn ở các bước trước
              if (currentStep > 0 && currentStep < 4) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (currentStep > 0)
                      Chip(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: (isDark ? AppColors.primary : const Color(0xFFE0F2FE)),
                        label: Text('✓ $currentGoal', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.black : const Color(0xFF0284C7))),
                      ),
                    if (currentStep > 1)
                      Chip(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: (isDark ? AppColors.primary : const Color(0xFFE0F2FE)),
                        label: Text('✓ $currentDays ngày', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.black : const Color(0xFF0284C7))),
                      ),
                    if (currentStep > 2)
                      Chip(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: (isDark ? AppColors.primary : const Color(0xFFE0F2FE)),
                        label: Text('✓ $prepTitle', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.black : const Color(0xFF0284C7))),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // =======================================================
              // BƯỚC 0: CÂU HỎI 1 - MỤC TIÊU THỂ HÌNH
              // =======================================================
              if (currentStep == 0) ...[
                Text(
                  '🎯 Câu hỏi 1: Mục tiêu thể hình của bạn là gì?',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn 1 phương án bên dưới để chuyển sang câu tiếp theo:',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    {'val': 'Tăng cơ giảm mỡ', 'label': '(Recommended) Tăng cơ giảm mỡ'},
                    {'val': 'Giảm mỡ', 'label': 'Giảm mỡ siết cơ'},
                    {'val': 'Tăng cơ', 'label': 'Tăng cân tăng cơ'},
                    {'val': 'Duy trì vóc dáng', 'label': 'Duy trì vóc dáng & Sức khỏe'},
                  ].map((item) {
                    final isSel = currentGoal != null && currentGoal == item['val'];
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 7),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          alignment: Alignment.centerLeft,
                          backgroundColor: isSel ? (isDark ? AppColors.primary.withValues(alpha: 0.25) : const Color(0xFFE0F2FE)) : Colors.transparent,
                          side: BorderSide(
                            color: isSel ? AppColors.primary : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            width: isSel ? 1.8 : 1.0,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setCardState(() {
                            currentGoal = item['val']!;
                            qData['goal'] = currentGoal;
                            qData['currentStep'] = 1;
                          });
                          setState(() {});
                        },
                        child: Row(
                          children: [
                            Icon(isSel ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: isSel ? AppColors.primary : (isDark ? Colors.white54 : Colors.grey)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['label']!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // =======================================================
              // BƯỚC 1: CÂU HỎI 2 - THỜI LƯỢNG KẾ HOẠCH
              // =======================================================
              if (currentStep == 1) ...[
                Text(
                  '📅 Câu hỏi 2: Thời lượng kế hoạch thực đơn?',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn số ngày thực hiện cho chu kỳ ăn uống này:',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    {'val': 7, 'label': '(Recommended) 7 ngày (1 tuần chuẩn Gymer)'},
                    {'val': 5, 'label': '5 ngày (Thứ 2 đến Thứ 6 - Đi làm)'},
                    {'val': 3, 'label': '3 ngày (Meal Prep ngắn hạn trải nghiệm)'},
                  ].map((item) {
                    final isSel = currentDays != null && currentDays == item['val'];
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 7),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          alignment: Alignment.centerLeft,
                          backgroundColor: isSel ? (isDark ? AppColors.primary.withValues(alpha: 0.25) : const Color(0xFFE0F2FE)) : Colors.transparent,
                          side: BorderSide(
                            color: isSel ? AppColors.primary : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            width: isSel ? 1.8 : 1.0,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setCardState(() {
                            currentDays = item['val'] as int;
                            qData['daysCount'] = currentDays;
                            qData['currentStep'] = 2;
                          });
                          setState(() {});
                        },
                        child: Row(
                          children: [
                            Icon(isSel ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: isSel ? AppColors.primary : (isDark ? Colors.white54 : Colors.grey)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // =======================================================
              // BƯỚC 2: CÂU HỎI 3 - CHẾ ĐỘ NẤU NƯỚNG & DINH DƯỠNG
              // =======================================================
              if (currentStep == 2) ...[
                Text(
                  '⚡ Câu hỏi 3: Chế độ dinh dưỡng & nấu nướng?',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn phong cách chế biến phù hợp với lịch tập của bạn:',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    {'val': 'carb_cycling', 'label': '⚡ Carb Cycling (Xoay vòng Carb Ngày cao/thấp)'},
                    {'val': 'hybrid', 'label': '🍱 Kết hợp Meal Prep & Tươi (Tiện lợi nhất)'},
                    {'val': 'full_prep', 'label': '❄️ 100% Meal Prep cấp đông (Nấu 1 lần cả tuần)'},
                    {'val': 'fresh', 'label': '🍳 Nấu tươi mỗi bữa (Ăn nóng sốt hàng ngày)'},
                  ].map((item) {
                    final isSel = currentPrepMode != null && currentPrepMode == item['val'];
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 7),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          alignment: Alignment.centerLeft,
                          backgroundColor: isSel ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFFE0F7FA)) : Colors.transparent,
                          side: BorderSide(
                            color: isSel ? const Color(0xFF00E5FF) : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            width: isSel ? 1.8 : 1.0,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setCardState(() {
                            currentPrepMode = item['val']!;
                            qData['prepMode'] = currentPrepMode;
                            qData['currentStep'] = 3;
                          });
                          setState(() {});
                        },
                        child: Row(
                          children: [
                            Icon(isSel ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: isSel ? const Color(0xFF00E5FF) : (isDark ? Colors.white54 : Colors.grey)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['label']!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // =======================================================
              // BƯỚC 3: CÂU HỎI 4 - NGUỒN NGUYÊN LIỆU THỰC PHẨM
              // =======================================================
              if (currentStep == 3) ...[
                Text(
                  '🧊 Câu hỏi 4: Nguồn nguyên liệu thực phẩm?',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn cách kết hợp nguyên liệu tủ lạnh và đi chợ để tối ưu Calo:',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    {
                      'val': 'hybrid',
                      'icon': '🔄',
                      'label': 'Tối ưu tủ lạnh và mua nguyên liệu',
                      'desc': 'Dùng đồ trong tủ & đi chợ mua bù phần thiếu. Bắt buộc đạt đủ 100% Calo & Macros.',
                      'isRecommended': true,
                    },
                    {
                      'val': 'market_only',
                      'icon': '🛒',
                      'label': 'Đi chợ mua mới toàn bộ',
                      'desc': 'Lập từ kho công thức phong phú Gymer. Bắt buộc đạt đủ 100% Calo & Macros.',
                      'isRecommended': false,
                    },
                    {
                      'val': 'fridge_only',
                      'icon': '🧊',
                      'label': 'Tối ưu có sẵn trong Tủ Lạnh',
                      'desc': 'Chỉ ưu tiên nấu từ các nguyên liệu đang có sẵn trong tủ lạnh.',
                      'isRecommended': false,
                    },
                  ].map((item) {
                    final isSel = currentSourceMode == item['val'];
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          alignment: Alignment.centerLeft,
                          backgroundColor: isSel ? (isDark ? AppColors.green.withValues(alpha: 0.2) : const Color(0xFFDCFCE7)) : Colors.transparent,
                          side: BorderSide(
                            color: isSel ? AppColors.green : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            width: isSel ? 1.8 : 1.0,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setCardState(() {
                            currentSourceMode = item['val'] as String;
                            qData['sourceMode'] = currentSourceMode;
                            qData['forceFromFridge'] = currentSourceMode == 'fridge_only';
                            forceFridge = currentSourceMode == 'fridge_only';
                            qData['currentStep'] = 4;
                            msg.isActionDone = true;
                          });
                          setState(() {});

                          String pTitle = 'Kết hợp Meal Prep & Nấu tươi';
                          if (currentPrepMode == 'full_prep') pTitle = 'Meal Prep toàn bộ';
                          if (currentPrepMode == 'fresh') pTitle = 'Nấu tươi mỗi ngày';
                          if (currentPrepMode == 'carb_cycling') pTitle = 'Carb Cycling';

                          ChatMessage? existingMealPlanMsg;
                          try {
                            existingMealPlanMsg = _messages.lastWhere((m) => m.type == ChatMessageType.mealPlanProposal);
                          } catch (_) {}

                          final optionsMap = {
                            'goal': currentGoal,
                            'daysCount': currentDays,
                            'prepMode': currentPrepMode,
                            'sourceMode': currentSourceMode,
                            'forceFromFridge': currentSourceMode == 'fridge_only',
                            'medicalHistory': medical,
                            'allergies': allergies,
                          };

                          if (existingMealPlanMsg != null) {
                            setState(() {
                              _isTyping = true;
                            });
                            NutriGymChatService.generateMealPlan(
                              prompt: 'Lập kế hoạch thực đơn $currentDays ngày',
                              forceFromFridge: currentSourceMode == 'fridge_only',
                              customOptions: optionsMap,
                            ).then((updatedMsg) {
                              if (mounted) {
                                setState(() {
                                  _isTyping = false;
                                  final idx = _messages.indexOf(existingMealPlanMsg!);
                                  if (idx != -1) {
                                    _messages[idx] = updatedMsg;
                                  } else {
                                    _messages.add(updatedMsg);
                                  }
                                });
                                _scrollToBottom();
                              }
                            });
                          } else {
                            final promptText = 'Lập kế hoạch thực đơn $currentDays ngày ($currentGoal, $pTitle)';
                            _sendMessage(
                              promptText,
                              customMealPlanOptions: optionsMap,
                            );
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(isSel ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: isSel ? AppColors.green : (isDark ? Colors.white54 : Colors.grey)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${item['icon']} ${item['label']}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                          color: isSel ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                        ),
                                      ),
                                      if (item['isRecommended'] == true) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Khuyên dùng', style: TextStyle(fontSize: 9.5, color: AppColors.green, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // =======================================================
              // BƯỚC 4: ĐÃ HOÀN TẤT - HIỂN THỊ TÓM TẮT & NÚT TÙY CHỌN LẠI
              // =======================================================
              if (currentStep >= 4) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151B18) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã xác nhận cấu hình thực đơn:',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('• 🎯 Mục tiêu: $currentGoal', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                      Text('• 📅 Thời lượng: $currentDays ngày', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                      Text('• ⚡ Chế độ: $prepTitle', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                      Text(
                        '• 🧊 Nguồn thực phẩm: ${currentSourceMode == 'fridge_only' ? 'Tối ưu có sẵn trong Tủ Lạnh' : (currentSourceMode == 'market_only' ? 'Đi chợ mua mới toàn bộ' : 'Tối ưu tủ lạnh và mua nguyên liệu')}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• 🩺 Sức khỏe: ${medical.join(', ')} | Dị ứng: ${allergies.join(', ')}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Tùy chọn lại các câu hỏi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      setCardState(() {
                        qData['currentStep'] = 0;
                        qData['goal'] = null;
                        qData['daysCount'] = null;
                        qData['prepMode'] = null;
                        qData['sourceMode'] = null;
                        qData['forceFromFridge'] = null;
                        currentSourceMode = null;
                        forceFridge = null;
                        msg.isActionDone = false;
                      });
                      setState(() {});
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TÙY CHỌN LẬP KẾ HOẠCH MEAL PREP (OPTIONS SHEET)
  // ---------------------------------------------------------------------------
  Future<void> _showMealPrepOptionsSheet({ChatMessage? targetMealPlanMsg}) async {
    final profile = await ApiService.getLocalProfile();
    final prefs = await SharedPreferences.getInstance();

    String selectedGoal = targetMealPlanMsg?.mealPlanData?['goal']?.toString() ??
        profile?['fitnessGoal']?.toString() ??
        prefs.getString('user_custom_goal') ??
        'Tăng cơ';
    if (selectedGoal == 'hypertrophy' || selectedGoal == 'bulking') selectedGoal = 'Tăng cơ';
    if (selectedGoal == 'cutting' || selectedGoal == 'fat_loss') selectedGoal = 'Giảm mỡ';
    if (selectedGoal == 'maintenance') selectedGoal = 'Duy trì vóc dáng';

    int selectedDaysCount = (targetMealPlanMsg?.mealPlanData?['days'] as List?)?.length ?? 3;
    String selectedPrepMode = targetMealPlanMsg?.mealPlanData?['prepMode']?.toString() ?? 'hybrid';
    String selectedSourceMode = targetMealPlanMsg?.mealPlanData?['sourceMode']?.toString() ??
        (targetMealPlanMsg?.mealPlanData?['forceFromFridge'] == true ? 'fridge_only' : 'hybrid');
    bool forceFromFridge = selectedSourceMode == 'fridge_only';

    final rawMedical = prefs.getStringList('medical_history') ??
        (profile?['medicalHistory'] != null ? List<String>.from(profile!['medicalHistory']) : <String>[]);
    final rawAllergies = prefs.getStringList('food_allergies') ??
        prefs.getStringList('user_allergies') ??
        (profile?['allergies'] != null ? List<String>.from(profile!['allergies']) : <String>[]);

    final Set<String> selectedMedical = Set<String>.from(rawMedical.where((m) => !m.toLowerCase().contains('không có')));
    if (selectedMedical.isEmpty) selectedMedical.add('Không có tiền sử bệnh');

    final Set<String> selectedAllergies = Set<String>.from(rawAllergies.where((a) => !a.toLowerCase().contains('không có')));
    if (selectedAllergies.isEmpty) selectedAllergies.add('Không có dị ứng');


    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2420) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget buildSelectChip({
            required String label,
            required bool isSelected,
            required VoidCallback onTap,
          }) {
            final activeBg = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0F172A);
            final activeFg = isDark ? Colors.black : Colors.white;
            final inactiveBg = isDark ? const Color(0xFF151B18) : const Color(0xFFF1F5F9);
            final inactiveFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? activeBg : inactiveBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? activeBg : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                      width: isSelected ? 1.6 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0F172A)).withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(Icons.check_rounded, size: 16, color: activeFg),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? activeFg : inactiveFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SafeArea(
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.88,
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            targetMealPlanMsg != null ? 'Chỉnh sửa Cấu hình Thực đơn' : 'Tùy chọn Lập Meal Prep',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        // 1. Mục tiêu thể hình
                        Text('1. Mục tiêu thể hình:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Tăng cơ', 'Giảm mỡ', 'Duy trì vóc dáng', 'Tăng cơ giảm mỡ'].map((g) {
                            final isSel = selectedGoal == g;
                            return buildSelectChip(
                              label: g,
                              isSelected: isSel,
                              onTap: () => setSheetState(() => selectedGoal = g),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // 2. Số ngày lên lịch
                        Text('2. Số ngày lên lịch thực đơn:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            {'days': 3, 'label': '3 ngày (Đầu tuần)'},
                            {'days': 5, 'label': '5 ngày (Thứ 2 - Thứ 6)'},
                            {'days': 7, 'label': '7 ngày (Cả tuần)'},
                          ].map((item) {
                            final d = item['days'] as int;
                            final isSel = selectedDaysCount == d;
                            return buildSelectChip(
                              label: item['label'] as String,
                              isSelected: isSel,
                              onTap: () => setSheetState(() => selectedDaysCount = d),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // 3. Chế độ chuẩn bị bữa ăn (Cooking Style)
                        Text('3. Chế độ chuẩn bị bữa ăn:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            {'key': 'hybrid', 'label': '🍱 Kết hợp Meal Prep & Nấu tươi'},
                            {'key': 'full_prep', 'label': '❄️ Meal Prep 100% (Cấp đông)'},
                            {'key': 'fresh', 'label': '🍳 Nấu tươi mỗi bữa (15-20p)'},
                            {'key': 'carb_cycling', 'label': '⚡ Carb Cycling (Xoay vòng tinh bột)'},
                          ].map((mode) {
                            final k = mode['key'] as String;
                            final isSel = selectedPrepMode == k;
                            return buildSelectChip(
                              label: mode['label'] as String,
                              isSelected: isSel,
                              onTap: () => setSheetState(() => selectedPrepMode = k),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // 4. Bệnh lí & Dị ứng (Tự động đồng bộ từ Cài đặt)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Hồ sơ Sức khỏe & Dị ứng (Lấy từ Cài đặt):',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '• Bệnh lí / Kiêng cữ: ${selectedMedical.isNotEmpty ? selectedMedical.join(', ') : 'Không có tiền sử bệnh'}\n• Dị ứng thực phẩm: ${selectedAllergies.isNotEmpty ? selectedAllergies.join(', ') : 'Không có dị ứng'}',
                                style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '💡 NutriGym AI luôn tự động lọc bỏ các món kiêng & dị ứng trên. Muốn thay đổi hãy vào Cài đặt > Bệnh lí và dị ứng.',
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 5. Nguồn nguyên liệu
                        const Text(
                          '5. Nguồn thực phẩm & Tối ưu Calo:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          children: [
                            {
                              'val': 'hybrid',
                              'icon': '🔄',
                              'title': 'Tối ưu tủ lạnh và mua nguyên liệu bù đắp',
                              'desc': 'Dùng đồ trong tủ & đi chợ bù phần thiếu. Bắt buộc đủ 100% Calo.',
                            },
                            {
                              'val': 'market_only',
                              'icon': '🛒',
                              'title': 'Đi chợ mua mới toàn bộ',
                              'desc': 'Lập từ kho công thức phong phú Gymer. Bắt buộc đủ 100% Calo.',
                            },
                            {
                              'val': 'fridge_only',
                              'icon': '🧊',
                              'title': 'Tối ưu có sẵn trong Tủ Lạnh',
                              'desc': 'Chỉ ưu tiên nấu từ các nguyên liệu có sẵn trong tủ.',
                            },
                          ].map((item) {
                            final isSel = selectedSourceMode == item['val'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () => setSheetState(() {
                                  selectedSourceMode = item['val'] as String;
                                  forceFromFridge = selectedSourceMode == 'fridge_only';
                                }),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.green.withValues(alpha: 0.15) : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel ? AppColors.green : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(item['icon'] as String, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                                color: isSel ? (isDark ? Colors.white : AppColors.primary) : null,
                                              ),
                                            ),
                                            Text(item['desc'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      if (isSel) const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Nút Tạo kế hoạch
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        targetMealPlanMsg != null ? 'CẬP NHẬT TRỰC TIẾP VÀO BẢNG NÀY' : 'TẠO KẾ HOẠCH THEO TÙY CHỌN NÀY',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);

                        String prepTitle = 'Kết hợp Meal Prep & Nấu tươi';
                        if (selectedPrepMode == 'full_prep') prepTitle = 'Meal Prep toàn bộ';
                        if (selectedPrepMode == 'fresh') prepTitle = 'Nấu tươi mỗi ngày';
                        if (selectedPrepMode == 'carb_cycling') prepTitle = 'Carb Cycling';

                        final promptText = 'Lập kế hoạch mealprep $selectedDaysCount ngày ($selectedGoal, $prepTitle)';

                        final optionsMap = {
                          'goal': selectedGoal,
                          'daysCount': selectedDaysCount,
                          'prepMode': selectedPrepMode,
                          'sourceMode': selectedSourceMode,
                          'forceFromFridge': selectedSourceMode == 'fridge_only',
                          'medicalHistory': selectedMedical.toList(),
                          'allergies': selectedAllergies.toList(),
                        };

                        if (targetMealPlanMsg != null) {
                          // Chỉnh sửa trực tiếp trên bảng hiện có thay vì tạo tin nhắn mới
                          final updatedMsg = await NutriGymChatService.generateMealPlan(
                            prompt: promptText,
                            forceFromFridge: forceFromFridge,
                            customOptions: optionsMap,
                          );
                          setState(() {
                            final idx = _messages.indexOf(targetMealPlanMsg);
                            if (idx != -1) {
                              _messages[idx] = updatedMsg;
                            }
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✨ Đã cập nhật lại kế hoạch thực đơn trực tiếp trên bảng này!'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          _sendMessage(
                            promptText,
                            customMealPlanOptions: optionsMap,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CHỈNH SỬA BẢNG THỰC ĐƠN CỦA CHATBOT (MEAL PLAN EDITOR)
  // ---------------------------------------------------------------------------
  void _openMealPlanEditor(ChatMessage msg, {int initialDayIdx = 0}) {
    final data = msg.mealPlanData;
    if (data == null) return;

    final rawDays = data['days'] as List? ?? [];
    // Deep clone days
    final List<Map<String, dynamic>> editedDays = rawDays.map((d) {
      final dm = Map<String, dynamic>.from(d as Map);
      final rawMeals = dm['meals'] as List? ?? [];
      dm['meals'] = rawMeals.map((m) {
        final mm = Map<String, dynamic>.from(m as Map);
        if (mm['ingredients'] is List) {
          mm['ingredients'] = (mm['ingredients'] as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
        }
        return mm;
      }).toList();
      return dm;
    }).toList();

    int activeDay = (initialDayIdx >= 0 && initialDayIdx < editedDays.length) ? initialDayIdx : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2420) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setEditorState) {
          final currentDay = editedDays[activeDay];
          final meals = currentDay['meals'] as List;
          final bool isPrep = currentDay['isMealPrep'] == true;

          return SafeArea(
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.88,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF7C3AED), size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chỉnh sửa Thực Đơn',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Day Tabs
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: editedDays.length,
                      itemBuilder: (_, i) {
                        final isSel = i == activeDay;
                        final d = editedDays[i];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '${d['dayName']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : AppColors.onSurface,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            backgroundColor: isDark ? const Color(0xFF262E2A) : const Color(0xFFF1F5F9),
                            onSelected: (val) {
                              if (val) {
                                setEditorState(() {
                                  activeDay = i;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Day settings bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${currentDay['dayName']} (${currentDay['date']})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        ChoiceChip(
                          label: Text(isPrep ? '❄️ Meal Prep' : '🍳 Nấu tươi', style: const TextStyle(fontSize: 11)),
                          selected: isPrep,
                          selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                          onSelected: (val) {
                            setEditorState(() {
                              currentDay['isMealPrep'] = val;
                              currentDay['cookType'] = val ? 'Meal Prep cấp đông' : 'Nấu tươi theo bữa';
                              if (val) {
                                currentDay['defrostAlert'] = '💡 Nhắc rã đông lúc 20:00 tối trước ngày ăn';
                              } else {
                                currentDay.remove('defrostAlert');
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Meals list
                  Expanded(
                    child: ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (_, mIdx) {
                        final meal = meals[mIdx] as Map<String, dynamic>;
                        final type = meal['type']?.toString() ?? 'Bữa ăn';
                        final name = meal['name']?.toString() ?? '';
                        final kcal = (meal['kcal'] as num?)?.toInt() ?? 0;
                        final pro = (meal['protein'] as num?)?.toInt() ?? 0;
                        final carb = (meal['carbs'] as num?)?.toInt() ?? 0;
                        final fat = (meal['fat'] as num?)?.toInt() ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      type,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$kcal kcal  •  ${pro}P / ${carb}C / ${fat}F',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.fire),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Xóa món',
                                    onPressed: () {
                                      setEditorState(() {
                                        meals.removeAt(mIdx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.swap_horiz_rounded, size: 15),
                                      label: const Text('Đổi món', style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        _showRecipePickerModal(
                                          onSelected: (newRecipe) {
                                            setEditorState(() {
                                              meal['name'] = (newRecipe['title'] ?? newRecipe['name']).toString();
                                              meal['kcal'] = (newRecipe['kcal'] as num?)?.toInt() ?? 400;
                                              meal['protein'] = (newRecipe['protein'] as num?)?.toInt() ?? 30;
                                              meal['carbs'] = (newRecipe['carbs'] as num?)?.toInt() ?? 30;
                                              meal['fat'] = (newRecipe['fat'] as num?)?.toInt() ?? 10;
                                              if (newRecipe['ingredients'] is List) {
                                                meal['ingredients'] = newRecipe['ingredients'];
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: const Text('Sửa chỉ số', style: TextStyle(fontSize: 11)),
                                      onPressed: () => _showEditMealStatsDialog(meal, () => setEditorState(() {})),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Button to add meal to day
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, style: BorderStyle.solid),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                      label: Text('Thêm món vào ${currentDay['dayName']}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        _showRecipePickerModal(
                          onSelected: (newRecipe) {
                            setEditorState(() {
                              meals.add({
                                'type': 'Bữa Phụ',
                                'name': (newRecipe['title'] ?? newRecipe['name']).toString(),
                                'kcal': (newRecipe['kcal'] as num?)?.toInt() ?? 350,
                                'protein': (newRecipe['protein'] as num?)?.toInt() ?? 25,
                                'carbs': (newRecipe['carbs'] as num?)?.toInt() ?? 30,
                                'fat': (newRecipe['fat'] as num?)?.toInt() ?? 8,
                                'ingredients': newRecipe['ingredients'] ?? [],
                              });
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Save and apply changes
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('LƯU & CẬP NHẬT THỰC ĐƠN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () async {
                        // Tính lại Macro TB & Shopping list
                        int tKcal = 0;
                        int tPro = 0;
                        int tCarb = 0;
                        int tFat = 0;
                        final Map<String, int> ingNeeds = {};

                        for (final d in editedDays) {
                          for (final m in d['meals'] as List) {
                            tKcal += (m['kcal'] as num?)?.toInt() ?? 0;
                            tPro += (m['protein'] as num?)?.toInt() ?? 0;
                            tCarb += (m['carbs'] as num?)?.toInt() ?? 0;
                            tFat += (m['fat'] as num?)?.toInt() ?? 0;

                            final ings = m['ingredients'] as List? ?? [];
                            for (final ing in ings) {
                              if (ing is Map) {
                                final n = (ing['name'] ?? '').toString();
                                final a = (ing['amount'] as num?)?.toInt() ?? 100;
                                if (n.isNotEmpty) {
                                  ingNeeds[n] = (ingNeeds[n] ?? 0) + a;
                                }
                              }
                            }
                          }
                        }

                        final int daysCount = editedDays.isNotEmpty ? editedDays.length : 1;
                        final newAvgKcal = (tKcal / daysCount).round();
                        final newAvgPro = (tPro / daysCount).round();
                        final newAvgCarb = (tCarb / daysCount).round();
                        final newAvgFat = (tFat / daysCount).round();

                        // So sánh tủ lạnh
                        final prefs = await SharedPreferences.getInstance();
                        final userId = await ApiService.getUserId() ?? 'guest';
                        final fridgeJson = prefs.getString('smart_fridge_items_$userId');
                        List<Map<String, dynamic>> fridgeItems = [];
                        if (fridgeJson != null && fridgeJson.isNotEmpty) {
                          try {
                            final List<dynamic> dec = jsonDecode(fridgeJson);
                            fridgeItems = dec.map((e) => Map<String, dynamic>.from(e)).toList();
                          } catch (_) {}
                        }

                        final List<Map<String, dynamic>> newShoppingList = [];
                        ingNeeds.forEach((name, neededGrams) {
                          int inFridgeGrams = 0;
                          for (final f in fridgeItems) {
                            final fName = f['name']?.toString().toLowerCase() ?? '';
                            if (fName.contains(name.toLowerCase()) || name.toLowerCase().contains(fName)) {
                              inFridgeGrams += ((f['weight'] as num?)?.toInt() ?? 0);
                            }
                          }
                          final int toBuyGrams = neededGrams > inFridgeGrams ? (neededGrams - inFridgeGrams) : 0;
                          final details = IngredientNormalizer.getIngredientDetails(name);
                          newShoppingList.add({
                            'name': name,
                            'needed': neededGrams,
                            'inFridge': inFridgeGrams,
                            'toBuy': toBuyGrams,
                            'unit': 'g',
                            'icon': details['icon'] ?? '🥗',
                            'isShortfall': toBuyGrams > 0,
                          });
                        });

                        newShoppingList.sort((a, b) {
                          if (a['isShortfall'] == true && b['isShortfall'] != true) return -1;
                          if (a['isShortfall'] != true && b['isShortfall'] == true) return 1;
                          return (b['toBuy'] as num).compareTo(a['toBuy'] as num);
                        });

                        setState(() {
                          data['days'] = editedDays;
                          data['avgDailyKcal'] = newAvgKcal;
                          data['avgDailyPro'] = newAvgPro;
                          data['avgDailyCarbs'] = newAvgCarb;
                          data['avgDailyFat'] = newAvgFat;
                          data['shoppingList'] = newShoppingList;

                          final targetCal = (data['targetCalories'] as num?)?.toInt() ?? 2200;
                          final diff = newAvgKcal - targetCal;
                          if (diff.abs() > 250) {
                            data['hasThresholdWarning'] = true;
                            data['thresholdWarning'] = diff > 0
                                ? '⚠️ CẢNH BÁO NGƯỠNG: Calo ($newAvgKcal kcal) cao hơn $diff kcal so với mục tiêu ($targetCal kcal).'
                                : '⚠️ CẢNH BÁO NGƯỠNG: Calo ($newAvgKcal kcal) thiếu ${diff.abs()} kcal so với mục tiêu ($targetCal kcal).';
                          } else {
                            data['hasThresholdWarning'] = false;
                            data['thresholdWarning'] = '';
                          }
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Đã cập nhật thực đơn theo chỉnh sửa của bạn!'),
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditMealStatsDialog(Map<String, dynamic> meal, VoidCallback onSaved) {
    final nameCtrl = TextEditingController(text: meal['name']?.toString() ?? '');
    final kcalCtrl = TextEditingController(text: '${meal['kcal'] ?? 0}');
    final proCtrl = TextEditingController(text: '${meal['protein'] ?? 0}');
    final carbCtrl = TextEditingController(text: '${meal['carbs'] ?? 0}');
    final fatCtrl = TextEditingController(text: '${meal['fat'] ?? 0}');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Chỉnh sửa chỉ số món', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên món ăn', isDense: true),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: kcalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Kcal', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: proCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Protein (g)', isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carbCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carbs (g)', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fat (g)', isDense: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              meal['name'] = nameCtrl.text.trim();
              meal['kcal'] = int.tryParse(kcalCtrl.text) ?? meal['kcal'];
              meal['protein'] = int.tryParse(proCtrl.text) ?? meal['protein'];
              meal['carbs'] = int.tryParse(carbCtrl.text) ?? meal['carbs'];
              meal['fat'] = int.tryParse(fatCtrl.text) ?? meal['fat'];
              onSaved();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecipePickerModal({required Function(Map<String, dynamic>) onSelected}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<Map<String, dynamic>> allRecipes = [];
    try {
      allRecipes = await ApiService.getRecipes();
    } catch (_) {}

    // Lấy profile để lọc an toàn
    final profile = await ApiService.getLocalProfile();
    final prefs = await SharedPreferences.getInstance();
    final rawAllergies = prefs.getStringList('food_allergies') ??
        prefs.getStringList('user_allergies') ??
        (profile?['allergies'] != null ? List<String>.from(profile!['allergies']) : <String>[]);
    final rawMedical = prefs.getStringList('medical_history') ??
        (profile?['medicalHistory'] != null ? List<String>.from(profile!['medicalHistory']) : <String>[]);

    final activeAllergies = rawAllergies.where((a) => !a.toLowerCase().contains('không có')).toList();
    final activeMedical = rawMedical.where((m) => !m.toLowerCase().contains('không có')).toList();

    final safeCurated = NutriGymChatService.getSafeCuratedRecipes(
      activeAllergies: activeAllergies,
      activeMedical: activeMedical,
    );

    final combined = [...allRecipes, ...safeCurated];
    final searchCtrl = TextEditingController();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2420) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (pickerCtx) => StatefulBuilder(
        builder: (pickerCtx, setPickerState) {
          final query = searchCtrl.text.toLowerCase().trim();
          final displayList = query.isEmpty
              ? combined
              : combined.where((r) {
                  final t = (r['title'] ?? r['name'] ?? '').toString().toLowerCase();
                  return t.contains(query);
                }).toList();

          return SafeArea(
            child: Container(
              height: MediaQuery.of(pickerCtx).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn món ăn thay thế',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(pickerCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tìm món (ức gà, cá hồi, yến mạch, tôm...)',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    onChanged: (_) => setPickerState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: displayList.isEmpty
                        ? const Center(child: Text('Không tìm thấy món ăn phù hợp'))
                        : ListView.builder(
                            itemCount: displayList.length,
                            itemBuilder: (_, idx) {
                              final r = displayList[idx];
                              final title = (r['title'] ?? r['name'] ?? '').toString();
                              final kcal = (r['kcal'] as num?)?.toInt() ?? 400;
                              final pro = (r['protein'] as num?)?.toInt() ?? 30;
                              final carb = (r['carbs'] as num?)?.toInt() ?? 30;
                              final fat = (r['fat'] as num?)?.toInt() ?? 10;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  subtitle: Text('$kcal kcal • ${pro}g đạm • ${carb}g carb • ${fat}g béo', style: const TextStyle(fontSize: 12)),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                  onTap: () {
                                    onSelected(r);
                                    Navigator.pop(pickerCtx);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Khối Kế hoạch Thực đơn Thông minh (Meal Plan Proposal Card)
  Widget _buildMealPlanProposalCard(ChatMessage msg) {
    final data = msg.mealPlanData!;
    final planTypeName = data['planTypeName']?.toString() ?? 'Kế hoạch Thực Đơn';
    final targetGoal = data['targetGoal']?.toString() ?? 'Tăng cơ giảm mỡ';
    final avgDailyKcal = data['avgDailyKcal'] ?? 0;
    final avgDailyPro = data['avgDailyPro'] ?? 0;
    final avgDailyCarbs = data['avgDailyCarbs'] ?? 0;
    final avgDailyFat = data['avgDailyFat'] ?? 0;
    final bool hasThresholdWarning = data['hasThresholdWarning'] == true;
    final String thresholdWarning = data['thresholdWarning']?.toString() ?? '';
    final String allergiesNote = data['allergiesNote']?.toString() ?? '';
    final List days = (data['days'] as List?) ?? [];
    final List shoppingList = (data['shoppingList'] as List?) ?? [];
    final bool isConfirmed = data['isConfirmedAndSaved'] == true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasThresholdWarning ? Colors.orangeAccent.withValues(alpha: 0.6) : AppColors.outlineVariant,
          width: hasThresholdWarning ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planTypeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.onSurface),
                      ),
                      Text(
                        'Mục tiêu: $targetGoal',
                        style: TextStyle(fontSize: 11.5, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConfirmed ? AppColors.green.withValues(alpha: 0.15) : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConfirmed ? '✅ Đã lưu lịch' : '⏳ Chờ duyệt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isConfirmed ? AppColors.green : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khối thông số Macros trung bình/ngày
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge('Calo TB', '$avgDailyKcal', 'kcal', AppColors.fire),
                      _buildMacroBadge('Protein', '$avgDailyPro', 'g', AppColors.primary),
                      _buildMacroBadge('Carbs', '$avgDailyCarbs', 'g', const Color(0xFF2563EB)),
                      _buildMacroBadge('Fat', '$avgDailyFat', 'g', const Color(0xFFD97706)),
                    ],
                  ),
                ),

                if (data['isCarbCycling'] == true) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.fitness_center_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lên kế hoạch thực đơn tuần (Carb Cycling): Tự động tăng lượng tinh bột vào ngày tập nặng (Chân/Lưng), giữ mức vừa phải ngày tập nhẹ và hạ thấp Carb vào ngày nghỉ ngơi.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.onSurface,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cảnh báo ngưỡng Calo nếu lệch quá nhiều (>250 kcal)
                if (hasThresholdWarning && thresholdWarning.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            thresholdWarning,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309), height: 1.35, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Danh sách biện pháp bảo vệ sức khỏe & dị ứng (Safeguards)
                if (data['safeguards'] is List && (data['safeguards'] as List).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.health_and_safety_rounded, color: Color(0xFF0284C7), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Đã cá nhân hóa theo mục tiêu & sức khỏe:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ...(data['safeguards'] as List).map((s) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            s.toString(),
                            style: const TextStyle(fontSize: 11, color: AppColors.onSurface, height: 1.3),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                // Ghi chú đồ kiêng / đồ thích (nếu có)
                if (allergiesNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🛡️ Sở thích & Kiêng cữ: $allergiesNote',
                    style: TextStyle(fontSize: 11.5, color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic),
                  ),
                ],

                const SizedBox(height: 12),
                const Text(
                  '📅 Lịch trình các ngày:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),

                // Lịch các ngày
                ...days.asMap().entries.map((entry) {
                  final dayIdx = entry.key;
                  final dayMap = entry.value as Map<String, dynamic>;
                  final dayName = dayMap['dayName']?.toString() ?? '';
                  final date = dayMap['date']?.toString() ?? '';
                  final isMealPrep = dayMap['isMealPrep'] == true;
                  final cookType = dayMap['cookType']?.toString() ?? '';
                  final defrostAlert = dayMap['defrostAlert']?.toString();
                  final meals = (dayMap['meals'] as List?) ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$dayName ($date)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isMealPrep
                                            ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                            : AppColors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cookType,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isMealPrep ? const Color(0xFF0097A7) : AppColors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isConfirmed) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primary),
                                tooltip: 'Chỉnh sửa ngày này / Đổi món',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _openMealPlanEditor(msg, initialDayIdx: dayIdx),
                              ),
                            ],
                          ],
                        ),
                        if (defrostAlert != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.ac_unit_rounded, size: 14, color: Color(0xFF0097A7)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  defrostAlert,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF0097A7), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Danh sách món trong ngày
                        ...meals.map((m) {
                          final meal = m as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${meal['type']}: ',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                                ),
                                Expanded(
                                  child: Text(
                                    meal['name']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${meal['kcal']} kcal',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.fire),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),

                // Danh sách nguyên liệu cần chuẩn bị & Bù đắp lượng thiếu
                if (shoppingList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Danh sách đi chợ & bù đắp thiếu hụt',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${shoppingList.length}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'So sánh tự động với nguyên liệu có sẵn trong tủ lạnh:',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 6),
                              ...shoppingList.map((item) {
                                final s = item as Map<String, dynamic>;
                                final name = s['name']?.toString() ?? '';
                                final needed = s['needed'] ?? 0;
                                final inFridge = s['inFridge'] ?? 0;
                                final toBuy = s['toBuy'] ?? 0;
                                final icon = s['icon']?.toString() ?? '🥗';
                                final isShortfall = s['isShortfall'] == true;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isShortfall ? Colors.orangeAccent.withValues(alpha: 0.5) : AppColors.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildFoodIconWidget(icon, size: 22),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                            Text(
                                              'Cần: ${needed}g • Có: ${inFridge}g',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isShortfall)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Cần mua: ${toBuy}g',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Đã đủ sẵn',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.green),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B14F),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.delivery_dining_rounded, size: 20),
                                  label: const Text(
                                    '🛵 Mua nguyên liệu trên GrabMart (Giao 30p)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                  onPressed: () async {
                                    final shortfallItems = shoppingList.where((item) {
                                      if (item is Map) {
                                        return (item['isShortfall'] == true) || ((item['toBuy'] ?? 0) > 0);
                                      }
                                      return false;
                                    }).toList();
                                    final itemsToUse = shortfallItems.isNotEmpty ? shortfallItems : shoppingList;
                                    final listString = itemsToUse.map((it) {
                                      final m = it as Map;
                                      return '• ${m['name']}: ${m['toBuy'] ?? m['needed'] ?? 100}g';
                                    }).join('\n');
                                    final clipboardText = '🛒 DANH SÁCH NGUYÊN LIỆU ĐI CHỢ EATGYM:\n$listString';
                                    await Clipboard.setData(ClipboardData(text: clipboardText));

                                    final firstItem = itemsToUse.isNotEmpty ? ((itemsToUse.first as Map)['name'] ?? 'thuc pham') : 'thuc pham';
                                    final encodedQuery = Uri.encodeComponent(firstItem.toString());
                                    final grabSchemeUri = Uri.parse('grab://open?screenType=GRABMART&query=$encodedQuery');
                                    final grabWebUri = Uri.parse('https://food.grab.com/vn/vi/mart/');

                                    bool launched = false;
                                    try {
                                      if (await canLaunchUrl(grabSchemeUri)) {
                                        launched = await launchUrl(grabSchemeUri, mode: LaunchMode.externalApplication);
                                      }
                                    } catch (_) {}

                                    if (!launched) {
                                      try {
                                        await launchUrl(grabWebUri, mode: LaunchMode.externalApplication);
                                        launched = true;
                                      } catch (_) {}
                                    }

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('🛵 Đã mở GrabMart! Đã copy ${itemsToUse.length} món vào bộ nhớ tạm.'),
                                          backgroundColor: const Color(0xFF00B14F),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Hành động xác nhận / điều chỉnh
                if (!isConfirmed) ...[
                  // Nút Chỉnh sửa thực đơn & Đổi món
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(color: Color(0xFF7C3AED), width: 1.3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      label: const Text(
                        '✏️ CHỈNH SỬA THỰC ĐƠN / ĐỔI MÓN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      onPressed: () => _openMealPlanEditor(msg),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nút Xác nhận và lưu vào lịch
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'XÁC NHẬN & LƯU VÀO LỊCH',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      onPressed: () => _saveConfirmedMealPlan(msg),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            side: BorderSide(color: AppColors.outline),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 16),
                          label: const Text('Tùy chọn lại', style: TextStyle(fontSize: 11.5)),
                          onPressed: () => _showMealPrepOptionsSheet(targetMealPlanMsg: msg),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: const Text('Mở Trang Lịch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MealPrepScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (data['isCarbCycling'] == true) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text(
                          'Xem chi tiết & Tùy chỉnh lịch tuần (Carb Cycling)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WeeklyMealPlannerScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.green, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Thực đơn đã được đồng bộ vào Trang Lịch',
                            style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MealPrepScreen()),
                            );
                          },
                          child: const Text(
                            'Xem Lịch →',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Khối nguyên liệu bóc tách được với các nút bấm xác nhận
  Widget _buildIngredientsActionCard(ChatMessage msg) {
    final ingredients = msg.ingredients!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Danh sách các nguyên liệu
          ...ingredients.map((ing) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  buildFoodIconWidget(ing.icon, size: 18, name: ing.name),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ing.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${ing.weight}g (${ing.totalCalories} kcal)',
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          if (msg.isActionDone)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.green, size: 16),
                  SizedBox(width: 6),
                  Text('Đã xử lý xong nguyên liệu', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('Thêm vào tab Nguyên liệu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () => _addIngredientsToScanSession(msg),
              ),
            ),
        ],
      ),
    );
  }

  // Khối danh sách món ăn gợi ý
  Widget _buildRecipeSuggestionsList(List<Map<String, dynamic>> recipes) {
    return Column(
      children: recipes.map((recipe) {
        return InkWell(
          onTap: () => _showRecipeDetailsDialog(recipe),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(recipe['icon']?.toString() ?? '🍲', style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['title']?.toString() ?? 'Món ăn',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${recipe['kcal'] ?? 0} kcal • ${recipe['protein'] ?? 0}g đạm • ${recipe['time'] ?? 15}p',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.smart_toy, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  'NutriGym AI đang suy nghĩ...',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
