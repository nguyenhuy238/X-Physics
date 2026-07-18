import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../core/theme/app_colors.dart';
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
      variable.symbol: _safeDefaultValue(variable),
  };

  double _calculate() =>
      FormulaCalculator.calculate(widget.config.result.expression, values);

  int? _divisionsFor(FormulaVariable variable) {
    if (variable.step <= 0 || variable.max <= variable.min) return null;
    final divisions = ((variable.max - variable.min) / variable.step).round();
    return divisions > 0 ? divisions : null;
  }

  double _safeDefaultValue(FormulaVariable variable) {
    if (variable.max <= variable.min) return variable.min;
    return variable.defaultValue.clamp(variable.min, variable.max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 420;
    final decimalPlaces = widget.config.result.decimalPlaces.clamp(0, 6);
    final result = _calculate();
    final isSupported = FormulaCalculator.isSupported(
      widget.config.result.expression,
    );
    final hasValidVariables = widget.config.variables.every(
      (variable) => variable.max > variable.min,
    );
    final canSimulate =
        isSupported &&
        hasValidVariables &&
        widget.config.variables.isNotEmpty &&
        widget.config.result.expression.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isNarrow ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: AppColors.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.config.title.isEmpty
                        ? 'Phòng thí nghiệm bỏ túi'
                        : widget.config.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: isNarrow ? 20 : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: widget.config.formula.trim().isEmpty
                      ? const Text(
                          'Chưa có công thức',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Math.tex(
                          widget.config.formula,
                          textStyle: const TextStyle(
                            fontSize: 26,
                            color: AppColors.primary,
                          ),
                          onErrorFallback: (_) => Text(
                            widget.config.formula,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final variable in widget.config.variables) ...[
              _VariableHeader(
                variable: variable,
                valueText:
                    '${values[variable.symbol]!.toStringAsFixed(decimalPlaces)} ${variable.unit}',
              ),
              if (variable.max > variable.min) ...[
                Slider(
                  min: variable.min,
                  max: variable.max,
                  divisions: _divisionsFor(variable),
                  value: values[variable.symbol]!,
                  onChanged: (value) =>
                      setState(() => values[variable.symbol] = value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        variable.min.toStringAsFixed(decimalPlaces),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        '${variable.max.toStringAsFixed(decimalPlaces)} ${variable.unit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'Khoảng giá trị của biến này chưa hợp lệ.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 8),
            ],
            if (!canSimulate)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: .18),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.danger,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cấu hình mô phỏng chưa hợp lệ hoặc còn thiếu biến. Kết quả tạm thời là 0.',
                        style: TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: .42),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.config.result.label.isEmpty
                        ? 'Kết quả'
                        : widget.config.result.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.toStringAsFixed(decimalPlaces)} ${widget.config.result.unit}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isNarrow ? 22 : 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.config.result.expression.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.config.result.expression,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariableHeader extends StatelessWidget {
  const _VariableHeader({required this.variable, required this.valueText});

  final FormulaVariable variable;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = '${variable.label} (${variable.symbol})';
        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
