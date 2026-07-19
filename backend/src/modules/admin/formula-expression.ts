import { BadRequestException } from "@nestjs/common";

type Token =
  | { type: "number"; value: number }
  | { type: "identifier"; value: string }
  | { type: "operator"; value: "+" | "-" | "*" | "/" | "^" }
  | { type: "leftParen" }
  | { type: "rightParen" }
  | { type: "comma" };

const KNOWN_MATH_KEYWORDS = new Set([
  "sqrt",
  "cbrt",
  "pow",
  "abs",
  "sin",
  "cos",
  "tan",
  "sin_deg",
  "sind",
  "cos_deg",
  "cosd",
  "tan_deg",
  "tand",
  "log",
  "log10",
  "ln",
  "exp",
  "pi",
  "π",
]);

export class FormulaExpression {
  private index = 0;
  private readonly usedSymbols = new Set<string>();

  private constructor(
    private readonly tokens: Token[],
    private readonly values: Map<string, number>,
    private readonly allowedSymbols: Set<string>,
  ) {}

  static validate(
    expression: string,
    allowedSymbols: Set<string>,
    values: Map<string, number>,
  ) {
    const parser = new FormulaExpression(
      tokenize(expression),
      values,
      allowedSymbols,
    );
    const result = parser.parseExpression();
    if (parser.index < parser.tokens.length) {
      throw new BadRequestException("Expression contains unexpected tokens");
    }
    if (!Number.isFinite(result)) {
      throw new BadRequestException("Expression result must be finite");
    }
    return { result, usedSymbols: parser.usedSymbols };
  }

  private parseExpression(): number {
    let value = this.parseTerm();
    while (this.matchOperator("+") || this.matchOperator("-")) {
      const operator = (this.previous() as Extract<Token, { type: "operator" }>)
        .value;
      const right = this.parseTerm();
      value = operator === "+" ? value + right : value - right;
    }
    return value;
  }

  private parseTerm(): number {
    let value = this.parsePower();
    while (this.matchOperator("*") || this.matchOperator("/")) {
      const operator = (this.previous() as Extract<Token, { type: "operator" }>)
        .value;
      const right = this.parsePower();
      if (operator === "/") {
        if (right === 0) {
          throw new BadRequestException("Expression divides by zero");
        }
        value /= right;
      } else {
        value *= right;
      }
    }
    return value;
  }

  private parsePower(): number {
    let value = this.parseFactor();
    if (this.matchOperator("^")) {
      const right = this.parsePower();
      value = Math.pow(value, right);
    }
    return value;
  }

  private parseFactor(): number {
    if (this.matchOperator("-")) {
      return -this.parseFactor();
    }
    if (this.matchOperator("+")) {
      return this.parseFactor();
    }
    if (this.match("number")) {
      return (this.previous() as Extract<Token, { type: "number" }>).value;
    }
    if (this.match("identifier")) {
      const symbol = (this.previous() as Extract<Token, { type: "identifier" }>)
        .value;
      return this.parseIdentifier(symbol);
    }
    if (this.match("leftParen")) {
      const value = this.parseExpression();
      if (!this.match("rightParen")) {
        throw new BadRequestException(
          "Expression is missing a closing parenthesis",
        );
      }
      return value;
    }
    throw new BadRequestException("Expression cannot be parsed");
  }

  private parseIdentifier(symbol: string): number {
    if (symbol === "pi" || symbol === "π") {
      return Math.PI;
    }

    if (symbol === "pow") {
      if (!this.match("leftParen")) {
        throw new BadRequestException("Function pow requires (");
      }
      const base = this.parseExpression();
      if (!this.match("comma")) {
        throw new BadRequestException("Function pow requires comma separator");
      }
      const exp = this.parseExpression();
      if (!this.match("rightParen")) {
        throw new BadRequestException(
          "Expression is missing a closing parenthesis",
        );
      }
      return Math.pow(base, exp);
    }

    if (KNOWN_MATH_KEYWORDS.has(symbol)) {
      let arg: number;
      if (this.match("leftParen")) {
        arg = this.parseExpression();
        if (!this.match("rightParen")) {
          throw new BadRequestException(
            "Expression is missing a closing parenthesis",
          );
        }
      } else {
        arg = this.parseFactor();
      }
      return this.evaluateFunction(symbol, arg);
    }

    if (!this.allowedSymbols.has(symbol)) {
      throw new BadRequestException(
        `Expression uses unknown symbol "${symbol}"`,
      );
    }
    this.usedSymbols.add(symbol);
    return this.values.get(symbol) ?? 0;
  }

