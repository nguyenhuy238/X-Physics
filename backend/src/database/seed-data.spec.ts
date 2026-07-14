import { readFileSync } from "node:fs";
import { join } from "node:path";

function readSeed<T>(fileName: string): T {
  return JSON.parse(
    readFileSync(join(__dirname, "..", "..", "..", "seed-data", fileName), {
      encoding: "utf8",
    }),
  ) as T;
}

describe("Seed data demo readiness", () => {
  it("has a student demo account", () => {
    const users =
      readSeed<Array<{ email: string; role: string }>>("users.json");

    expect(users).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ email: "nam@example.com", role: "STUDENT" }),
      ]),
    );
  });

  it("has five questions with explanations for every lesson", () => {
    const lessons = readSeed<Array<{ id: string }>>("lessons.json");
    const questions =
      readSeed<Array<{ lessonId: string; explanation?: string }>>(
        "questions.json",
      );

    for (const lesson of lessons) {
      const lessonQuestions = questions.filter(
        (question) => question.lessonId === lesson.id,
      );
      expect(lessonQuestions).toHaveLength(5);
      expect(lessonQuestions.every((question) => question.explanation)).toBe(
        true,
      );
    }
  });

  it("has badge definitions for the TV4 demo rules", () => {
    const badges =
      readSeed<Array<{ ruleKey: string; conditionValue?: string }>>(
        "badges.json",
      );

    expect(badges.map((badge) => badge.ruleKey)).toEqual(
      expect.arrayContaining([
        "complete_first_lesson",
        "quiz_score_10",
        "complete_chapter",
        "streak_days",
        "complete_all_lessons",
      ]),
    );
    expect(
      badges.filter((badge) => badge.ruleKey === "complete_chapter"),
    ).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ conditionValue: "motion" }),
        expect.objectContaining({ conditionValue: "force" }),
        expect.objectContaining({ conditionValue: "electric" }),
      ]),
    );
  });
});
