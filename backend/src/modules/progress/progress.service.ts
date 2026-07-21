import { Injectable } from "@nestjs/common";

import { AuthenticatedUser } from "../../common/current-user";
import { DatabaseRepository } from "../../database/database.repository";
import { UpdateProgressDto } from "./dto/update-progress.dto";
import { NotificationsService } from "../notifications/notifications.service";

@Injectable()
export class ProgressService {
  constructor(
    private readonly database: DatabaseRepository,
    private readonly notificationsService: NotificationsService,
  ) {}

  async dashboard(user: AuthenticatedUser) {
    const [
      profile,
      completedLessons,
      totalLessons,
      badges,
      averageScore,
      chapterProgress,
      recentAttempts,
    ] = await Promise.all([
      this.database.findUserById(user.id),
      this.database.countCompletedLessons(user.id),
      this.database.countTotalLessons(),
      this.database.listBadgesByUser(user.id),
      this.database.averageBestScore(user.id),
      this.database.listChapterProgress(user.id),
      this.database.listRecentAttemptsByUser(user.id),
    ]);
    const normalizedChapterProgress = chapterProgress.map((chapter) => ({
      chapterId: chapter.chapterId,
      title: chapter.title,
      completedLessons: chapter.completedLessons,
      totalLessons: chapter.totalLessons,
      progressPercent:
        chapter.totalLessons === 0
          ? 0
          : Number(
              ((chapter.completedLessons / chapter.totalLessons) * 100).toFixed(
                2,
              ),
            ),
    }));
    return {
      overallProgress:
        totalLessons === 0
          ? 0
          : Number(((completedLessons / totalLessons) * 100).toFixed(2)),
      completedLessons,
      totalLessons,
      averageScore: Number(averageScore.toFixed(2)),
      totalCoins: profile?.coins ?? 0,
      coins: profile?.coins ?? 0,
      badgeCount: badges.length,
      chapterProgress: normalizedChapterProgress,
      recentAttempts: recentAttempts.map((attempt) => ({
        attemptId: attempt.id,
        lessonId: attempt.lessonId,
        lessonTitle: attempt.lessonTitle ?? "",
        score: attempt.score,
        submittedAt: attempt.submittedAt,
        durationSeconds: attempt.durationSeconds,
      })),
    };
  }

  async achievements(user: AuthenticatedUser) {
    return this.profile(user);
  }

  async profile(user: AuthenticatedUser) {
    const [
      profile,
      completedLessons,
      totalLessons,
      earnedBadges,
      allBadges,
      averageScore,
      recentAttempts,
      streak,
    ] = await Promise.all([
      this.database.findUserById(user.id),
      this.database.countCompletedLessons(user.id),
      this.database.countTotalLessons(),
      this.database.listBadgesByUser(user.id),
      this.database.listAllBadges(),
      this.database.averageBestScore(user.id),
      this.database.listRecentAttemptsByUser(user.id),
      this.database.currentLearningStreak(user.id),
    ]);
    const earnedBadgeIds = new Set(earnedBadges.map((badge) => badge.id));
    const chapterProgress = await this.database.listChapterProgress(user.id);
    const progressByChapter = new Map(
      chapterProgress.map((chapter) => [
        chapter.chapterId,
        { current: chapter.completedLessons, target: chapter.totalLessons },
      ]),
    );
    return {
      user: profile
        ? {
            ...this.database.toPublicUser(profile),
            avatarUrl: null,
          }
        : null,
      totalCoins: profile?.coins ?? 0,
      completedLessons,
      totalLessons,
      overallProgress: totalLessons === 0 ? 0 : completedLessons / totalLessons,
      averageScore: Number(averageScore.toFixed(2)),
      recentAttempts: recentAttempts.map((attempt) => ({
        attemptId: attempt.id,
        lessonId: attempt.lessonId,
        lessonTitle: attempt.lessonTitle ?? "",
        score: attempt.score,
        submittedAt: attempt.submittedAt,
        durationSeconds: attempt.durationSeconds,
      })),
      earnedBadges: earnedBadges.map((badge) => ({
        id: badge.id,
        name: badge.name,
        description: badge.description,
        iconUrl: badge.iconUrl,
        ruleKey: badge.ruleKey,
        conditionValue: badge.conditionValue,
        achievedAt: badge.achievedAt,
      })),
      lockedBadges: allBadges
        .filter((badge) => !earnedBadgeIds.has(badge.id))
        .map((badge) => {
          const progress = this.badgeProgress(
            badge.ruleKey,
            badge.conditionValue,
            completedLessons,
            totalLessons,
            streak,
            progressByChapter,
          );
          return {
            id: badge.id,
            name: badge.name,
            description: badge.description,
            iconUrl: badge.iconUrl,
            ruleKey: badge.ruleKey,
            conditionValue: badge.conditionValue,
            progressCurrent: progress.current,
            progressTarget: progress.target,
          };
        }),
    };
  }

  private badgeProgress(
    ruleKey: string,
    conditionValue: string | null | undefined,
    completedLessons: number,
    totalLessons: number,
    streak: number,
    progressByChapter: Map<string, { current: number; target: number }>,
  ) {
    if (ruleKey === "complete_first_lesson") {
      return { current: Math.min(completedLessons, 1), target: 1 };
    }
    if (ruleKey === "complete_all_lessons") {
      return { current: completedLessons, target: totalLessons };
    }
    if (ruleKey === "complete_chapter" && conditionValue) {
      return progressByChapter.get(conditionValue) ?? { current: 0, target: 0 };
    }
    if (ruleKey === "streak_days") {
      return {
        current: Math.min(streak, Number(conditionValue ?? 0)),
        target: Number(conditionValue ?? 0),
      };
    }
    return { current: 0, target: 1 };
  }

  me(user: AuthenticatedUser) {
    return this.database.listProgress(user.id);
  }

  async update(user: AuthenticatedUser, dto: UpdateProgressDto) {
    return this.database.withTransaction(async (client) => {
      const progress = await this.database.upsertProgress(
        {
          userId: user.id,
          lessonId: dto.lessonId,
          status: dto.status,
          progressPercent: dto.progressPercent,
        },
        client,
      );

      if (dto.status === "COMPLETED") {
        const lesson = await this.database.findAdminLesson(
          dto.lessonId,
          client,
        );
        if (lesson) {
          await this.notificationsService.awardBadgesAndNotify(
            user.id,
            dto.lessonId,
            lesson.chapterId,
            false,
            client,
          );
        }
      }

      return progress;
    });
  }
}
