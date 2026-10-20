import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_theme.dart';
import '../models/voice_ingredient_result.dart';
import '../services/ai/voice_ingredient_parser.dart';

class VoiceIngredientSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? availableIngredients;
  final Function(List<VoiceIngredientResult> results) onConfirm;

  const VoiceIngredientSheet({
    super.key,
    this.availableIngredients,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    List<Map<String, dynamic>>? availableIngredients,
    required Function(List<VoiceIngredientResult> results) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceIngredientSheet(
        availableIngredients: availableIngredients,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<VoiceIngredientSheet> createState() => _VoiceIngredientSheetState();
}

class _VoiceIngredientSheetState extends State<VoiceIngredientSheet> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _wordsSpoken = '';
  String _errorMessage = '';
  final List<VoiceIngredientResult> _parsedItems = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _textFallbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textFallbackController.dispose();
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
              _processSpokenText();
            }
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _errorMessage = 'Lỗi nhận diện: ${errorNotification.errorMsg}';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
        if (available) {
          _startListening();
        } else {
          setState(() {
            _errorMessage = 'Thiết bị chưa cấp quyền Micro hoặc không hỗ trợ nhận diện giọng nói.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _speechEnabled = false;
          _errorMessage = 'Không thể khởi động micro: $e';
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      return;
    }

    setState(() {
      _isListening = true;
      _errorMessage = '';
      _wordsSpoken = '';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _wordsSpoken = result.recognizedWords;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _errorMessage = 'Không thể nghe: $e';
        });
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _processSpokenText();
    }
  }

  void _processSpokenText([String? customText]) {
    final textToProcess = (customText ?? _wordsSpoken).trim();
    if (textToProcess.isEmpty) return;

    final results = VoiceIngredientParser.parseSpokenText(
      textToProcess,
      availableIngredients: widget.availableIngredients,
    );

    setState(() {
      if (results.isNotEmpty) {
        // Gộp vào danh sách hiện tại
        for (final r in results) {
          final idx = _parsedItems.indexWhere((item) => item.name.toLowerCase() == r.name.toLowerCase());
          if (idx >= 0) {
            _parsedItems[idx].weight += r.weight;
          } else {
            _parsedItems.add(r);
          }
        }
      } else {
        _errorMessage = 'Không nhận diện được tên nguyên liệu trong câu: "$textToProcess"';
      }
    });
  }

  int get _totalCalories {
    return _parsedItems
        .where((i) => i.isSelected)
        .fold(0, (sum, i) => sum + i.totalCalories);
  }

  double get _totalProtein {
    return _parsedItems
        .where((i) => i.isSelected)
        .fold(0.0, (sum, i) => sum + i.totalProtein);
  }

  void _showEditWeightDialog(VoiceIngredientResult item) {
    final ctrl = TextEditingController(text: item.weight.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${item.icon} Chỉnh khối lượng: ${item.name}', style: AppTypography.titleMedium(color: AppColors.onSurface)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Khối lượng (gam)',
            suffixText: 'g',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
            onPressed: () {
              final w = int.tryParse(ctrl.text.trim());
              if (w != null && w > 0) {
                setState(() => item.weight = w);
              }
              Navigator.pop(ctx);
            },
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      height: MediaQuery.of(context).size.height * (isKeyboardOpen ? 0.85 : 0.78),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thêm bằng giọng nói',
                      style: AppTypography.titleMedium(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'VD: "200 gam ức gà, 3 quả trứng gà và nửa ký khoai"',
                      style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Voice Record Button & Status Waveform
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isListening ? AppColors.primary.withValues(alpha: 0.5) : AppColors.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [AppColors.fire, AppColors.primary]
                                  : [AppColors.primary, const Color(0xFF1E88E5)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? AppColors.fire : AppColors.primary).withValues(alpha: 0.35),
                                blurRadius: _isListening ? 18 : 8,
                                spreadRadius: _isListening ? 4 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isListening
                      ? 'Đang lắng nghe... (Chạm để dừng)'
                      : (_wordsSpoken.isNotEmpty ? 'Chạm để nói tiếp câu khác' : 'Chạm vào micro để nói'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isListening ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
                if (_wordsSpoken.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"$_wordsSpoken"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.onSurface),
                    ),
                  ),
                ],
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.fire),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Fallback text input (Bridge to Chatbot)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _textFallbackController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Hoặc gõ câu lệnh (VD: 300g thịt bò...)',
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) {
                      _processSpokenText(val);
                      _textFallbackController.clear();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.send, size: 18),
                onPressed: () {
                  if (_textFallbackController.text.trim().isNotEmpty) {
                    _processSpokenText(_textFallbackController.text.trim());
                    _textFallbackController.clear();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Recognized Items List
          Expanded(
            child: _parsedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fastfood_outlined, size: 40, color: AppColors.outlineVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có nguyên liệu nào được nhận diện',
                          style: AppTypography.bodySmall(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _parsedItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = _parsedItems[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: item.isSelected,
                              activeColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) {
                                setState(() => item.isSelected = val ?? true);
                              },
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(item.icon, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: item.isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.totalCalories} kcal • ${item.totalProtein.round()}g đạm',
                                    style: AppTypography.labelCaption(color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            // Nút chỉnh sửa khối lượng
                            GestureDetector(
                              onTap: () => _showEditWeightDialog(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.outlineVariant),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.weight}g',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit, size: 12, color: AppColors.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.fire, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() => _parsedItems.removeAt(idx));
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 3. Bottom Actions & Summary
          if (_parsedItems.isNotEmpty) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng: $_totalCalories kcal • ${_totalProtein.round()}g Đạm',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${_parsedItems.where((i) => i.isSelected).length} nguyên liệu',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.playlist_add, size: 20),
                label: const Text('Thêm vào danh sách nguyên liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  final selected = _parsedItems.where((i) => i.isSelected).toList();
                  if (selected.isEmpty) return;
                  Navigator.pop(context);
                  widget.onConfirm(selected);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
