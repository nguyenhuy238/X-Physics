import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from "@nestjs/common";

import { LessonsService } from "../lessons/lessons.service";
import { QuizService } from "./quiz.service";

const user = {
  id: "user-1",
  email: "student@example.com",
  role: "STUDENT" as const,
};

type Answer = { questionId: string; selectedOption: number };

class FakeDatabase {
  lessons = new Map([
    ["lesson-1", { id: "lesson-1", chapterId: "chapter-1" }],
    ["lesson-2", { id: "lesson-2", chapterId: "chapter-1" }],
    ["empty-lesson", { id: "empty-lesson", chapterId: "chapter-2" }],
  ]);

  questionsByLesson = new Map<string, any[]>([
    ["lesson-1", this.makeQuestions("lesson-1")],
    ["lesson-2", this.makeQuestions("lesson-2")],
    ["empty-lesson", []],
  ]);

  coins = 0;
  attempts: any[] = [];
  progress = new Map<string, any>();
  rewardEvents: any[] = [];
  badges = new Set<string>();
  activityDates: string[] = [];
  nextActivityDate = "2026-07-11";
  totalLessons = 2;
  failAwardBadge = false;
  failAddCoins = false;

  private makeQuestions(lessonId: string) {
    return Array.from({ length: 5 }, (_, index) => ({
      id: `${lessonId}-q${index + 1}`,
      lessonId,
      question: `Question ${index + 1}`,
      options: ["A", "B", "C", "D"],
      correctOption: 0,
      explanation: `Explanation ${index + 1}`,
      orderIndex: index + 1,
    }));
  }

  async withTransaction<T>(work: (client: this) => Promise<T>) {
    const snapshot = {
      coins: this.coins,
      attempts: [...this.attempts],
      progress: new Map(this.progress),
      rewardEvents: [...this.rewardEvents],
      badges: new Set(this.badges),
    };
    try {
      return await work(this);
    } catch (error) {
      this.coins = snapshot.coins;
      this.attempts = snapshot.attempts;
      this.progress = snapshot.progress;
      this.rewardEvents = snapshot.rewardEvents;
      this.badges = snapshot.badges;
      throw error;
    }
  }

  async lockRewardScope() {}

  async findLesson(id: string) {
    const lesson = this.lessons.get(id);
    if (!lesson) throw new NotFoundException("Lesson not found");
    return lesson;
  }

  async listQuestionsByLesson(lessonId: string) {
    return this.questionsByLesson.get(lessonId) ?? [];
  }

  async findProgressForLesson(userId: string, lessonId: string) {
    return this.progress.get(`${userId}:${lessonId}`) ?? null;
  }

  async createQuizAttempt(input: any) {
    const attempt = { id: `attempt-${this.attempts.length + 1}`, ...input };
    this.attempts.push(attempt);
    return attempt;
  }

  async upsertProgress(input: any) {
    const key = `${input.userId}:${input.lessonId}`;
    const previous = this.progress.get(key);
    const progress = {
      ...previous,
      ...input,
      latestQuizScore: input.latestQuizScore,
      bestQuizScore: Math.max(
        previous?.bestQuizScore ?? 0,
        input.bestQuizScore ?? 0,
      ),
      updatedAt: new Date(),
    };
    this.progress.set(key, progress);
    return progress;
  }

  async maxRewardLevel(
    userId: string,
    rewardType: string,
    sourceType: string,
    sourceId: string,
  ) {
    return Math.max(
      0,
      ...this.rewardEvents
        .filter(
          (event) =>
            event.userId === userId &&
            event.rewardType === rewardType &&
            event.sourceType === sourceType &&
            event.sourceId === sourceId,
        )
        .map((event) => event.rewardLevel),
    );
  }

  async createRewardEvent(input: any) {
    const exists = this.rewardEvents.some(
      (event) =>
        event.userId === input.userId &&
        event.rewardType === input.rewardType &&
        event.sourceType === input.sourceType &&
        event.sourceId === input.sourceId &&
        event.rewardLevel === input.rewardLevel,
    );
    if (exists) return null;
    const event = { id: `reward-${this.rewardEvents.length + 1}`, ...input };
    this.rewardEvents.push(event);
    return event;
  }

  async addCoins(_userId: string, coins: number) {
    if (this.failAddCoins) throw new Error("Coin update failed");
    this.coins += coins;
    return { coins: this.coins };
  }

