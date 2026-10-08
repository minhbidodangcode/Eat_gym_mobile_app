import 'package:flutter/material.dart';
import '../services/nutrition_advanced_api_service.dart';

class MealPrepScreen extends StatefulWidget {
  @override
  _MealPrepScreenState createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  final _formKey = GlobalKey<FormState>();
  String _batchName = '';
  int _servings = 1;
  bool _isLoading = false;

  void _submitBatch() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      // Gọi API tạo mẻ Meal Prep (giả lập dữ liệu item)
      final result = await NutritionAdvancedApiService.createMealPrepBatch(
        name: _batchName,
        servings: _servings,
        items: [
          {
            // ID giả định của hệ số chuyển đổi (lấy từ getYieldFactors)
            'yieldFactorId': 'c392fdb2-1a41-4c6e-827d-94c3dc09d27f', 
            'inputWeightG': 1000, 
            'inputState': 'raw'
          }
        ],
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo mẻ nấu thành công! ID: ${result['batch']['id']}')),
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
      appBar: AppBar(title: Text('Meal Prep Sống - Chín')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nấu 1 mẻ lớn, chia nhiều hộp',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Tên mẻ (VD: Gà luộc ăn cả tuần)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                onSaved: (v) => _batchName = v!,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Số hộp / Khẩu phần (Servings)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v!) == null ? 'Nhập số hợp lệ' : null,
                onSaved: (v) => _servings = int.parse(v!),
              ),
              SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text('Nguyên liệu: Ức gà sống'),
                  subtitle: Text('Khối lượng: 1000g - Phương pháp: Luộc'),
                  trailing: Icon(Icons.fastfood),
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16)),
                  onPressed: _isLoading ? null : _submitBatch,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Lưu mẻ Meal Prep', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
