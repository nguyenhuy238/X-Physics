import 'package:flutter_test/flutter_test.dart';
import 'package:x_physics/features/formula_simulation/utils/formula_calculator.dart';

void main() {
  group('FormulaCalculator.calculate', () {
    test('v * t (s = v x t)', () {
      expect(
        FormulaCalculator.calculate('v * t', {'v': 5, 't': 10}),
        50,
      );
    });

    test('s / t (v = s / t), division by zero returns 0', () {
      expect(FormulaCalculator.calculate('s / t', {'s': 100, 't': 0}), 0);
      expect(FormulaCalculator.calculate('s / t', {'s': 100, 't': 20}), 5);
    });

    test('ignores missing variables by treating them as 0', () {
      expect(FormulaCalculator.calculate('U * I', {'U': 12}), 0);
    });

    test('unknown expression returns 0 instead of throwing', () {
      expect(
        FormulaCalculator.calculate('A / t', {'A': 10, 't': 2}),
        0,
      );
    });
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

    test('false for an expression not yet wired up', () {
      expect(FormulaCalculator.isSupported('A / t'), isFalse);
    });
  });
}