  private evaluateFunction(name: string, arg: number): number {
    switch (name) {
      case "sqrt":
        if (arg < 0) {
          throw new BadRequestException("Cannot take square root of negative number");
        }
        return Math.sqrt(arg);
      case "cbrt":
        if (arg < 0) {
          return -Math.pow(-arg, 1 / 3);
        }
        return Math.cbrt ? Math.cbrt(arg) : Math.pow(arg, 1 / 3);
      case "abs":
        return Math.abs(arg);
      case "sin":
        return Math.sin(arg);
      case "cos":
        return Math.cos(arg);
      case "tan":
        return Math.tan(arg);
      case "sin_deg":
      case "sind":
        return Math.sin((arg * Math.PI) / 180);
      case "cos_deg":
      case "cosd":
        return Math.cos((arg * Math.PI) / 180);
      case "tan_deg":
      case "tand":
        return Math.tan((arg * Math.PI) / 180);
      case "log":
      case "log10":
        if (arg <= 0) {
          throw new BadRequestException("Logarithm requires positive number");
        }
        return Math.log10 ? Math.log10(arg) : Math.log(arg) / Math.LN10;
      case "ln":
        if (arg <= 0) {
          throw new BadRequestException("Logarithm requires positive number");
        }
        return Math.log(arg);
      case "exp":
        return Math.exp(arg);
      default:
        throw new BadRequestException(`Unsupported function: ${name}`);
    }
  }

  private match(type: Token["type"]) {
    if (this.tokens[this.index]?.type !== type) return false;
    this.index += 1;
    return true;
  }

  private matchOperator(operator: "+" | "-" | "*" | "/" | "^") {
    const token = this.tokens[this.index];
    if (token?.type !== "operator" || token.value !== operator) return false;
    this.index += 1;
    return true;
  }

  private previous() {
    return this.tokens[this.index - 1];
  }
}

function normalizeExpression(expression: string): string {
  return expression
    .replace(/×/g, "*")
    .replace(/÷/g, "/")
    .replace(/−/g, "-")
    .replace(/\*\*/g, "^")
    .replace(/π/g, "pi")
    .trim();
}

function tokenize(expression: string): Token[] {
  const normalized = normalizeExpression(expression);
  const tokens: Token[] = [];
  let index = 0;
  while (index < normalized.length) {
    const char = normalized[index];
    if (/\s/.test(char)) {
      index += 1;
      continue;
    }
    if (/[+\-*/^]/.test(char)) {
      tokens.push({
        type: "operator",
        value: char as "+" | "-" | "*" | "/" | "^",
      });
      index += 1;
      continue;
    }
    if (char === "(") {
      tokens.push({ type: "leftParen" });
      index += 1;
      continue;
    }
    if (char === ")") {
      tokens.push({ type: "rightParen" });
      index += 1;
      continue;
    }
    if (char === ",") {
      tokens.push({ type: "comma" });
      index += 1;
      continue;
    }
    if (char === "√") {
      tokens.push({ type: "identifier", value: "sqrt" });
      index += 1;
      continue;
    }
    if (/[0-9.]/.test(char)) {
      const start = index;
      index += 1;
      while (index < normalized.length && /[0-9.]/.test(normalized[index])) {
        index += 1;
      }
      const value = Number(normalized.slice(start, index));
      if (!Number.isFinite(value)) {
        throw new BadRequestException("Expression contains an invalid number");
      }
      tokens.push({ type: "number", value });
      continue;
    }
    if (/[A-Za-z_]/.test(char)) {
      const start = index;
      index += 1;
      while (
        index < normalized.length &&
        /[A-Za-z0-9_]/.test(normalized[index])
      ) {
        index += 1;
      }
      tokens.push({
        type: "identifier",
        value: normalized.slice(start, index),
      });
      continue;
    }
    throw new BadRequestException(
      `Expression contains unsupported character "${char}"`,
    );
  }
  if (tokens.length === 0) {
    throw new BadRequestException("Expression is required");
  }
  return tokens;
}

