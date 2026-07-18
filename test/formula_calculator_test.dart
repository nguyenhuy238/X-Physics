import 'package:flutter_test/flutter_test.dart';
import 'package:x_physics/features/formula_simulation/utils/formula_calculator.dart';
import 'package:x_physics/shared/models/x_models.dart';

void main() {
  group('FormulaCalculator.calculate', () {
    test('v * t (s = v x t)', () {
      expect(FormulaCalculator.calculate('v * t', {'v': 5, 't': 10}), 50);
    });

    test('s / t (v = s / t), division by zero returns 0', () {
      expect(FormulaCalculator.calculate('s / t', {'s': 100, 't': 0}), 0);
      expect(FormulaCalculator.calculate('s / t', {'s': 100, 't': 20}), 5);
    });

    test('ignores missing variables by treating them as 0', () {
      expect(FormulaCalculator.calculate('U * I', {'U': 12}), 0);
    });

    test('unknown expression returns 0 instead of throwing', () {
      expect(FormulaCalculator.calculate('A / t', {'A': 10}), 0);
    });

    test(
      'supports addition, subtraction, multiplication, division and parentheses',
      () {
        expect(
          FormulaCalculator.calculate('(a + b) / c - d * 2', {
            'a': 10,
            'b': 5,
            'c': 3,
            'd': 1,
          }),
          3,
        );
      },
    );
  });

  group('FormulaCalculator.isSupported', () {
    test('true for the 6 seeded simulation expressions', () {
      for (final expression in ['v*t', 's/t', 'F/S', 'U/R', 'U*I', 'd*V']) {
        expect(FormulaCalculator.isSupported(expression), isTrue);
      }
    });

    test('true regardless of spacing', () {
      expect(FormulaCalculator.isSupported('v * t'), isTrue);
    });

    test('true for any parseable generic expression', () {
      expect(FormulaCalculator.isSupported('A / t'), isTrue);
      expect(FormulaCalculator.isSupported('(a + b) / c'), isTrue);
    });

    test('false for invalid syntax', () {
      expect(FormulaCalculator.isSupported('A /'), isFalse);
    });
  });

  group('FormulaSimulationConfig.fromJson', () {
    test('parses API config object shape', () {
      final config = FormulaSimulationConfig.fromJson({
        'title': 'Mô phỏng I = U / R',
        'formula': r'I = \frac{U}{R}',
        'expression': 'U / R',
        'config': {
          'variables': [
            {
              'symbol': 'U',
              'label': 'Hiệu điện thế',
              'unit': 'V',
              'min': 0,
              'max': 220,
              'step': 1,
              'default': 12,
            },
            {
              'symbol': 'R',
              'label': 'Điện trở',
              'unit': 'ohm',
              'min': 1,
              'max': 100,
              'step': 1,
              'default': 4,
            },
          ],
          'result': {
            'symbol': 'I',
            'label': 'Cường độ dòng điện',
            'unit': 'A',
            'expression': 'U / R',
            'decimalPlaces': 2,
          },
        },
      });

      expect(config.variables, hasLength(2));
      expect(config.variables.first.step, 1);
      expect(config.result.expression, 'U / R');
      expect(config.result.decimalPlaces, 2);
    });
  });
}
