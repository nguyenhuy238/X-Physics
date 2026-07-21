import {
  BadRequestException,
  ConflictException,
  Injectable,
} from "@nestjs/common";

import { AuthenticatedUser } from "../../common/current-user";
import { DatabaseRepository } from "../../database/database.repository";
import {
  SyncPracticeSessionItemDto,
  SyncPracticeSessionsDto,
} from "./dto/sync-practice-sessions.dto";

const DAILY_REWARDED_PRACTICE_SESSION_CAP = 5;

@Injectable()
export class PracticeService {
  constructor(private readonly database: DatabaseRepository) {}

  async questions(lessonId: string, offlineOnly = false) {
    await this.database.findLesson(lessonId);
    return this.database.listPracticeQuestionsByLesson(lessonId, {
      offlineOnly,
    });
  }

  async syncSessions(
    user: AuthenticatedUser,
    lessonId: string,
    dto: SyncPracticeSessionsDto,
  ) {
    if (!dto.items.length) {
      throw new BadRequestException("items must not be empty");
    }

    return this.database.withTransaction(async (client) => {
      await this.database.lockRewardScope(
        user.id,
        "PRACTICE_LESSON",
        lessonId,
        client,
      );
      const lesson = await this.database.findLesson(lessonId, client);
      const questions = await this.database.listPracticeQuestionsByLesson(
        lesson.id,
        {},
        client,
      );
      const questionsById = new Map(questions.map((q) => [q.id, q]));
      const accepted = [];
      const rejected = [];
      let earnedCoins = 0;
      let rewardedToday =
        await this.database.countRewardedPracticeSessionsToday(
          user.id,
          client,
        );

      for (const item of dto.items) {
        try {
          const normalized = this.normalizeSession(item, questionsById);
          const { session, created } =
            await this.database.createPracticeSessionIfAbsent(
              {
                ...normalized,
                id: item.id.trim(),
                userId: user.id,
                lessonId: lesson.id,
              },
              client,
            );
          if (!session) {
            throw new ConflictException("Practice session id belongs to another user");
          }

          let coins = 0;
          if (created && rewardedToday < DAILY_REWARDED_PRACTICE_SESSION_CAP) {
            coins = this.practiceCoins(
              normalized.correctCount,
              normalized.questionsAttempted,
            );
            const reward = await this.database.createRewardEvent(
              {
                userId: user.id,
                rewardType: "PRACTICE_SESSION",
                sourceType: "PRACTICE_SESSION",
                sourceId: item.id.trim(),
                rewardLevel: 0,
                coins,
                metadata: {
                  lessonId: lesson.id,
                  questionsAttempted: normalized.questionsAttempted,
                  correctCount: normalized.correctCount,
                },
              },
              client,
            );
            if (reward) {
              earnedCoins += reward.coins;
              rewardedToday++;
            }
          }

          accepted.push({
            id: item.id,
            lessonId: lesson.id,
            created,
            coinsEarned: coins,
            serverState: session,
          });
        } catch (error) {
          rejected.push({
            id: item.id,
            lessonId: lesson.id,
            reason: error instanceof Error ? error.message : "Sync item failed",
          });
        }
      }

      const updatedUser = await this.database.addCoins(user.id, earnedCoins, client);
      const newBadges = await this.awardPracticeBadges(user.id, client);

      return {
        syncedItems: accepted.length,
        accepted,
        rejected,
        earnedCoins,
        coinsEarned: earnedCoins,
        totalCoins: updatedUser.coins,
        newBadges,
      };
    });
  }

  private normalizeSession(
    item: SyncPracticeSessionItemDto,
    questionsById: Map<string, any>,
  ) {
    const answers = item.answers ?? [];
    if (answers.length > 0) {
      const seen = new Set<string>();
      const normalizedAnswers = answers.map((answer) => {
        if (seen.has(answer.questionId)) {
          throw new BadRequestException("Duplicate questionId in answers");
        }
        seen.add(answer.questionId);
        const question = questionsById.get(answer.questionId);
        if (!question) {
          throw new ConflictException("Practice question set has changed");
        }
        const isCorrect = answer.selectedOption === question.correctOption;
        return {
          questionId: answer.questionId,
          selectedOption: answer.selectedOption,
          isCorrect,
        };
      });
      return {
        questionsAttempted: normalizedAnswers.length,
        correctCount: normalizedAnswers.filter((answer) => answer.isCorrect)
          .length,
        answers: normalizedAnswers,
        startedAt: item.startedAt,
        completedAt: item.completedAt,
      };
    }

    const questionsAttempted = item.questionsAttempted ?? 0;
    const correctCount = item.correctCount ?? 0;
    if (questionsAttempted <= 0) {
      throw new BadRequestException("questionsAttempted must be greater than 0");
    }
    if (correctCount < 0 || correctCount > questionsAttempted) {
      throw new BadRequestException("correctCount is out of range");
    }
    return {
      questionsAttempted,
      correctCount,
      answers: [],
      startedAt: item.startedAt,
      completedAt: item.completedAt,
    };
  }

  private practiceCoins(correctCount: number, questionsAttempted: number) {
    const rate = questionsAttempted === 0 ? 0 : correctCount / questionsAttempted;
    if (rate >= 0.8) return 5;
    if (rate >= 0.5) return 3;
    return 2;
  }

  private async awardPracticeBadges(
    userId: string,
    client: Parameters<Parameters<DatabaseRepository["withTransaction"]>[0]>[0],
  ) {
    const awarded = [];
    const practiceCount = await this.database.countPracticeSessionsByUser(
      userId,
      client,
    );
    const countBadges = await this.database.listBadgesByRule(
      "practice_count",
      client,
    );
    for (const badge of countBadges) {
      const target = Number(badge.conditionValue ?? 0);
      if (target > 0 && practiceCount >= target) {
        const awardedBadge = await this.database.awardBadge(
          userId,
          badge.id,
          client,
        );
        if (awardedBadge) awarded.push(awardedBadge);
      }
    }

    const streak = await this.database.currentPracticeStreak(userId, client);
    const streakBadges = await this.database.listBadgesByRule(
      "practice_streak",
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

    return awarded;
  }
}
