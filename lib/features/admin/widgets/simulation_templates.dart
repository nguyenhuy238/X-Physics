import '../../../shared/models/x_models.dart';

class SimulationTemplate {
  const SimulationTemplate({required this.id, required this.name, this.config});

  final String id;
  final String name;
  final FormulaSimulationConfig? config;

  bool get isCustom => config == null;
}

const simulationTemplates = <SimulationTemplate>[
  SimulationTemplate(id: 'custom', name: 'Không dùng mẫu / Tùy chỉnh'),
  SimulationTemplate(
    id: 'velocity',
    name: 'Vận tốc: v = s / t',
    config: FormulaSimulationConfig(
      title: 'Mô phỏng vận tốc',
      formula: r'v = \frac{s}{t}',
      variables: [
        FormulaVariable(
          symbol: 's',
          label: 'Quãng đường',
          unit: 'm',
          min: 0,
          max: 1000,
          step: 10,
          defaultValue: 100,
        ),
        FormulaVariable(
          symbol: 't',
          label: 'Thời gian',
          unit: 's',
          min: 1,
          max: 120,
          step: 1,
          defaultValue: 10,
        ),
      ],
      result: FormulaResult(
        symbol: 'v',
        label: 'Vận tốc',
        unit: 'm/s',
        expression: 's / t',
        decimalPlaces: 2,
      ),
    ),
  ),
  SimulationTemplate(
    id: 'distance',
    name: 'Quãng đường: s = v * t',
    config: FormulaSimulationConfig(
      title: 'Mô phỏng quãng đường',
      formula: r's = v \times t',
      variables: [
        FormulaVariable(
          symbol: 'v',
          label: 'Vận tốc',
          unit: 'm/s',
          min: 0,
          max: 60,
          step: 1,
          defaultValue: 10,
        ),
        FormulaVariable(
          symbol: 't',
          label: 'Thời gian',
          unit: 's',
          min: 0,
          max: 120,
          step: 1,
          defaultValue: 10,
        ),
      ],
      result: FormulaResult(
        symbol: 's',
        label: 'Quãng đường',
        unit: 'm',
        expression: 'v * t',
        decimalPlaces: 2,
      ),
    ),
  ),
  SimulationTemplate(
    id: 'ohm',
    name: 'Định luật Ohm: I = U / R',
    config: FormulaSimulationConfig(
      title: 'Mô phỏng định luật Ohm',
      formula: r'I = \frac{U}{R}',
      variables: [
        FormulaVariable(
          symbol: 'U',
          label: 'Hiệu điện thế',
          unit: 'V',
          min: 0,
          max: 220,
          step: 1,
          defaultValue: 12,
        ),
        FormulaVariable(
          symbol: 'R',
          label: 'Điện trở',
          unit: 'ohm',
          min: 1,
          max: 100,
          step: 1,
          defaultValue: 4,
        ),
      ],
      result: FormulaResult(
        symbol: 'I',
        label: 'Cường độ dòng điện',
        unit: 'A',
        expression: 'U / R',
        decimalPlaces: 2,
      ),
    ),
  ),
  SimulationTemplate(
    id: 'pressure',
    name: 'Áp suất: p = F / S',
    config: FormulaSimulationConfig(
      title: 'Mô phỏng áp suất',
      formula: r'p = \frac{F}{S}',
      variables: [
        FormulaVariable(
          symbol: 'F',
          label: 'Lực tác dụng',
          unit: 'N',
          min: 0,
          max: 1000,
          step: 10,
          defaultValue: 100,
        ),
        FormulaVariable(
          symbol: 'S',
          label: 'Diện tích',
          unit: 'm2',
          min: 0.1,
          max: 20,
          step: 0.1,
          defaultValue: 2,
        ),
      ],
      result: FormulaResult(
        symbol: 'p',
        label: 'Áp suất',
        unit: 'Pa',
        expression: 'F / S',
        decimalPlaces: 2,
      ),
    ),
  ),
  SimulationTemplate(
    id: 'electric-power',
    name: 'Công suất điện: P = U * I',
    config: FormulaSimulationConfig(
      title: 'Mô phỏng công suất điện',
      formula: r'P = U \times I',
      variables: [
        FormulaVariable(
          symbol: 'U',
          label: 'Hiệu điện thế',
          unit: 'V',
          min: 0,
          max: 220,
          step: 1,
          defaultValue: 12,
        ),
        FormulaVariable(
          symbol: 'I',
          label: 'Cường độ dòng điện',
          unit: 'A',
          min: 0,
          max: 20,
          step: 0.1,
          defaultValue: 2,
        ),
      ],
      result: FormulaResult(
        symbol: 'P',
        label: 'Công suất điện',
        unit: 'W',
        expression: 'U * I',
        decimalPlaces: 2,
      ),
    ),
  ),
];
