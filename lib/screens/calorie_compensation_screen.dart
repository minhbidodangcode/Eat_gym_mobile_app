import 'package:flutter/material.dart';
import '../services/nutrition_advanced_api_service.dart';

class CalorieCompensationScreen extends StatefulWidget {
  @override
  _CalorieCompensationScreenState createState() => _CalorieCompensationScreenState();
}

class _CalorieCompensationScreenState extends State<CalorieCompensationScreen> {
  bool _isLoading = false;

  void _triggerCompensation(String deviationId, int days) async {
    setState(() => _isLoading = true);
    try {
      final result = await NutritionAdvancedApiService.allocateCompensation(
        deviationId: deviationId,
        horizonDays: days,
        minKcalPerMeal: 300, // Chừa lại tối thiểu 300 calo mỗi bữa
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bù trừ thành công: ${result['compensation']['status']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bù trừ Calo (Compensation)')),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(
              'Lịch sử ăn lố (Deviations)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ngày: 05/10/2026', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Mục tiêu: 2000 Kcal'),
                    Text('Thực tế: 2600 Kcal', style: TextStyle(color: Colors.red)),
                    Text('Vượt mức: +600 Kcal', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _triggerCompensation('dummy_deviation_id', 1),
                          child: Text('Trừ vào ngày mai'),
                        ),
                        OutlinedButton(
                          onPressed: () => _triggerCompensation('dummy_deviation_id', 2),
                          child: Text('Chia đều 2 ngày'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
