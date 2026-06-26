import { Injectable } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/current-user';
import { DatabaseRepository } from '../../database/database.repository';
import { SubmitQuizDto } from './dto/submit-quiz.dto';

@Injectable()
export class QuizService {
  constructor(private readonly database: DatabaseRepository) {}

  async submit(user: AuthenticatedUser, dto: SubmitQuizDto) {
    return this.database.withTransaction(async (client) => {
      const questions = await this.database.listQuestionsByLesson(
        dto.lessonId,
        client,
      );
      const answersByQuestion = new Map(
        dto.answers.map((answer) => [answer.questionId, answer.selectedOption]),
      );
      const correctCount = questions.filter(
        (question) => answersByQuestion.get(question.id) === question.correctOption,
      ).length;
      const totalQuestions = questions.length;
      const score =
        totalQuestions === 0 ? 0 : Number(((correctCount / totalQuestions) * 10).toFixed(2));
      const quizCoins = score === 10 ? 30 : score >= 8 ? 20 : score >= 6 ? 15 : 0;
      const completionCoins = 10;
      const coinsEarned = quizCoins + completionCoins;

      const attempt = await this.database.createQuizAttempt(
        {
          userId: user.id,
          lessonId: dto.lessonId,
          answers: dto.answers,
          score,
          correctCount,
          totalQuestions,
          coinsEarned,
        },
        client,
      );
      await this.database.upsertProgress(
        {
          userId: user.id,
          lessonId: dto.lessonId,
          status: 'COMPLETED',
          progressPercent: 100,
        },
        client,
      );
      await this.database.addCoins(user.id, coinsEarned, client);

      const newBadges = await this.awardBadges(user.id, dto.lessonId, score, client);
      return {
        attemptId: attempt.id,
        lessonId: dto.lessonId,
        score,
        correctCount,
        totalQuestions,
        coinsEarned,
        newBadges: newBadges.map((badge) => badge.name),
        review: questions.map((question) => ({
          questionId: question.id,
          correctOption: question.correctOption,
          selectedOption: answersByQuestion.get(question.id) ?? null,
          explanation: question.explanation,
        })),
      };
    });
  }

  myAttempts(user: AuthenticatedUser) {
    return this.database.listAttemptsByUser(user.id);
  }

  attempt(user: AuthenticatedUser, id: string) {
    return this.database.findAttempt(id, user.id);
  }

  private async awardBadges(
    userId: string,
    lessonId: string,
    score: number,
    client: Parameters<Parameters<DatabaseRepository['withTransaction']>[0]>[0],
  ) {
    const awarded = [];
    const completedLessons = await this.database.countCompletedLessons(userId, client);
    const totalLessons = await this.database.countTotalLessons(client);

    if (completedLessons >= 1) {
      const badge = await this.database.awardBadge(userId, 'starter', client);
      if (badge) awarded.push(badge);
    }
    if (score === 10) {
      const badge = await this.database.awardBadge(userId, 'perfect-score', client);
      if (badge) awarded.push(badge);
    }

    const lesson = await this.database.findLesson(lessonId);
    const chapterLessons = await this.database.countLessonsInChapter(
      lesson.chapterId,
      client,
    );
    const chapterCompleted = await this.database.countCompletedLessonsInChapter(
      userId,
      lesson.chapterId,
      client,
    );
    if (chapterLessons > 0 && chapterCompleted >= chapterLessons) {
      const chapterBadge = {
        motion: 'motion-master',
        electric: 'electric-master',
      }[lesson.chapterId];
      if (chapterBadge) {
        const badge = await this.database.awardBadge(userId, chapterBadge, client);
        if (badge) awarded.push(badge);
      }
    }

    if (totalLessons > 0 && completedLessons >= totalLessons) {
      const badge = await this.database.awardBadge(userId, 'scientist', client);
      if (badge) awarded.push(badge);
    }

    return awarded;
  }
}
