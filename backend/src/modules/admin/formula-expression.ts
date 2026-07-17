import { BadRequestException } from "@nestjs/common";

type Token =
  | { type: "number"; value: number }
  | { type: "identifier"; value: string }
  | { type: "operator"; value: "+" | "-" | "*" | "/" }
  | { type: "leftParen" }
  | { type: "rightParen" };

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
    let value = this.parseFactor();
    while (this.matchOperator("*") || this.matchOperator("/")) {
      const operator = (this.previous() as Extract<Token, { type: "operator" }>)
        .value;
      const right = this.parseFactor();
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
      if (!this.allowedSymbols.has(symbol)) {
        throw new BadRequestException(
          `Expression uses unknown symbol "${symbol}"`,
        );
      }
      this.usedSymbols.add(symbol);
      return this.values.get(symbol) ?? 0;
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

  private match(type: Token["type"]) {
    if (this.tokens[this.index]?.type !== type) return false;
    this.index += 1;
    return true;
  }

  private matchOperator(operator: "+" | "-" | "*" | "/") {
    const token = this.tokens[this.index];
    if (token?.type !== "operator" || token.value !== operator) return false;
    this.index += 1;
    return true;
  }

  private previous() {
    return this.tokens[this.index - 1];
  }
}

function tokenize(expression: string): Token[] {
  const tokens: Token[] = [];
  let index = 0;
  while (index < expression.length) {
    const char = expression[index];
    if (/\s/.test(char)) {
      index += 1;
      continue;
    }
    if (/[+\-*/]/.test(char)) {
      tokens.push({ type: "operator", value: char as "+" | "-" | "*" | "/" });
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
    if (/[0-9.]/.test(char)) {
      const start = index;
      index += 1;
      while (index < expression.length && /[0-9.]/.test(expression[index])) {
        index += 1;
      }
      const value = Number(expression.slice(start, index));
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
        index < expression.length &&
        /[A-Za-z0-9_]/.test(expression[index])
      ) {
        index += 1;
      }
      tokens.push({
        type: "identifier",
        value: expression.slice(start, index),
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
