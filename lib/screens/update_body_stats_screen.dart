import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UpdateBodyStatsScreen extends StatefulWidget {
  const UpdateBodyStatsScreen({super.key});

  @override
  State<UpdateBodyStatsScreen> createState() => _UpdateBodyStatsScreenState();
}

class _UpdateBodyStatsScreenState extends State<UpdateBodyStatsScreen> {
  int selectedTabIndex = 0;
  double weight = 72.4;
  double bodyFat = 17.8;
  Map<String, int> measurements = {
    'Vòng ngực': 96,
    'Vòng eo': 78,
    'Vòng mông': 94,
    'Bắp tay': 32,
    'Đùi': 54,
  };
  String notes = '';
  String measurementSource = 'Cân thông minh';

  final TextEditingController _notesController = TextEditingController();
  late final Map<String, TextEditingController> _measurementControllers;

  final List<String> _tabLabels = ['Cân nặng', '% Mỡ', 'Số đo'];
  final List<String> _sourceOptions = [
    'Cân thông minh',
    'Đo tay',
    'DEXA Scan',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _measurementControllers = {
      for (final entry in measurements.entries)
        entry.key: TextEditingController(text: entry.value.toString()),
    };
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _measurementControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Text(
            '<',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.darkNavy,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Cập nhật vóc dáng',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            _buildTabBar(),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildTabContent(),
              ),
            ),
            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: List.generate(_tabLabels.length, (index) {
          final bool isSelected = selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTabIndex = index;
                });
              },
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == _tabLabels.length - 1 ? 0 : 4,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.darkNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.darkNavy : AppColors.grey.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabLabels[index],
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.darkNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTabIndex) {
      case 0:
        return _buildWeightTab();
      case 1:
        return _buildBodyFatTab();
      case 2:
        return _buildMeasurementsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── TAB 1: Cân nặng ─────────────────────────────────────────────────

  Widget _buildWeightTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeightCard(),
        const SizedBox(height: 16),
        _buildWeightInfoBoxes(),
        const SizedBox(height: 24),
        _buildNotesSection(),
      ],
    );
  }

  Widget _buildWeightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'CÂN NẶNG HÔM NAY',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCircleButton(
                icon: Icons.remove,
                onTap: () {
                  setState(() {
                    weight = double.parse((weight - 0.1).toStringAsFixed(1));
                  });
                },
              ),
              const SizedBox(width: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    weight.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              _buildCircleButton(
                icon: Icons.add,
                onTap: () {
                  setState(() {
                    weight = double.parse((weight + 0.1).toStringAsFixed(1));
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInfoBoxes() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngày đo',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hôm nay, 26/09',
                  style: TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'So với lần trước',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '▼ 0.3 kg',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ghi chú (không bắt buộc)',
          style: TextStyle(
            color: AppColors.darkNavy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            onChanged: (value) {
              setState(() {
                notes = value;
              });
            },
            decoration: const InputDecoration(
              hintText: 'VD: đo sau khi ngủ dậy, chưa ăn sáng...',
              hintStyle: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(
              color: AppColors.darkNavy,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ─── TAB 2: % Mỡ ─────────────────────────────────────────────────────

  Widget _buildBodyFatTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBodyFatCard(),
        const SizedBox(height: 16),
        _buildMeasurementSourceDropdown(),
      ],
    );
  }

  Widget _buildBodyFatCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'TỶ LỆ MỠ CƠ THỂ',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCircleButton(
                icon: Icons.remove,
                onTap: () {
                  setState(() {
                    bodyFat = double.parse((bodyFat - 0.1).toStringAsFixed(1));
                  });
                },
              ),
              const SizedBox(width: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    bodyFat.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              _buildCircleButton(
                icon: Icons.add,
                onTap: () {
                  setState(() {
                    bodyFat = double.parse((bodyFat + 0.1).toStringAsFixed(1));
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementSourceDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nguồn đo',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: measurementSource,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.darkNavy),
              ),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.darkNavy),
            style: const TextStyle(
              color: AppColors.darkNavy,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            items: _sourceOptions.map((source) {
              return DropdownMenuItem<String>(
                value: source,
                child: Text(source),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  measurementSource = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: Số đo ────────────────────────────────────────────────────

  Widget _buildMeasurementsTab() {
    return Column(
      children: measurements.entries.map((entry) {
        return _buildMeasurementRow(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildMeasurementRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkNavy,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Container(
                width: 72,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.darkNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: TextField(
                    controller: _measurementControllers[label],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) {
                        setState(() {
                          measurements[label] = parsed;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'cm',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.darkNavy,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.darkNavy,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            // Handle save
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkNavy,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Lưu thay đổi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
