import { Injectable } from '@nestjs/common';

import { DatabaseRepository } from '../../database/database.repository';

@Injectable()
export class LessonsService {
  constructor(private readonly database: DatabaseRepository) {}

  findOne(id: string) {
    return this.database.findLesson(id);
  }

  simulations(lessonId: string) {
    return this.database.listSimulationsByLesson(lessonId);
  }

  questions(lessonId: string) {
    return this.database.listQuestionsByLesson(lessonId).then((questions) =>
      questions.map(({ correctOption: _correctOption, ...question }) => question),
    );
  }
}
