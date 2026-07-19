import { BadRequestException, ConflictException, Injectable } from "@nestjs/common";

import { AuthenticatedUser } from "../../common/current-user";
import { DatabaseRepository } from "../../database/database.repository";
import { NotificationsService } from "../notifications/notifications.service";
import { SubmitQuizDto } from "./dto/submit-quiz.dto";

const MAX_DURATION_SECONDS = 3600;

@Injectable()
export class QuizService {
  constructor(
    private readonly database: DatabaseRepository,
    private readonly notificationsService: NotificationsService,
  ) {}

  async submit(user: AuthenticatedUser, dto: SubmitQuizDto) {
    return this.database.withTransaction(async (client) => {
      await this.database.lockRewardScope(
        user.id,
        "LESSON",
        dto.lessonId,
        client,
      );

      const lesson = await this.database.findLesson(dto.lessonId, client);
      const questions = await this.database.listQuestionsByLesson(
        lesson.id,
        client,
      );
      this.validateSubmitPayload(dto, questions);

      const answersByQuestion = new Map(
        dto.answers.map((answer) => [answer.questionId, answer.selectedOption]),
      );
      const correctCount = questions.filter(
        (question) =>
          answersByQuestion.get(question.id) === question.correctOption,
      ).length;
      const totalQuestions = questions.length;
      const score = Number(((correctCount / totalQuestions) * 10).toFixed(2));
      const perfectScore = correctCount === totalQuestions;
      const review = questions.map((question) => {
        const selectedOption = answersByQuestion.get(question.id) ?? null;
        return {
          questionId: question.id,
          question: question.question,
          options: question.options,
          selectedOption,
          correctOption: question.correctOption,
          isCorrect: selectedOption === question.correctOption,
          explanation: question.explanation,
        };
      });

      const previousProgress = await this.database.findProgressForLesson(
        user.id,
        lesson.id,
        client,
      );

      const lessonCoins = await this.createLessonCompletionReward(
        user.id,
        lesson.id,
        client,
      );
      const quizCoins = await this.createQuizScoreReward(
        user.id,
        lesson.id,
        score,
        perfectScore,
        client,
      );

      const attempt = await this.database.createQuizAttempt(
        {
          userId: user.id,
          lessonId: lesson.id,
          answers: dto.answers,
          score,
          correctCount,
          totalQuestions,
          durationSeconds: dto.durationSeconds,
          coinsEarned: lessonCoins + quizCoins,
          review,
        },
        client,
      );

      await this.database.upsertProgress(
        {
          userId: user.id,
          lessonId: lesson.id,
          status: "COMPLETED",
          progressPercent: 100,
          latestQuizScore: score,
          bestQuizScore: Math.max(previousProgress?.bestQuizScore ?? 0, score),
        },
        client,
      );

      await this.database.recordLearningActivity(
        user.id,
        { sourceType: "QUIZ_SUBMIT", sourceId: attempt.id },
        client,
      );

      const chapterCoins = await this.createChapterCompletionReward(
        user.id,
        lesson.chapterId,
        client,
      );
      const earnedCoins = lessonCoins + quizCoins + chapterCoins;
      const updatedUser = await this.database.addCoins(
        user.id,
        earnedCoins,
        client,
      );

      const newBadges = await this.notificationsService.awardBadgesAndNotify(
        user.id,
        lesson.id,
        lesson.chapterId,
        perfectScore,
        client,
      );

      return {
        attemptId: attempt.id,
        lessonId: lesson.id,
        score,
        correctCount,
        totalQuestions,
        durationSeconds: dto.durationSeconds,
        earnedCoins,
        coinsEarned: earnedCoins,
        totalCoins: updatedUser.coins,
        newBadges,
        review,
      };
    });
  }

  myAttempts(user: AuthenticatedUser) {
    return this.database.listAttemptsByUser(user.id);
  }

  attempt(user: AuthenticatedUser, id: string) {
    return this.database.findAttempt(id, user.id);
  }

