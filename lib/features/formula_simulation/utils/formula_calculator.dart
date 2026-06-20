class FormulaCalculator {
  const FormulaCalculator._();

  static double calculate(String expression, Map<String, double> values) {
    double val(String key) => values[key] ?? 0;
    return switch (expression.replaceAll(' ', '')) {
      'v*t' => val('v') * val('t'),
      's/t' => val('t') == 0 ? 0 : val('s') / val('t'),
      'F/S' => val('S') == 0 ? 0 : val('F') / val('S'),
      'U/R' => val('R') == 0 ? 0 : val('U') / val('R'),
      'U*I' => val('U') * val('I'),
      'd*V' => val('d') * val('V'),
      _ => 0,
    };
  }
}
