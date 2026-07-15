import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../shared/models/x_models.dart';
import '../utils/formula_calculator.dart';

/// Renders a `Simulations` config (see `docs/API_CONTRACT.md`) as an
/// interactive "phòng thí nghiệm bỏ túi": the LaTeX formula, one slider per
/// variable, and a real-time computed result. Calculation logic lives in
/// [FormulaCalculator] so it is not duplicated here.
class FormulaSimulationWidget extends StatefulWidget {
  const FormulaSimulationWidget({super.key, required this.config});
  final FormulaSimulationConfig config;

  @override
  State<FormulaSimulationWidget> createState() =>
      _FormulaSimulationWidgetState();
}

class _FormulaSimulationWidgetState extends State<FormulaSimulationWidget> {
  late final Map<String, double> values = {
    for (final variable in widget.config.variables)
      variable.symbol: variable.defaultValue,
  };

  double _calculate() =>
      FormulaCalculator.calculate(widget.config.result.expression, values);

  @override
  Widget build(BuildContext context) {
    final result = _calculate();
    final isSupported = FormulaCalculator.isSupported(
      widget.config.result.expression,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science_rounded, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.config.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Math.tex(
                widget.config.formula,
                textStyle: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(height: 16),
            for (final variable in widget.config.variables) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${variable.label} (${variable.symbol})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${values[variable.symbol]!.toStringAsFixed(2)} ${variable.unit}',
                  ),
                ],
              ),
              Slider(
                min: variable.min,
                max: variable.max,
                value: values[variable.symbol]!,
                onChanged: (value) =>
                    setState(() => values[variable.symbol] = value),
              ),
            ],
            if (!isSupported)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Công thức này chưa được hỗ trợ tính real-time. Kết quả '
                  'bên dưới tạm thời là 0 — báo TV3 để bổ sung expression '
                  'mới vào FormulaCalculator.',
                  style: TextStyle(color: Color(0xFFC0392B), fontSize: 13),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${widget.config.result.label}: ${result.toStringAsFixed(2)} ${widget.config.result.unit}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