  private validateSubmitPayload(
    dto: SubmitQuizDto,
    questions: Array<{
      id: string;
      lessonId: string;
      options: unknown;
    }>,
  ) {
    if (dto.durationSeconds > MAX_DURATION_SECONDS) {
      throw new BadRequestException("durationSeconds is too large");
    }
    if (questions.length === 0) {
      throw new BadRequestException("Lesson has no quiz questions");
    }
    if (!Array.isArray(dto.answers) || dto.answers.length === 0) {
      throw new BadRequestException("answers must be a non-empty array");
    }
    const questionsById = new Map(
      questions.map((question) => [question.id, question]),
    );
    const seenQuestionIds = new Set<string>();

    for (const answer of dto.answers) {
      if (
        !Number.isInteger(answer.selectedOption) ||
        answer.selectedOption < 0
      ) {
        throw new BadRequestException(
          "selectedOption must be a non-negative integer",
        );
      }
      if (seenQuestionIds.has(answer.questionId)) {
        throw new BadRequestException("Duplicate questionId in answers");
      }
      seenQuestionIds.add(answer.questionId);

      const question = questionsById.get(answer.questionId);
      if (!question) {
        throw new ConflictException(
          "B? c�u h?i d� du?c c?p nh?t. Vui l�ng t?i l?i quiz.",
        );
      }
      const options = Array.isArray(question.options) ? question.options : [];
      if (answer.selectedOption >= options.length) {
        throw new BadRequestException("selectedOption is out of range");
      }
    }

    for (const question of questions) {
      if (!seenQuestionIds.has(question.id)) {
        throw new ConflictException(
          "B? c�u h?i d� du?c c?p nh?t. Vui l�ng t?i l?i quiz.",
        );
      }
    }
    if (dto.answers.length !== questions.length) {
      throw new ConflictException(
        "B? c�u h?i d� du?c c?p nh?t. Vui l�ng t?i l?i quiz.",
      );
    }
  }

  private quizRewardLevel(score: number, perfectScore: boolean) {
    if (perfectScore) return 30;
    if (score >= 8) return 20;
    if (score >= 6) return 15;
    return 0;
  }

  private async createLessonCompletionReward(
    userId: string,
    lessonId: string,
    client: Parameters<Parameters<DatabaseRepository["withTransaction"]>[0]>[0],
  ) {
    const event = await this.database.createRewardEvent(
      {
        userId,
        rewardType: "LESSON_COMPLETE",
        sourceType: "LESSON",
        sourceId: lessonId,
        rewardLevel: 0,
        coins: 10,
      },
      client,
    );
    return event?.coins ?? 0;
  }

  private async createQuizScoreReward(
    userId: string,
    lessonId: string,
    score: number,
    perfectScore: boolean,
    client: Parameters<Parameters<DatabaseRepository["withTransaction"]>[0]>[0],
  ) {
    const rewardLevel = this.quizRewardLevel(score, perfectScore);
    if (rewardLevel === 0) {
      return 0;
    }
    const previousLevel = await this.database.maxRewardLevel(
      userId,
      "QUIZ_SCORE",
      "LESSON",
      lessonId,
      client,
    );
    const deltaCoins = Math.max(0, rewardLevel - previousLevel);
    if (deltaCoins === 0) {
      return 0;
    }
    const event = await this.database.createRewardEvent(
      {
        userId,
        rewardType: "QUIZ_SCORE",
        sourceType: "LESSON",
        sourceId: lessonId,
        rewardLevel,
        coins: deltaCoins,
        metadata: { score, previousLevel },
      },
      client,
    );
    return event?.coins ?? 0;
  }

  private async createChapterCompletionReward(
    userId: string,
    chapterId: string,
    client: Parameters<Parameters<DatabaseRepository["withTransaction"]>[0]>[0],
  ) {
    await this.database.lockRewardScope(userId, "CHAPTER", chapterId, client);
    const [chapterLessons, chapterCompleted] = await Promise.all([
      this.database.countLessonsInChapter(chapterId, client),
      this.database.countCompletedLessonsInChapter(userId, chapterId, client),
    ]);
    if (chapterLessons === 0 || chapterCompleted < chapterLessons) {
      return 0;
    }
    const event = await this.database.createRewardEvent(
      {
        userId,
        rewardType: "CHAPTER_COMPLETE",
        sourceType: "CHAPTER",
        sourceId: chapterId,
        rewardLevel: 0,
        coins: 50,
      },
      client,
    );
    return event?.coins ?? 0;
  }
}
