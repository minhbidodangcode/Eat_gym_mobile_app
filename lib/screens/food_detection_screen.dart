import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/yolo_api_service.dart';

class FoodDetectionScreen extends StatefulWidget {
  @override
  _FoodDetectionScreenState createState() => _FoodDetectionScreenState();
}

class _FoodDetectionScreenState extends State<FoodDetectionScreen> {
  File? _imageFile;
  bool _isLoading = false;
  List<dynamic> _detections = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _detections = []; // Reset kết quả cũ
        });
        _detectFood();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
    }
  }

  Future<void> _detectFood() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await YoloApiService.detectFood(_imageFile!);
      setState(() {
        _detections = result['detections'];
      });
      
      if (_detections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tìm thấy món ăn nào trong ảnh.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Nhận Diện Món Ăn (YOLOv8)')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            // Hiển thị ảnh
            if (_imageFile != null)
              Container(
                height: 300,
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 300,
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text('Chưa có ảnh nào được chọn', style: TextStyle(color: Colors.grey.shade600))),
              ),

            SizedBox(height: 20),

            // Các nút chọn ảnh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Chụp ảnh'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text('Thư viện'),
                ),
              ],
            ),

            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),

            // Kết quả nhận diện
            if (_detections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Kết quả nhận diện:', style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _detections.length,
                itemBuilder: (context, index) {
                  final item = _detections[index];
                  final String name = item['class_name'];
                  final double conf = item['confidence'] * 100;
                  
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(Icons.fastfood, size: 20)),
                      title: Text(name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('${conf.toStringAsFixed(1)}%'),
                    ),
                  );
                },
              )
            ]
          ],
        ),
      ),
    );
  }
}
