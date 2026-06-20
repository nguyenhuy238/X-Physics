import { Injectable } from '@nestjs/common';

@Injectable()
export class StatisticsService {
  overview() {
    return { activeStudents: 0, completedLessons: 0, quizAttempts: 0 };
  }
}
