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

    test('normalizes multiplication and division glyphs', () {
      expect(FormulaCalculator.calculate('U × I', {'U': 12, 'I': 2}), 24);
      expect(FormulaCalculator.calculate('s ÷ t', {'s': 100, 't': 20}), 5);
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

    test('supports powers/exponents ^', () {
      expect(FormulaCalculator.calculate('v^2', {'v': 5}), 25);
      expect(
        FormulaCalculator.calculate('0.5 * m * v^2', {'m': 2, 'v': 4}),
        16,
      );
      expect(FormulaCalculator.calculate('(a + b)^2', {'a': 3, 'b': 2}), 25);
    });

    test('supports square root sqrt and √', () {
      expect(FormulaCalculator.calculate('sqrt(16)', {}), 4);
      expect(
        FormulaCalculator.calculate('sqrt(2 * g * h)', {'g': 9.8, 'h': 5}),
        closeTo(9.89949, 0.00001),
      );
      expect(FormulaCalculator.calculate('√(a^2 + b^2)', {'a': 3, 'b': 4}), 5);
    });

    test('supports cube root cbrt and abs', () {
      expect(FormulaCalculator.calculate('cbrt(27)', {}), 3);
      expect(FormulaCalculator.calculate('abs(-15.5)', {}), 15.5);
    });

    test('supports pow, trig functions sin_deg, cos_deg, and pi', () {
      expect(FormulaCalculator.calculate('pow(2, 3)', {}), 8);
      expect(
        FormulaCalculator.calculate('sin_deg(30)', {}),
        closeTo(0.5, 0.0001),
      );
      expect(
        FormulaCalculator.calculate('cos_deg(60)', {}),
        closeTo(0.5, 0.0001),
      );
      expect(
        FormulaCalculator.calculate('2 * pi * r', {'r': 10}),
        closeTo(62.83185, 0.001),
      );
    });
  });

  group('FormulaCalculator.isSupported', () {
    test('true for the 6 seeded simulation expressions', () {
      for (final expression in ['v*t', 's/t', 'F/S', 'U/R', 'U*I', 'd*V']) {
        expect(FormulaCalculator.isSupported(expression), isTrue);
      }
    });

    test('true for complex physics formulas with roots and exponents', () {
      expect(FormulaCalculator.isSupported('0.5 * m * v^2'), isTrue);
      expect(FormulaCalculator.isSupported('sqrt(2 * g * h)'), isTrue);
      expect(FormulaCalculator.isSupported('2 * pi * sqrt(l / g)'), isTrue);
      expect(
        FormulaCalculator.isSupported(
          'sqrt(F1^2 + F2^2 + 2*F1*F2*cos_deg(alpha))',
        ),
        isTrue,
      );
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
      expect(FormulaCalculator.isSupported('sqrt('), isFalse);
    });
  });

  group('FormulaCalculator.tryCalculate and references', () {
    test('returns an explicit error for division by zero', () {
      final result = FormulaCalculator.tryCalculate('U / R', {'U': 12, 'R': 0});

      expect(result.isValid, isFalse);
      expect(result.error, contains('Division by zero'));
    });

    test('returns error for negative square root', () {
      final result = FormulaCalculator.tryCalculate('sqrt(-9)', {});

      expect(result.isValid, isFalse);
      expect(result.error, contains('số âm'));
    });

    test('extracts referenced variable symbols excluding math keywords', () {
      expect(
        FormulaCalculator.referencedSymbols('(U + R) / R'),
        equals({'U', 'R'}),
      );
      expect(
        FormulaCalculator.referencedSymbols('2 * pi * sqrt(l / g)'),
        equals({'l', 'g'}),
      );
      expect(
        FormulaCalculator.referencedSymbols('0.5 * m * v^2'),
        equals({'m', 'v'}),
      );
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

    test('serializes simulation for student/offline cache shape', () {
      final config = FormulaSimulationConfig(
        title: 'Mô phỏng vận tốc',
        formula: r'v = \frac{s}{t}',
        variables: const [
          FormulaVariable(
            symbol: 's',
            label: 'Quãng đường',
            unit: 'm',
            min: 0,
            max: 100,
            step: 1,
            defaultValue: 20,
          ),
          FormulaVariable(
            symbol: 't',
            label: 'Thời gian',
            unit: 's',
            min: 1,
            max: 20,
            step: 1,
            defaultValue: 4,
          ),
        ],
        result: const FormulaResult(
          symbol: 'v',
          label: 'Vận tốc',
          unit: 'm/s',
          expression: 's / t',
          decimalPlaces: 2,
        ),
      );

      expect(config.toJson()['result']['expression'], 's / t');
      expect(config.toJson()['variables'].first['default'], 20);
    });
  });
}
