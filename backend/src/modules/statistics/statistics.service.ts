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
      activeTrend: statistics.activeTrend,
      completionByChapter: statistics.completionByChapter,
      completionByLesson: statistics.completionByLesson,
      difficultLessons: statistics.difficultLessons,
    };
  }
}