  async countLessonsInChapter(chapterId: string) {
    return [...this.lessons.values()].filter(
      (lesson) =>
        lesson.chapterId === chapterId && !lesson.id.startsWith("empty"),
    ).length;
  }

  async countCompletedLessonsInChapter(userId: string, chapterId: string) {
    return [...this.progress.values()].filter(
      (progress) =>
        progress.userId === userId &&
        progress.status === "COMPLETED" &&
        this.lessons.get(progress.lessonId)?.chapterId === chapterId,
    ).length;
  }

  async countCompletedLessons(userId: string) {
    return [...this.progress.values()].filter(
      (progress) =>
        progress.userId === userId && progress.status === "COMPLETED",
    ).length;
  }

  async countTotalLessons() {
    return this.totalLessons;
  }

  async listBadgesByRule(ruleKey: string) {
    const badgesByRule: Record<string, any[]> = {
      complete_first_lesson: [{ id: "starter", ruleKey, conditionValue: null }],
      quiz_score_10: [{ id: "perfect-score", ruleKey, conditionValue: null }],
      complete_chapter: [
        { id: "chapter-1-master", ruleKey, conditionValue: "chapter-1" },
        { id: "chapter-2-master", ruleKey, conditionValue: "chapter-2" },
      ],
      streak_days: [{ id: "streak-3", ruleKey, conditionValue: "3" }],
      complete_all_lessons: [
        { id: "scientist", ruleKey, conditionValue: null },
      ],
    };
    return badgesByRule[ruleKey] ?? [];
  }

  async recordLearningActivity() {
    if (!this.activityDates.includes(this.nextActivityDate)) {
      this.activityDates.push(this.nextActivityDate);
    }
    return this.nextActivityDate;
  }

  async currentLearningStreak() {
    const dates = [...this.activityDates].sort().reverse();
    let streak = 0;
    let expected: string | null = null;
    for (const date of dates) {
      expected ??= date;
      if (date !== expected) break;
      streak++;
      const previousDate: Date = new Date(`${date}T00:00:00.000Z`);
      previousDate.setUTCDate(previousDate.getUTCDate() - 1);
      expected = previousDate.toISOString().slice(0, 10);
    }
    return streak;
  }

  async awardBadge(_userId: string, badgeId: string) {
    if (this.failAwardBadge) throw new Error("Badge insert failed");
    if (this.badges.has(badgeId)) return null;
    this.badges.add(badgeId);
    return {
      id: badgeId,
      name: badgeId,
      description: "",
      iconUrl: "",
      icon: "",
      ruleKey: badgeId,
    };
  }
}

function answersFor(lessonId: string, correctCount: number): Answer[] {
  return Array.from({ length: 5 }, (_, index) => ({
    questionId: `${lessonId}-q${index + 1}`,
    selectedOption: index < correctCount ? 0 : 1,
  }));
}

async function submit(
  service: QuizService,
  lessonId: string,
  answers: Answer[],
  durationSeconds = 123,
) {
  return service.submit(user, { lessonId, answers, durationSeconds });
}

