import { Injectable } from '@nestjs/common';

import { DatabaseRepository } from '../../database/database.repository';

@Injectable()
export class StatisticsService {
  constructor(private readonly database: DatabaseRepository) {}

  async overview() {
    const statistics = await this.database.statistics();
    return {
      activeStudents: statistics.activeStudents,
      totalUsers: statistics.totalUsers,
      totalAttempts: statistics.totalAttempts,
      completionRate: statistics.completionRate,
      totalBadgesAwarded: statistics.totalBadgesAwarded,
      activeUsers7Days: statistics.activeUsers7Days,
      activeUsers30Days: statistics.activeUsers30Days,
      newUsersThisWeek: statistics.newUsersThisWeek,
      newUsersGrowth: statistics.newUsersGrowth,
      attemptsThisWeek: statistics.attemptsThisWeek,
      attemptsGrowth: statistics.attemptsGrowth,
      completionsThisWeek: statistics.completionsThisWeek,
      completionsGrowth: statistics.completionsGrowth,
      retentionRate: statistics.retentionRate,
      averageStudyTime: statistics.averageStudyTime,
      mostViewedLessons: statistics.mostViewedLessons,
      leastViewedLessons: statistics.leastViewedLessons,
      lessonsWithoutQuiz: statistics.lessonsWithoutQuiz,
      completionByChapter: statistics.completionByChapter,
      averageScore: statistics.averageScore,
      difficultQuestions: statistics.difficultQuestions,
      quizAttemptsTrend: statistics.quizAttemptsTrend,
    };
  }
}
