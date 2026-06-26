import { Injectable } from '@nestjs/common';

import { DatabaseRepository } from '../../database/database.repository';

@Injectable()
export class StatisticsService {
  constructor(private readonly database: DatabaseRepository) {}

  async overview() {
    const statistics = await this.database.statistics();
    return {
      activeStudents: statistics.totalUsers,
      completedLessons: statistics.completionRate,
      quizAttempts: statistics.totalAttempts,
    };
  }
}