describe("QuizService submit", () => {
  let database: FakeDatabase;
  let service: QuizService;

  beforeEach(() => {
    database = new FakeDatabase();
    const notificationsService = {
      createNotification: jest.fn(),
      awardBadgesAndNotify: jest.fn().mockImplementation(
        async (userId, lessonId, chapterId, perfectScore, client) => {
          const awarded = [];
          const completedLessons = await database.countCompletedLessons(userId);
          const totalLessons = await database.countTotalLessons();

          if (completedLessons >= 1) {
            const badges = await database.listBadgesByRule("complete_first_lesson");
            for (const b of badges) {
              const awardedBadge = await database.awardBadge(userId, b.id);
              if (awardedBadge) awarded.push(awardedBadge);
            }
          }
          if (perfectScore) {
            const badges = await database.listBadgesByRule("quiz_score_10");
            for (const b of badges) {
              const awardedBadge = await database.awardBadge(userId, b.id);
              if (awardedBadge) awarded.push(awardedBadge);
            }
          }

          const streak = await database.currentLearningStreak();
          const streakBadges = await database.listBadgesByRule("streak_days");
          for (const badge of streakBadges) {
            const target = Number(badge.conditionValue ?? 0);
            if (target > 0 && streak >= target) {
              const awardedBadge = await database.awardBadge(userId, badge.id);
              if (awardedBadge) awarded.push(awardedBadge);
            }
          }

          const chapterLessons = await database.countLessonsInChapter(chapterId);
          const chapterCompleted = await database.countCompletedLessonsInChapter(userId, chapterId);
          if (chapterLessons > 0 && chapterCompleted >= chapterLessons) {
            const chapterBadges = await database.listBadgesByRule("complete_chapter");
            for (const badge of chapterBadges) {
              if (badge.conditionValue !== chapterId) continue;
              const awardedBadge = await database.awardBadge(userId, badge.id);
              if (awardedBadge) awarded.push(awardedBadge);
            }
          }

          if (totalLessons > 0 && completedLessons >= totalLessons) {
            const badges = await database.listBadgesByRule("complete_all_lessons");
            for (const b of badges) {
              const awardedBadge = await database.awardBadge(userId, b.id);
              if (awardedBadge) awarded.push(awardedBadge);
            }
          }

          return awarded;
        }
      ),
    };
    service = new QuizService(database as any, notificationsService as any);
  });

  it("rejects missing lesson", async () => {
    await expect(submit(service, "missing", [])).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it("rejects lesson without questions", async () => {
    await expect(submit(service, "empty-lesson", [])).rejects.toThrow(
      "Lesson has no quiz questions",
    );
  });

  it("rejects empty answers", async () => {
    await expect(submit(service, "lesson-1", [])).rejects.toThrow(
      "answers must be a non-empty array",
    );
  });

  it("rejects missing answer", async () => {
    await expect(
      submit(service, "lesson-1", answersFor("lesson-1", 5).slice(0, 4)),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it("rejects extra answer", async () => {
    await expect(
      submit(service, "lesson-1", [
        ...answersFor("lesson-1", 5),
        { questionId: "lesson-1-q-extra", selectedOption: 0 },
      ]),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it("rejects duplicate questionId", async () => {
    const answers = answersFor("lesson-1", 5);
    answers[1] = { ...answers[0] };
    await expect(submit(service, "lesson-1", answers)).rejects.toThrow(
      "Duplicate questionId",
    );
  });

  it("rejects question from another lesson", async () => {
    const answers = answersFor("lesson-1", 5);
    answers[0] = { questionId: "lesson-2-q1", selectedOption: 0 };
    await expect(submit(service, "lesson-1", answers)).rejects.toThrow(
      "B? c�u h?i d� du?c c?p nh?t",
    );
  });

  it("rejects negative selectedOption", async () => {
    const answers = answersFor("lesson-1", 5);
    answers[0] = { questionId: "lesson-1-q1", selectedOption: -1 };
    await expect(submit(service, "lesson-1", answers)).rejects.toThrow(
      "selectedOption must be a non-negative integer",
    );
  });

  it("rejects selectedOption outside question options", async () => {
    const answers = answersFor("lesson-1", 5);
    answers[0] = { questionId: "lesson-1-q1", selectedOption: 4 };
    await expect(submit(service, "lesson-1", answers)).rejects.toThrow(
      "selectedOption is out of range",
    );
  });

  it("rejects invalid duration above max", async () => {
    await expect(
      submit(service, "lesson-1", answersFor("lesson-1", 5), 3601),
    ).rejects.toThrow("durationSeconds is too large");
  });

  it("calculates score 0 and no quiz reward below 6", async () => {
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 0));
    expect(result.score).toBe(0);
    expect(result.correctCount).toBe(0);
    expect(result.earnedCoins).toBe(10);
  });

  it("rewards exact score 6 with quiz tier 15", async () => {
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 3));
    expect(result.score).toBe(6);
    expect(result.earnedCoins).toBe(25);
  });

  it("rewards exact score 8 with quiz tier 20", async () => {
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 4));
    expect(result.score).toBe(8);
    expect(result.earnedCoins).toBe(30);
  });

  it("rewards perfect score without unsafe float comparison", async () => {
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 5));
    expect(result.score).toBe(10);
    expect(result.earnedCoins).toBe(40);
    expect(result.newBadges.map((badge: any) => badge.id)).toContain(
      "perfect-score",
    );
  });

  it("stores durationSeconds in the quiz attempt", async () => {
    await submit(service, "lesson-1", answersFor("lesson-1", 5), 222);
    expect(database.attempts[0].durationSeconds).toBe(222);
  });

  it("does not reward lesson completion twice", async () => {
    await submit(service, "lesson-1", answersFor("lesson-1", 3));
    const second = await submit(service, "lesson-1", answersFor("lesson-1", 3));
    expect(second.earnedCoins).toBe(0);
  });

  it("uses best-score delta for quiz rewards", async () => {
    await submit(service, "lesson-1", answersFor("lesson-1", 3));
    const improvedToEight = await submit(
      service,
      "lesson-1",
      answersFor("lesson-1", 4),
    );
    const improvedToPerfect = await submit(
      service,
      "lesson-1",
      answersFor("lesson-1", 5),
    );
    expect(improvedToEight.earnedCoins).toBe(5);
    expect(improvedToPerfect.earnedCoins).toBe(10);
  });

  it("does not lower best score after a worse retake", async () => {
    await submit(service, "lesson-1", answersFor("lesson-1", 5));
    const lower = await submit(service, "lesson-1", answersFor("lesson-1", 1));
    expect(database.progress.get("user-1:lesson-1").bestQuizScore).toBe(10);
    expect(database.progress.get("user-1:lesson-1").latestQuizScore).toBe(2);
    expect(lower.earnedCoins).toBe(0);
  });

  it("rewards chapter completion only once", async () => {
    await submit(service, "lesson-1", answersFor("lesson-1", 3));
    const completeChapter = await submit(
      service,
      "lesson-2",
      answersFor("lesson-2", 3),
    );
    const repeat = await submit(service, "lesson-2", answersFor("lesson-2", 4));
    expect(completeChapter.earnedCoins).toBe(75);
    expect(repeat.earnedCoins).toBe(5);
  });

  it("awards dynamic chapter badge for completed chapter", async () => {
    await submit(service, "lesson-1", answersFor("lesson-1", 3));
    const result = await submit(service, "lesson-2", answersFor("lesson-2", 3));

    expect(result.newBadges.map((badge: any) => badge.id)).toContain(
      "chapter-1-master",
    );
  });

  it("does not award chapter badge for a different chapter condition", async () => {
    await submit(service, "lesson-1", answersFor("lesson-1", 3));
    const result = await submit(service, "lesson-2", answersFor("lesson-2", 3));

    expect(result.newBadges.map((badge: any) => badge.id)).not.toContain(
      "chapter-2-master",
    );
  });

  it("tracks streak days 1, 2, and 3 with one activity per day", async () => {
    database.nextActivityDate = "2026-07-11";
    const day1 = await submit(service, "lesson-1", answersFor("lesson-1", 3));
    database.nextActivityDate = "2026-07-12";
    const day2 = await submit(service, "lesson-1", answersFor("lesson-1", 3));
    database.nextActivityDate = "2026-07-13";
    const day3 = await submit(service, "lesson-1", answersFor("lesson-1", 3));

    expect(day1.newBadges.map((badge: any) => badge.id)).not.toContain(
      "streak-3",
    );
    expect(day2.newBadges.map((badge: any) => badge.id)).not.toContain(
      "streak-3",
    );
    expect(day3.newBadges.map((badge: any) => badge.id)).toContain("streak-3");
    expect(database.activityDates).toEqual([
      "2026-07-11",
      "2026-07-12",
      "2026-07-13",
    ]);
  });

  it("does not count multiple activities on the same day twice", async () => {
    database.nextActivityDate = "2026-07-11";
    await submit(service, "lesson-1", answersFor("lesson-1", 3));
    await submit(service, "lesson-2", answersFor("lesson-2", 3));

    expect(database.activityDates).toEqual(["2026-07-11"]);
    expect(await database.currentLearningStreak()).toBe(1);
  });

  it("does not award streak when the sequence is broken", async () => {
    database.nextActivityDate = "2026-07-10";
    await submit(service, "lesson-1", answersFor("lesson-1", 3));
    database.nextActivityDate = "2026-07-12";
    await submit(service, "lesson-1", answersFor("lesson-1", 3));
    database.nextActivityDate = "2026-07-13";
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 3));

    expect(result.newBadges.map((badge: any) => badge.id)).not.toContain(
      "streak-3",
    );
  });

  it("awards all lessons badge from dynamic total lesson count", async () => {
    database.totalLessons = 1;
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 3));

    expect(result.newBadges.map((badge: any) => badge.id)).toContain(
      "scientist",
    );
  });

  it("does not award all lessons badge when totalLessons is zero", async () => {
    database.totalLessons = 0;
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 3));

    expect(result.newBadges.map((badge: any) => badge.id)).not.toContain(
      "scientist",
    );
  });

  it("does not duplicate badges in newBadges", async () => {
    const first = await submit(service, "lesson-1", answersFor("lesson-1", 5));
    const second = await submit(service, "lesson-1", answersFor("lesson-1", 5));
    expect(first.newBadges.length).toBeGreaterThan(0);
    expect(second.newBadges).toEqual([]);
  });

  it("rolls back attempt, progress, coins, rewards, and badges on failure", async () => {
    database.failAwardBadge = true;
    await expect(
      submit(service, "lesson-1", answersFor("lesson-1", 5)),
    ).rejects.toThrow("Badge insert failed");
    expect(database.attempts).toHaveLength(0);
    expect(database.progress.size).toBe(0);
    expect(database.rewardEvents).toHaveLength(0);
    expect(database.coins).toBe(0);
    expect(database.badges.size).toBe(0);
  });

  it("rolls back attempt, progress, rewards, and badges when add coins fails", async () => {
    database.failAddCoins = true;
    await expect(
      submit(service, "lesson-1", answersFor("lesson-1", 5)),
    ).rejects.toThrow("Coin update failed");
    expect(database.attempts).toHaveLength(0);
    expect(database.progress.size).toBe(0);
    expect(database.rewardEvents).toHaveLength(0);
    expect(database.badges.size).toBe(0);
    expect(database.coins).toBe(0);
  });

  it("returns review with selected, correct, isCorrect, and explanation", async () => {
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 4));
    expect(result.review[0]).toMatchObject({
      questionId: "lesson-1-q1",
      selectedOption: 0,
      correctOption: 0,
      isCorrect: true,
      explanation: "Explanation 1",
    });
  });

  it("stores historical review snapshot on the attempt", async () => {
    const result = await submit(service, "lesson-1", answersFor("lesson-1", 5));
    expect(database.attempts[0].review).toEqual(result.review);

    database.questionsByLesson.get("lesson-1")![0] = {
      ...database.questionsByLesson.get("lesson-1")![0],
      question: "Changed question",
      correctOption: 1,
      explanation: "Changed explanation",
    };

    expect(database.attempts[0].review[0]).toMatchObject({
      question: "Question 1",
      correctOption: 0,
      explanation: "Explanation 1",
    });
  });

  it("uses updated correct answer for future submits without changing old attempt", async () => {
    await submit(service, "lesson-1", answersFor("lesson-1", 5));
    database.questionsByLesson.get("lesson-1")![0].correctOption = 1;

    const answers = answersFor("lesson-1", 5);
    answers[0] = { questionId: "lesson-1-q1", selectedOption: 1 };
    const next = await submit(service, "lesson-1", answers);

    expect(next.correctCount).toBe(5);
    expect(database.attempts[0].review[0].correctOption).toBe(0);
  });

  it("rejects stale question set with 409 and creates no side effects", async () => {
    const answers = answersFor("lesson-1", 5);
    database.questionsByLesson.get("lesson-1")!.pop();

    await expect(submit(service, "lesson-1", answers)).rejects.toBeInstanceOf(
      ConflictException,
    );
    expect(database.attempts).toHaveLength(0);
    expect(database.progress.size).toBe(0);
    expect(database.rewardEvents).toHaveLength(0);
    expect(database.coins).toBe(0);
  });
});

describe("LessonsService questions", () => {
  it("returns five questions for an existing lesson", async () => {
    const database = new FakeDatabase();
    const service = new LessonsService(database as any);

    const questions = await service.questions("lesson-1");

    expect(questions).toHaveLength(5);
    expect(
      questions.every((question: any) => question.lessonId === "lesson-1"),
    ).toBe(true);
  });

  it("does not leak correctOption or explanation", async () => {
    const database = new FakeDatabase();
    const service = new LessonsService(database as any);

    const [question] = await service.questions("lesson-1");

    expect(question).not.toHaveProperty("correctOption");
    expect(question).not.toHaveProperty("explanation");
  });

  it("rejects missing lesson before listing questions", async () => {
    const database = new FakeDatabase();
    const service = new LessonsService(database as any);

    await expect(service.questions("missing")).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
