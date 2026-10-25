import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_theme.dart';
import '../models/chat_message.dart';
import '../services/ai/nutrigym_chat_service.dart';
import '../main.dart'; // Để truy cập CameraScanContent.sessionIngredients

class NutriGymChatbotScreen extends StatefulWidget {
  const NutriGymChatbotScreen({super.key});

  @override
  State<NutriGymChatbotScreen> createState() => _NutriGymChatbotScreenState();
}

class _NutriGymChatbotScreenState extends State<NutriGymChatbotScreen> with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _liveTranscript = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _quickPrompts = [
    '🎙️ Thêm 300g ức gà và 3 quả trứng',
    '🍲 Gợi ý món ăn từ nguyên liệu đã chọn',
    '💪 Cần nạp bao nhiêu protein để tăng cơ?',
    '⚡ Bữa ăn trước khi tập gym nên ăn gì?',
    '🍗 Thực phẩm nào giàu đạm nhất?',
    '🧪 Hướng dẫn uống Creatine',
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
    _addInitialBotGreeting();
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
        'và giải đáp mọi thắc mắc về dinh dưỡng thể hình. Hôm nay bạn cần hỗ trợ gì?'
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage.user(query));
      _isTyping = true;
    });
    _scrollToBottom();

    // Gọi AI Service xử lý tin nhắn kèm danh sách nguyên liệu hiện có trong session
    final botResponse = await NutriGymChatService.processMessage(
      query,
      availableIngredients: CameraScanContent.sessionIngredients,
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
          _scrollController.position.maxScrollExtent + 80,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2563EB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NutriGym AI',
                  style: AppTypography.bodyMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
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
                      'Trực tuyến • Trợ lý Dinh Dưỡng',
                      style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: () {
              setState(() {
                _messages.clear();
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
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  final msg = _messages[index];
                  return _buildMessageItem(msg);
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
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final prompt = _quickPrompts[idx];
                  return InkWell(
                    onTap: () => _sendMessage(prompt),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Center(
                        child: Text(
                          prompt,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // 3. Thanh nhập liệu (Text Input + Microphone Button)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.outlineVariant)),
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
                          color: _isListening ? AppColors.fire : AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
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
                        hintText: 'Hỏi dinh dưỡng hoặc nói nguyên liệu...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
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
                    icon: const Icon(Icons.arrow_upward, size: 20),
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

  Widget _buildMessageItem(ChatMessage msg) {
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
      margin: const EdgeInsets.only(bottom: 16, right: 32),
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
              ],
            ),
          ),
        ],
      ),
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
