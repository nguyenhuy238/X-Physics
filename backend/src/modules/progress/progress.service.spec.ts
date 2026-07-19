import { ProgressService } from "./progress.service";

const user = {
  id: "user-1",
  email: "student@example.com",
  role: "STUDENT" as const,
};

class FakeDatabase {
  profile = {
    id: "user-1",
    name: "Student",
    email: "s@example.com",
    role: "STUDENT",
    coins: 140,
  };
  completedLessons = 0;
  totalLessons = 0;
  averageScoreValue = 0;
  badges: any[] = [];
  allBadges: any[] = [];
  chapterProgress: any[] = [];
  attempts: any[] = [];
  requestedRecentLimit = 0;
  requestedUserIds: string[] = [];

  async findUserById(id: string) {
    this.requestedUserIds.push(id);
    return id === user.id ? this.profile : null;
  }

  async countCompletedLessons(id: string) {
    this.requestedUserIds.push(id);
    return this.completedLessons;
  }

  async countTotalLessons() {
    return this.totalLessons;
  }

  async listBadgesByUser(id: string) {
    this.requestedUserIds.push(id);
    return this.badges;
  }

  async listAllBadges() {
    return this.allBadges;
  }

  async averageBestScore(id: string) {
    this.requestedUserIds.push(id);
    return this.averageScoreValue;
  }

  async listChapterProgress(id: string) {
    this.requestedUserIds.push(id);
    return this.chapterProgress;
  }

  async listRecentAttemptsByUser(id: string, limit = 5) {
    this.requestedUserIds.push(id);
    this.requestedRecentLimit = limit;
    return this.attempts.slice(0, limit);
  }

  async currentLearningStreak(id: string) {
    this.requestedUserIds.push(id);
    return 1;
  }

  toPublicUser(profile: any) {
    return {
      id: profile.id,
      name: profile.name,
      email: profile.email,
      role: profile.role,
      coins: profile.coins,
    };
  }
}

describe("ProgressService dashboard", () => {
  let database: FakeDatabase;
  let service: ProgressService;

  beforeEach(() => {
    database = new FakeDatabase();
    const notificationsService = {
      awardBadgesAndNotify: jest.fn().mockResolvedValue([]),
    };
    service = new ProgressService(database as any, notificationsService as any);
  });

  it("returns safe empty values for a user without progress", async () => {
    const result = await service.dashboard(user);

    expect(result).toMatchObject({
      overallProgress: 0,
      completedLessons: 0,
      totalLessons: 0,
      averageScore: 0,
      totalCoins: 140,
      chapterProgress: [],
      recentAttempts: [],
    });
  });

  it("avoids division by zero when totalLessons is 0", async () => {
    database.completedLessons = 3;
    database.totalLessons = 0;

    const result = await service.dashboard(user);

    expect(result.overallProgress).toBe(0);
  });

  it("calculates progress across multiple chapters", async () => {
    database.completedLessons = 3;
    database.totalLessons = 6;
    database.chapterProgress = [
      {
        chapterId: "motion",
        title: "Motion",
        completedLessons: 2,
        totalLessons: 2,
      },
      {
        chapterId: "electric",
        title: "Electric",
        completedLessons: 1,
        totalLessons: 4,
      },
    ];

    const result = await service.dashboard(user);

    expect(result.overallProgress).toBe(50);
    expect(result.chapterProgress).toEqual([
      {
        chapterId: "motion",
        title: "Motion",
        completedLessons: 2,
        totalLessons: 2,
        progressPercent: 100,
      },
      {
        chapterId: "electric",
        title: "Electric",
        completedLessons: 1,
        totalLessons: 4,
        progressPercent: 25,
      },
    ]);
  });

  it("returns recent attempts newest first and limits to 5", async () => {
    database.attempts = Array.from({ length: 6 }, (_, index) => ({
      id: `attempt-${index + 1}`,
      lessonId: `lesson-${index + 1}`,
      lessonTitle: `Lesson ${index + 1}`,
      score: 10 - index,
      submittedAt: new Date(`2026-07-13T0${index}:00:00.000Z`),
      durationSeconds: 100 + index,
    }));

    const result = await service.dashboard(user);

    expect(database.requestedRecentLimit).toBe(5);
    expect(result.recentAttempts).toHaveLength(5);
    expect(result.recentAttempts[0]).toMatchObject({
      attemptId: "attempt-1",
      lessonId: "lesson-1",
      score: 10,
    });
  });

  it("does not request data for another user", async () => {
    await service.dashboard(user);

    expect(new Set(database.requestedUserIds)).toEqual(new Set([user.id]));
  });

  it("rounds average score according to best-score business rule source", async () => {
    database.averageScoreValue = 8.236;

    const result = await service.dashboard(user);

    expect(result.averageScore).toBe(8.24);
  });
});

describe("ProgressService profile", () => {
  let database: FakeDatabase;
  let service: ProgressService;

  beforeEach(() => {
    database = new FakeDatabase();
    database.completedLessons = 1;
    database.totalLessons = 6;
    database.averageScoreValue = 8.236;
    database.badges = [
      {
        id: "starter",
        name: "Starter",
        description: "First lesson",
        iconUrl: null,
        ruleKey: "complete_first_lesson",
        achievedAt: new Date("2026-07-13T09:00:00.000Z"),
      },
    ];
    database.allBadges = [
      ...database.badges,
      {
        id: "scientist",
        name: "Scientist",
        description: "Complete all",
        iconUrl: "science",
        ruleKey: "complete_all_lessons",
      },
      {
        id: "motion-master",
        name: "Motion Master",
        description: "Complete motion",
        iconUrl: "rocket",
        ruleKey: "complete_chapter",
        conditionValue: "motion",
      },
    ];
    database.chapterProgress = [
      {
        chapterId: "motion",
        title: "Motion",
        completedLessons: 1,
        totalLessons: 2,
      },
    ];
    const notificationsService = {
      awardBadgesAndNotify: jest.fn().mockResolvedValue([]),
    };
    service = new ProgressService(database as any, notificationsService as any);
  });

  it("returns earned badges with achievedAt and nullable icon", async () => {
    const result = await service.profile(user);

    expect(result.earnedBadges).toEqual([
      {
        id: "starter",
        name: "Starter",
        description: "First lesson",
        iconUrl: null,
        ruleKey: "complete_first_lesson",
        achievedAt: new Date("2026-07-13T09:00:00.000Z"),
      },
    ]);
  });

  it("returns locked badges without duplicating earned badges", async () => {
    const result = await service.profile(user);

    expect(result.lockedBadges.map((badge: any) => badge.id)).toEqual([
      "scientist",
      "motion-master",
    ]);
    expect(result.lockedBadges.map((badge: any) => badge.id)).not.toContain(
      "starter",
    );
  });

  it("adds progress for locked badges when calculable", async () => {
    const result = await service.profile(user);

    expect(result.lockedBadges[0]).toMatchObject({
      id: "scientist",
      progressCurrent: 1,
      progressTarget: 6,
    });
    expect(result.lockedBadges[1]).toMatchObject({
      id: "motion-master",
      progressCurrent: 1,
      progressTarget: 2,
    });
  });

  it("returns safe empty profile sections", async () => {
    database.badges = [];
    database.allBadges = [];
    database.attempts = [];

    const result = await service.profile(user);

    expect(result.earnedBadges).toEqual([]);
    expect(result.lockedBadges).toEqual([]);
    expect(result.recentAttempts).toEqual([]);
  });

  it("only requests current user data", async () => {
    await service.profile(user);

    expect(new Set(database.requestedUserIds)).toEqual(new Set([user.id]));
  });
});
