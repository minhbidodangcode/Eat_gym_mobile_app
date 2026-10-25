
import 'lib/services/ai/ingredient_normalizer.dart';

void main() {
  final list = [
    'CocaCola',
    'Bánh phồng tôm',
    'Xoài cát chín',
    'Ba khía muối',
    'Bò',
    'Thịt bò',
    'Thịt thăn bò',
    'Gan bò',
    'Vịt',
    'Thịt vịt',
    'Gan vịt',
    'Trứng gà',
    'Trứng gà tươi',
    'Trứng vịt',
    'Trứng vịt lộn',
    'Xúc xích',
    'Cải bó xôi',
    'Cải bó xôi (Rau chân vịt)',
    'Ớt chuông 3 màu',
    'Ớt chuông'
  ];

  for (final item in list) {
    final details = IngredientNormalizer.getIngredientDetails(item);
    print('\ => icon: ');
  }
}
