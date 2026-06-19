import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../shared/models/x_models.dart';

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

  double _calculate() {
    double val(String key) => values[key] ?? 0;
    return switch (widget.config.result.expression.replaceAll(' ', '')) {
      'v*t' => val('v') * val('t'),
      's/t' => val('t') == 0 ? 0 : val('s') / val('t'),
      'F/S' => val('S') == 0 ? 0 : val('F') / val('S'),
      'U/R' => val('R') == 0 ? 0 : val('U') / val('R'),
      'U*I' => val('U') * val('I'),
      'd*V' => val('d') * val('V'),
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final result = _calculate();
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
