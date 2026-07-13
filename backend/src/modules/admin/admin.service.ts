import { Injectable } from '@nestjs/common';

import { DatabaseRepository } from '../../database/database.repository';
import {
  AdminChapterDto,
  AdminLessonDto,
  AdminQuestionDto,
} from './dto/admin-content.dto';

@Injectable()
export class AdminService {
  constructor(private readonly database: DatabaseRepository) {}

  users() {
    return this.database.adminUsers();
  }

  statistics() {
    return this.database.statistics();
  }

  chapters() {
    return this.database.adminListChapters();
  }

  lessons() {
    return this.database.adminListLessons();
  }

  questions() {
    return this.database.adminListQuestions();
  }

  createChapter(dto: AdminChapterDto) {
    return this.database.upsertChapter(dto);
  }

  updateChapter(id: string, dto: AdminChapterDto) {
    return this.database.updateChapter(id, dto);
  }

  removeChapter(id: string) {
    return this.database.softDeleteChapter(id);
  }

  createLesson(dto: AdminLessonDto) {
    return this.database.upsertLesson(dto);
  }

  updateLesson(id: string, dto: AdminLessonDto) {
    return this.database.updateLesson(id, dto);
  }

  removeLesson(id: string) {
    return this.database.softDeleteLesson(id);
  }

  createQuestion(dto: AdminQuestionDto) {
    return this.database.upsertQuestion(dto);
  }

  updateQuestion(id: string, dto: AdminQuestionDto) {
    return this.database.updateQuestion(id, dto);
  }

  removeQuestion(id: string) {
    return this.database.deleteQuestion(id);
  }
}
