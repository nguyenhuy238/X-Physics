import { Injectable } from '@nestjs/common';

@Injectable()
export class LessonsService {
  findOne(id: string) {
    return { id, title: 'TODO lesson', contentMarkdown: '# TODO' };
  }

  simulations(lessonId: string) {
    return [{ id: `sim-${lessonId}`, lessonId, expression: 'v * t' }];
  }

  questions(lessonId: string) {
    return [{ id: `${lessonId}-q1`, lessonId, question: 'TODO?' }];
  }
}
