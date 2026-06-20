import { Injectable } from '@nestjs/common';

import { SubmitQuizDto } from './dto/submit-quiz.dto';

@Injectable()
export class QuizService {
  submit(dto: SubmitQuizDto) {
    return {
      attemptId: 'TODO',
      lessonId: dto.lessonId,
      score: 0,
      correctCount: 0,
      totalQuestions: dto.answers.length,
      coinsEarned: 0,
      newBadges: [],
      review: [],
    };
  }

  myAttempts() {
    return [];
  }

  attempt(id: string) {
    return { id };
  }
}
