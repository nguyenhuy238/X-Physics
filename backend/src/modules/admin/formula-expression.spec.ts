import { FormulaExpression } from "./formula-expression";
import { BadRequestException } from "@nestjs/common";

describe("FormulaExpression", () => {
  const allowed = new Set(["m", "v", "g", "h", "k", "x", "l", "F1", "F2", "alpha"]);
  const defaultValues = new Map<string, number>([
    ["m", 2],
    ["v", 5],
    ["g", 9.8],
    ["h", 10],
    ["k", 100],
    ["x", 0.1],
    ["l", 2],
    ["F1", 10],
    ["F2", 15],
    ["alpha", 60],
  ]);

  it("validates basic linear arithmetic", () => {
    const { result, usedSymbols } = FormulaExpression.validate(
      "m * v",
      allowed,
      defaultValues,
    );
    expect(result).toBe(10);
    expect(Array.from(usedSymbols)).toEqual(["m", "v"]);
  });

  it("validates kinetic energy formula with exponentiation ^ (0.5 * m * v^2)", () => {
    const { result, usedSymbols } = FormulaExpression.validate(
      "0.5 * m * v^2",
      allowed,
      defaultValues,
    );
    expect(result).toBe(25); // 0.5 * 2 * 25
    expect(Array.from(usedSymbols)).toEqual(["m", "v"]);
  });

  it("validates free fall velocity with square root sqrt (sqrt(2 * g * h))", () => {
    const { result, usedSymbols } = FormulaExpression.validate(
      "sqrt(2 * g * h)",
      allowed,
      defaultValues,
    );
    expect(result).toBeCloseTo(14, 1); // sqrt(2 * 9.8 * 10) = sqrt(196) = 14
    expect(Array.from(usedSymbols)).toEqual(["g", "h"]);
  });

  it("validates pendulum period formula with pi and sqrt (2 * pi * sqrt(l / g))", () => {
    const { result, usedSymbols } = FormulaExpression.validate(
      "2 * pi * sqrt(l / g)",
      allowed,
      defaultValues,
    );
    expect(result).toBeCloseTo(2.838, 3);
    // pi and sqrt must NOT be counted as used symbols!
    expect(Array.from(usedSymbols)).toEqual(["l", "g"]);
  });

  it("supports trig in degrees (sin_deg, cos_deg)", () => {
    const { result } = FormulaExpression.validate(
      "10 * sin_deg(30)",
      allowed,
      defaultValues,
    );
    expect(result).toBeCloseTo(5, 4);
  });

  it("supports pow function pow(base, exp)", () => {
    const { result } = FormulaExpression.validate(
      "pow(2, 3)",
      allowed,
      defaultValues,
    );
    expect(result).toBe(8);
  });

  it("rejects unknown symbol", () => {
    expect(() =>
      FormulaExpression.validate("m * unknownVar", allowed, defaultValues),
    ).toThrow(BadRequestException);
  });

  it("rejects square root of negative number", () => {
    expect(() =>
      FormulaExpression.validate("sqrt(-10)", allowed, defaultValues),
    ).toThrow(BadRequestException);
  });
});
