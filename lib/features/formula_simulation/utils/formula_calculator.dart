import 'dart:math' as math;

class FormulaCalculator {
  const FormulaCalculator._();

  static const supportedSyntax =
      'Dùng số, biến, ngoặc (), toán tử +, -, *, /, ^ (mũ), căn (sqrt/cbrt/√), hàm sin/cos/tan/abs/pow/ln/log và hằng số pi.';

  static const Set<String> _knownMathKeywords = {
    'sqrt',
    'cbrt',
    'pow',
    'abs',
    'sin',
    'cos',
    'tan',
    'sin_deg',
    'sind',
    'cos_deg',
    'cosd',
    'tan_deg',
    'tand',
    'log',
    'log10',
    'ln',
    'exp',
    'pi',
    'π',
  };

  static String normalizeExpression(String expression) => expression
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('**', '^')
      .replaceAll('π', 'pi')
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
          .where((symbol) => !_knownMathKeywords.contains(symbol))
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

class _CommaToken extends _Token {
  const _CommaToken();
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
      if ('+-*/^'.contains(char)) {
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
      if (char == ',') {
        output.add(const _CommaToken());
        index++;
        continue;
      }
      if (char == '√') {
        output.add(const _IdentifierToken('sqrt'));
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
      throw FormatException('Ký tự không được hỗ trợ trong biểu thức: $char');
    }
    if (output.isEmpty) {
      throw const FormatException('Biểu thức không được để trống');
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
      throw const FormatException('Cú pháp biểu thức không hợp lệ');
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
    var value = _parsePower();
    while (_matchOperator('*') || _matchOperator('/')) {
      final operator = (tokens[_index - 1] as _OperatorToken).value;
      final right = _parsePower();
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

  double _parsePower() {
    var value = _parseFactor();
    if (_matchOperator('^')) {
      final right = _parsePower();
      value = math.pow(value, right).toDouble();
    }
    return value;
  }

  double _parseFactor() {
    if (_matchOperator('-')) return -_parseFactor();
    if (_matchOperator('+')) return _parseFactor();

    final token = _advance();
    return switch (token) {
      _NumberToken(value: final value) => value,
      _IdentifierToken(value: final name) => _parseIdentifier(name),
      _LeftParenToken() => _parseGroupedExpression(),
      _ => throw const FormatException('Thiếu yếu tố biểu thức hợp lệ'),
    };
  }

  double _parseIdentifier(String name) {
    if (name == 'pi' || name == 'π') {
      return math.pi;
    }

    if (name == 'pow') {
      _matchLeftParenOrThrow();
      final base = _parseExpression();
      _matchCommaOrThrow();
      final exponent = _parseExpression();
      _matchRightParenOrThrow();
      return math.pow(base, exponent).toDouble();
    }

    if (FormulaCalculator._knownMathKeywords.contains(name)) {
      double arg;
      if (_checkLeftParen()) {
        _advance();
        arg = _parseExpression();
        _matchRightParenOrThrow();
      } else {
        arg = _parseFactor();
      }
      return _evaluateFunction(name, arg);
    }

    return values[name] ?? fallbackIdentifierValue;
  }

  double _evaluateFunction(String name, double arg) {
    switch (name) {
      case 'sqrt':
        if (arg < 0) {
          throw const FormatException('Không thể lấy căn bậc hai của số âm');
        }
        return math.sqrt(arg);
      case 'cbrt':
        if (arg < 0) {
          return -math.pow(-arg, 1.0 / 3.0).toDouble();
        }
        return math.pow(arg, 1.0 / 3.0).toDouble();
      case 'abs':
        return arg.abs();
      case 'sin':
        return math.sin(arg);
      case 'cos':
        return math.cos(arg);
      case 'tan':
        return math.tan(arg);
      case 'sin_deg':
      case 'sind':
        return math.sin(arg * math.pi / 180.0);
      case 'cos_deg':
      case 'cosd':
        return math.cos(arg * math.pi / 180.0);
      case 'tan_deg':
      case 'tand':
        return math.tan(arg * math.pi / 180.0);
      case 'log':
      case 'log10':
        if (arg <= 0) {
          throw const FormatException('Lôgarit yêu cầu số dương');
        }
        return math.log(arg) / math.ln10;
      case 'ln':
        if (arg <= 0) {
          throw const FormatException('Lôgarit yêu cầu số dương');
        }
        return math.log(arg);
      case 'exp':
        return math.exp(arg);
      default:
        throw FormatException('Hàm không hỗ trợ: $name');
    }
  }

  double _parseGroupedExpression() {
    final value = _parseExpression();
    _matchRightParenOrThrow();
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

  bool _checkLeftParen() {
    if (_index >= tokens.length) return false;
    return tokens[_index] is _LeftParenToken;
  }

  void _matchLeftParenOrThrow() {
    final token = _advance();
    if (token is! _LeftParenToken) {
      throw const FormatException('Thiếu dấu mở ngoặc (');
    }
  }

  void _matchRightParenOrThrow() {
    final token = _advance();
    if (token is! _RightParenToken) {
      throw const FormatException('Missing closing parenthesis');
    }
  }

  void _matchCommaOrThrow() {
    final token = _advance();
    if (token is! _CommaToken) {
      throw const FormatException('Thiếu dấu phẩy , giữa các tham số');
    }
  }
}

