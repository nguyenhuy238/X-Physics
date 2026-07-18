class FormulaCalculator {
  const FormulaCalculator._();

  static const supportedSyntax =
      'Dùng số, biến dạng A-Z/a-z/_, ngoặc tròn và toán tử +, -, *, /.';

  static String normalizeExpression(String expression) => expression
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .trim();

  static bool isSupported(String expression) {
    try {
      _Parser(
        _Tokenizer(normalizeExpression(expression)).tokens,
        const {},
        fallbackIdentifierValue: 1,
      ).parse();
      return true;
    } catch (_) {
      return false;
    }
  }

  static double calculate(String expression, Map<String, double> values) {
    final result = tryCalculate(expression, values);
    return result.value ?? 0;
  }

  static FormulaCalculationResult tryCalculate(
    String expression,
    Map<String, double> values,
  ) {
    try {
      final result = _Parser(
        _Tokenizer(normalizeExpression(expression)).tokens,
        values,
      ).parse();
      if (!result.isFinite) {
        return const FormulaCalculationResult(error: 'Kết quả không hữu hạn.');
      }
      return FormulaCalculationResult(value: result);
    } on FormatException catch (error) {
      return FormulaCalculationResult(error: error.message);
    } catch (error) {
      return FormulaCalculationResult(error: error.toString());
    }
  }

  static Set<String> referencedSymbols(String expression) {
    try {
      return _Tokenizer(normalizeExpression(expression)).tokens
          .whereType<_IdentifierToken>()
          .map((token) => token.value)
          .toSet();
    } catch (_) {
      return const {};
    }
  }
}

class FormulaCalculationResult {
  const FormulaCalculationResult({this.value, this.error});

  final double? value;
  final String? error;

  bool get isValid => value != null && error == null;
}

sealed class _Token {
  const _Token();
}

class _NumberToken extends _Token {
  const _NumberToken(this.value);
  final double value;
}

class _IdentifierToken extends _Token {
  const _IdentifierToken(this.value);
  final String value;
}

class _OperatorToken extends _Token {
  const _OperatorToken(this.value);
  final String value;
}

class _LeftParenToken extends _Token {
  const _LeftParenToken();
}

class _RightParenToken extends _Token {
  const _RightParenToken();
}

class _Tokenizer {
  _Tokenizer(this.expression);

  final String expression;

  List<_Token> get tokens {
    final output = <_Token>[];
    var index = 0;
    while (index < expression.length) {
      final char = expression[index];
      if (RegExp(r'\s').hasMatch(char)) {
        index++;
        continue;
      }
      if ('+-*/'.contains(char)) {
        output.add(_OperatorToken(char));
        index++;
        continue;
      }
      if (char == '(') {
        output.add(const _LeftParenToken());
        index++;
        continue;
      }
      if (char == ')') {
        output.add(const _RightParenToken());
        index++;
        continue;
      }
      if (RegExp(r'[0-9.]').hasMatch(char)) {
        final start = index;
        index++;
        while (index < expression.length &&
            RegExp(r'[0-9.]').hasMatch(expression[index])) {
          index++;
        }
        final value = double.parse(expression.substring(start, index));
        output.add(_NumberToken(value));
        continue;
      }
      if (RegExp(r'[A-Za-z_]').hasMatch(char)) {
        final start = index;
        index++;
        while (index < expression.length &&
            RegExp(r'[A-Za-z0-9_]').hasMatch(expression[index])) {
          index++;
        }
        output.add(_IdentifierToken(expression.substring(start, index)));
        continue;
      }
      throw const FormatException('Unsupported expression character');
    }
    if (output.isEmpty) {
      throw const FormatException('Expression is empty');
    }
    return output;
  }
}

class _Parser {
  _Parser(this.tokens, this.values, {this.fallbackIdentifierValue = 0});

  final List<_Token> tokens;
  final Map<String, double> values;
  final double fallbackIdentifierValue;
  var _index = 0;

  double parse() {
    final value = _parseExpression();
    if (_index != tokens.length) {
      throw const FormatException('Unexpected token');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (_matchOperator('+') || _matchOperator('-')) {
      final operator = (tokens[_index - 1] as _OperatorToken).value;
      final right = _parseTerm();
      value = operator == '+' ? value + right : value - right;
    }
    return value;
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (_matchOperator('*') || _matchOperator('/')) {
      final operator = (tokens[_index - 1] as _OperatorToken).value;
      final right = _parseFactor();
      if (operator == '/') {
        if (right == 0) {
          throw const FormatException('Division by zero');
        }
        value /= right;
      } else {
        value *= right;
      }
    }
    return value;
  }

  double _parseFactor() {
    if (_matchOperator('-')) return -_parseFactor();
    if (_matchOperator('+')) return _parseFactor();

    final token = _advance();
    return switch (token) {
      _NumberToken(value: final value) => value,
      _IdentifierToken(value: final value) =>
        values[value] ?? fallbackIdentifierValue,
      _LeftParenToken() => _parseGroupedExpression(),
      _ => throw const FormatException('Expected expression factor'),
    };
  }

  double _parseGroupedExpression() {
    final value = _parseExpression();
    final token = _advance();
    if (token is! _RightParenToken) {
      throw const FormatException('Missing closing parenthesis');
    }
    return value;
  }

  _Token _advance() {
    if (_index >= tokens.length) {
      throw const FormatException('Unexpected end of expression');
    }
    return tokens[_index++];
  }

  bool _matchOperator(String value) {
    if (_index >= tokens.length) return false;
    final token = tokens[_index];
    if (token is! _OperatorToken || token.value != value) return false;
    _index++;
    return true;
  }
}
