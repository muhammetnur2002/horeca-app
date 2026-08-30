import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/core/money.dart';

void main() {
  group('Money.parse', () {
    test('понимает точку как разделитель', () {
      expect(Money.parse('1.5'), 1.5);
    });

    test('понимает запятую — раньше "1,5" превращалось в 0', () {
      expect(Money.parse('1,5'), 1.5);
      expect(Money.parse('12345,67'), 12345.67);
    });

    test('игнорирует пробелы внутри числа', () {
      expect(Money.parse('12 345,50'), 12345.5);
    });

    test('пустое и мусорное значение дают ноль', () {
      expect(Money.parse(''), 0);
      expect(Money.parse(null), 0);
      expect(Money.parse('абв'), 0);
    });

    test('округляет до сотых по десятичным знакам строки', () {
      // 1.005 в double хранится как 1.00499..., поэтому округление через
      // (v * 100).round() дало бы 1.00. Разбор идёт по самой строке.
      expect(Money.parse('1.005'), 1.01);
      expect(Money.parse('1.004'), 1.0);
      expect(Money.parse('0.125'), 0.13);
      expect(Money.parse('-1.005'), -1.01);
      expect(Money.parse('1,005'), 1.01);
    });

    test('целые числа и число без целой части', () {
      expect(Money.parse('100'), 100);
      expect(Money.parse('.5'), 0.5);
      expect(Money.parse('-250'), -250);
    });
  });

  group('Money.sum', () {
    test('не накапливает ошибку double', () {
      expect(Money.sum([0.1, 0.2]), 0.3);
      expect(Money.sum([0.1, 0.2, 0.3]), 0.6);
    });

    test('пустой список даёт ноль', () {
      expect(Money.sum(const []), 0);
    });
  });

  group('Money.format', () {
    test('целые суммы без дробной части', () {
      expect(Money.format(1000), '1 000');
      expect(Money.format(1234567), '1 234 567');
    });

    test('дробные суммы с запятой', () {
      expect(Money.format(1234.5), '1 234,50');
    });

    test('отрицательные суммы', () {
      expect(Money.format(-1500), '-1 500');
    });

    test('ноль', () {
      expect(Money.format(0), '0');
    });
  });
}
