import { NotFoundException } from "@nestjs/common";

import { PracticeService } from "./practice.service";

const user = {
  id: "user-1",
  email: "student@example.com",
  role: "STUDENT" as const,
};

class FakeDatabase {
  lessons = new Map([["lesson-1", { id: "lesson-1", chapterId: "chapter-1" }]]);
  questions = [
    {
      id: "pq-1",
      lessonId: "lesson-1",
      question: "Practice 1",
      options: ["A", "B", "C", "D"],
      correctOption: 0,
      explanation: "Because A",
      hint: "",
      isOfflineEnabled: true,
      orderIndex: 1,
    },
  ];
  sessions: any[] = [];
  rewardEvents: any[] = [];
  coins = 0;
  progressWrites = 0;
  badges = new Set<string>();

  async withTransaction<T>(work: (client: this) => Promise<T>) {
    const snapshot = {
      sessions: [...this.sessions],
      rewardEvents: [...this.rewardEvents],
      coins: this.coins,
      badges: new Set(this.badges),
      progressWrites: this.progressWrites,
    };
    try {
      return await work(this);
    } catch (error) {
      this.sessions = snapshot.sessions;
      this.rewardEvents = snapshot.rewardEvents;
      this.coins = snapshot.coins;
      this.badges = snapshot.badges;
      this.progressWrites = snapshot.progressWrites;
      throw error;
    }
  }

  async lockRewardScope() {}

  async findLesson(id: string) {
    const lesson = this.lessons.get(id);
    if (!lesson) throw new NotFoundException("Lesson not found");
    return lesson;
  }

  async listPracticeQuestionsByLesson() {
    return this.questions;
  }

  async createPracticeSessionIfAbsent(input: any) {
    const existing = this.sessions.find(
      (session) => session.id === input.id && session.userId === input.userId,
    );
    if (existing) {
      return { session: existing, created: false };
    }
    const session = {
      ...input,
      createdAt: new Date(),
      syncedAt: new Date(),
    };
    this.sessions.push(session);
    return { session, created: true };
  }

  async countRewardedPracticeSessionsToday(userId: string) {
    return this.rewardEvents.filter(
      (event) =>
        event.userId === userId && event.rewardType === "PRACTICE_SESSION",
    ).length;
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
    this.coins += coins;
    return { coins: this.coins };
  }

  async countPracticeSessionsByUser(userId: string) {
    return this.sessions.filter((session) => session.userId === userId).length;
  }

  async currentPracticeStreak() {
    return 1;
  }

  async listBadgesByRule(ruleKey: string) {
    if (ruleKey === "practice_count") {
      return [{ id: "practice-count-2", ruleKey, conditionValue: "2" }];
    }
    return [];
  }

  async awardBadge(_userId: string, badgeId: string) {
    if (this.badges.has(badgeId)) return null;
    this.badges.add(badgeId);
    return { id: badgeId, name: badgeId, ruleKey: "practice_count" };
  }

  async upsertProgress() {
    this.progressWrites++;
  }
}

function session(id: string, selectedOption = 0) {
  return {
    id,
    answers: [{ questionId: "pq-1", selectedOption }],
    startedAt: "2026-07-21T00:00:00.000Z",
    completedAt: "2026-07-21T00:05:00.000Z",
  };
}

describe("PracticeService", () => {
  let database: FakeDatabase;
  let service: PracticeService;

  beforeEach(() => {
    database = new FakeDatabase();
    service = new PracticeService(database as any);
  });

  it("caps rewarded practice sessions per day", async () => {
    const result = await service.syncSessions(user, "lesson-1", {
      items: Array.from({ length: 6 }, (_, index) =>
        session(`practice-session-${index + 1}`),
      ),
    });

    expect(result.syncedItems).toBe(6);
    expect(result.earnedCoins).toBe(25);
    expect(database.rewardEvents).toHaveLength(5);
    expect(database.coins).toBe(25);
    expect(database.progressWrites).toBe(0);
  });

  it("does not double reward the same client session id", async () => {
    const first = await service.syncSessions(user, "lesson-1", {
      items: [session("same-session")],
    });
    const retry = await service.syncSessions(user, "lesson-1", {
      items: [session("same-session")],
    });

    expect(first.earnedCoins).toBe(5);
    expect(retry.earnedCoins).toBe(0);
    expect(database.rewardEvents).toHaveLength(1);
    expect(database.coins).toBe(5);
    expect(database.sessions).toHaveLength(1);
    expect(database.progressWrites).toBe(0);
  });
});
