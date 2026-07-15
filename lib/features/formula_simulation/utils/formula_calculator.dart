/// Single source of truth for evaluating a `Simulations.expression` (see
/// `docs/API_CONTRACT.md` — `GET /api/lessons/{id}/simulations`). Used by
/// `FormulaSimulationWidget` so the calculation logic exists in exactly one
/// place instead of being duplicated inline in the widget.
class FormulaCalculator {
  const FormulaCalculator._();

  static const _supportedExpressions = {
    'v*t',
    's/t',
    'F/S',
    'U/R',
    'U*I',
    'd*V',
  };

  /// Whether [expression] is one of the hard-coded formulas below. If an
  /// Admin adds a new simulation with a different expression, this returns
  /// `false` so the widget can show a warning instead of silently
  /// displaying `0`.
  static bool isSupported(String expression) =>
      _supportedExpressions.contains(_normalize(expression));

  static double calculate(String expression, Map<String, double> values) {
    double val(String key) => values[key] ?? 0;
    return switch (_normalize(expression)) {
      'v*t' => val('v') * val('t'),
      's/t' => val('t') == 0 ? 0 : val('s') / val('t'),
      'F/S' => val('S') == 0 ? 0 : val('F') / val('S'),
      'U/R' => val('R') == 0 ? 0 : val('U') / val('R'),
      'U*I' => val('U') * val('I'),
      'd*V' => val('d') * val('V'),
      _ => 0,
    };
  }

  static String _normalize(String expression) =>
      expression.replaceAll(' ', '');
}
