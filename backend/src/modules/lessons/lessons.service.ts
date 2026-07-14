import { Injectable } from "@nestjs/common";

import { DatabaseRepository } from "../../database/database.repository";

@Injectable()
export class LessonsService {
  constructor(private readonly database: DatabaseRepository) {}

  findOne(id: string) {
    return this.database.findLesson(id);
  }

  simulations(lessonId: string) {
    return this.database.listSimulationsByLesson(lessonId);
  }

  async questions(lessonId: string) {
    await this.database.findLesson(lessonId);
    const questions = await this.database.listQuestionsByLesson(lessonId);
    return questions.map(
      ({
        correctOption: _correctOption,
        explanation: _explanation,
        ...question
      }) => question,
    );
  }
}
