import { readFileSync } from "node:fs";
import { join } from "node:path";

describe("database validation constraints", () => {
  const schema = readFileSync(join(__dirname, "schema.sql"), "utf8");

  it("declares question integrity checks idempotently", () => {
    expect(schema).toContain("questions_correct_option_range");
    expect(schema).toContain("check (correct_option between 0 and 3)");
    expect(schema).toContain("questions_options_json_four_items");
    expect(schema).toContain("jsonb_typeof(options_json) = 'array'");
    expect(schema).toContain("jsonb_array_length(options_json) = 4");
  });

  it("declares quiz attempt integrity checks idempotently", () => {
    expect(schema).toContain("quiz_attempts_score_range");
    expect(schema).toContain("check (score between 0 and 10)");
    expect(schema).toContain("quiz_attempts_counts_valid");
    expect(schema).toContain("correct_count <= total_questions");
    expect(schema).toContain("quiz_attempts_duration_non_negative");
    expect(schema).toContain("check (duration_seconds >= 0)");
    expect(schema).toContain("quiz_attempts_coins_non_negative");
    expect(schema).toContain("check (coins_earned >= 0)");
  });

  it("declares user coins non-negative check idempotently", () => {
    expect(schema).toContain("users_coins_non_negative");
    expect(schema).toContain("check (coins >= 0)");
  });

  it("uses not valid constraints for existing database compatibility", () => {
    expect(schema).toContain("not valid");
  });
});
