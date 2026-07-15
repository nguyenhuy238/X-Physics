import { NotFoundException } from "@nestjs/common";

import { OfflineSyncService } from "./offline-sync.service";

const user = {
  id: "user-1",
  email: "student@example.com",
  role: "STUDENT" as const,
};

class FakeDatabase {
  publishedLessonIds = new Set(["motion-1"]);
  upsertedProgress: any[] = [];
  recordedDownloads: any[] = [];

  async upsertProgress(input: any) {
    this.upsertedProgress.push(input);
    return input;
  }

  async findLesson(id: string) {
    if (!this.publishedLessonIds.has(id)) {
      throw new NotFoundException("Lesson not found");
    }
    return { id };
  }

  async recordLessonDownload(input: any) {
    this.recordedDownloads.push(input);
  }
}

describe("OfflineSyncService.syncProgress", () => {
  let database: FakeDatabase;
  let service: OfflineSyncService;

  beforeEach(() => {
    database = new FakeDatabase();
    service = new OfflineSyncService(database as any);
  });

  it("upserts progress for every item and reports the synced count", async () => {
    const result = await service.syncProgress(user, {
      items: [
        {
          lessonId: "motion-1",
          progressPercent: 100,
          clientUpdatedAt: "2026-07-14T00:00:00.000Z",
        },
        {
          lessonId: "force-1",
          progressPercent: 40,
          clientUpdatedAt: "2026-07-14T00:01:00.000Z",
        },
      ],
    } as any);

    expect(result).toEqual({ syncedItems: 2, conflicts: [] });
    expect(database.upsertedProgress).toHaveLength(2);
    expect(database.upsertedProgress[0]).toMatchObject({
      userId: user.id,
      lessonId: "motion-1",
      status: "COMPLETED",
      progressPercent: 100,
    });
    expect(database.upsertedProgress[1]).toMatchObject({
      status: "IN_PROGRESS",
      progressPercent: 40,
    });
  });
});

describe("OfflineSyncService.recordDownload", () => {
  let database: FakeDatabase;
  let service: OfflineSyncService;

  beforeEach(() => {
    database = new FakeDatabase();
    service = new OfflineSyncService(database as any);
  });

  it("records a download event for a published lesson", async () => {
    const result = await service.recordDownload(user, {
      lessonId: "motion-1",
      clientDeviceId: "device-1",
    } as any);

    expect(result).toEqual({ recorded: true });
    expect(database.recordedDownloads).toEqual([
      { userId: user.id, lessonId: "motion-1", clientDeviceId: "device-1" },
    ]);
  });

  it("throws 404 instead of recording when the lesson does not exist", async () => {
    await expect(
      service.recordDownload(user, { lessonId: "unknown-lesson" } as any),
    ).rejects.toBeInstanceOf(NotFoundException);

    expect(database.recordedDownloads).toHaveLength(0);
  });
});
