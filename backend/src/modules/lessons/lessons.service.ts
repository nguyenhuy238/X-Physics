import { Injectable } from "@nestjs/common";

import { DatabaseRepository } from "../../database/database.repository";

@Injectable()
export class LessonsService {
  constructor(private readonly database: DatabaseRepository) {}

  async findOne(id: string) {
    const lesson = await this.database.findLesson(id);
    const simulations = await this.database.listSimulationsByLesson(id);
    return {
      ...lesson,
      simulation: simulations[0] ?? null,
      simulations,
    };
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
