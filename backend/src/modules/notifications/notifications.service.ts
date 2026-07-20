import { Injectable } from "@nestjs/common";
import {
  DatabaseRepository,
  NotificationRow,
} from "../../database/database.repository";

const CHAPTER_BADGE_MIN_AVERAGE_SCORE = 5;

@Injectable()
export class NotificationsService {
  constructor(private readonly database: DatabaseRepository) {}

  async getNotifications(userId: string, page: number = 1, limit: number = 20) {
    const result = await this.database.listNotifications(userId, {
      page,
      limit,
    });
    return {
      items: result.items.map(this.mapNotification),
      page: result.page,
      limit: result.limit,
      total: result.total,
      totalPages: result.totalPages,
      unreadCount: result.unreadCount,
    };
  }

  async markAsRead(id: string, userId: string) {
    const row = await this.database.markNotificationAsRead(id, userId);
    return this.mapNotification(row);
  }

  async markAllAsRead(userId: string) {
    await this.database.markAllNotificationsAsRead(userId);
    return { success: true };
  }

  async createNotification(
    userId: string,
    type: string,
    title: string,
    message: string,
    data?: any,
  ) {
    const row = await this.database.createNotification({
      userId,
      type,
      title,
      message,
      data,
    });
    return this.mapNotification(row);
  }

  async notifyAllStudents(
    type: string,
    title: string,
    message: string,
    data?: any,
  ) {
    const studentIds = await this.database.listAllStudentIds();
    await Promise.all(
      studentIds.map((studentId) =>
        this.createNotification(studentId, type, title, message, data),
      ),
    );
  }

  async notifyAdminsAndTeachers(
    type: string,
    title: string,
    message: string,
    data?: any,
  ) {
    const staffIds = await this.database.listAllAdminAndTeacherIds();
    await Promise.all(
      staffIds.map((staffId) =>
        this.createNotification(staffId, type, title, message, data),
      ),
    );
  }

  async awardBadgesAndNotify(
    userId: string,
    lessonId: string,
    chapterId: string,
    perfectScore: boolean,
    client?: any,
  ) {
    const awarded = [];
    const completedLessons = await this.database.countCompletedLessons(
      userId,
      client,
    );
    const totalLessons = await this.database.countTotalLessons(client);

    if (completedLessons >= 1) {
      awarded.push(
        ...(await this.awardBadgesByRule(
          userId,
          "complete_first_lesson",
          client,
        )),
      );
    }
    if (perfectScore) {
      awarded.push(
        ...(await this.awardBadgesByRule(userId, "quiz_score_10", client)),
      );
    }

    const streak = await this.database.currentLearningStreak(userId, client);
    const streakBadges = await this.database.listBadgesByRule(
      "streak_days",
      client,
    );
    for (const badge of streakBadges) {
      const target = Number(badge.conditionValue ?? 0);
      if (target > 0 && streak >= target) {
        const awardedBadge = await this.database.awardBadge(
          userId,
          badge.id,
          client,
        );
        if (awardedBadge) awarded.push(awardedBadge);
      }
    }

    const chapterLessons = await this.database.countLessonsInChapter(
      chapterId,
      client,
    );
    const chapterCompleted = await this.database.countCompletedLessonsInChapter(
      userId,
      chapterId,
      client,
    );
    if (chapterLessons > 0 && chapterCompleted >= chapterLessons) {
      const chapterAverageScore = await this.database.averageBestScoreInChapter(
        userId,
        chapterId,
        client,
      );
      if (chapterAverageScore > CHAPTER_BADGE_MIN_AVERAGE_SCORE) {
        const chapterBadges = await this.database.listBadgesByRule(
          "complete_chapter",
          client,
        );
        for (const badge of chapterBadges) {
          if (badge.conditionValue !== chapterId) continue;
          const awardedBadge = await this.database.awardBadge(
            userId,
            badge.id,
            client,
          );
          if (awardedBadge) awarded.push(awardedBadge);
        }
      }
    }

    if (totalLessons > 0 && completedLessons >= totalLessons) {
      awarded.push(
        ...(await this.awardBadgesByRule(
          userId,
          "complete_all_lessons",
          client,
        )),
      );
    }

    for (const badge of awarded) {
      await this.createNotification(
        userId,
        "ACHIEVEMENT",
        "Huy hiệu mới!",
        `Chúc mừng! Bạn đã đạt được huy hiệu mới: "${badge.name}"`,
        { badgeId: badge.id },
      );
    }

    return awarded;
  }

  private async awardBadgesByRule(
    userId: string,
    ruleKey: string,
    client?: any,
  ) {
    const badges = await this.database.listBadgesByRule(ruleKey, client);
    const awarded = [];
    for (const badge of badges) {
      const awardedBadge = await this.database.awardBadge(
        userId,
        badge.id,
        client,
      );
      if (awardedBadge) {
        awarded.push(awardedBadge);
      }
    }
    return awarded;
  }

  private mapNotification(row: NotificationRow) {
    return {
      id: row.id,
      userId: row.user_id,
      type: row.type,
      title: row.title,
      message: row.message,
      data: row.data_json,
      isRead: row.is_read,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}
