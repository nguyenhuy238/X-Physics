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

  users(query: {
    search?: string;
    sortBy?: string;
    sortOrder?: string;
    page?: number;
    limit?: number;
  }) {
    return this.database.adminUsers(query);
  }

  statistics() {
    return this.database.statistics();
  }

  chapters() {
    return this.database.adminChapters();
  }

  lessons() {
    return this.database.adminLessons();
  }

  questions() {
    return this.database.adminQuestions();
  }

  createChapter(dto: AdminChapterDto) {
    return this.database.createChapter(dto);
  }

  updateChapter(id: string, dto: AdminChapterDto) {
    return this.database.updateChapter(id, dto);
  }

  removeChapter(id: string) {
    return this.database.removeChapterWithLessonCheck(id);
  }

  createLesson(dto: AdminLessonDto) {
    return this.database.createLesson(dto);
  }

  updateLesson(id: string, dto: AdminLessonDto) {
    return this.database.updateLesson(id, dto);
  }

  removeLesson(id: string) {
    return this.database.softDeleteLesson(id);
  }

  createQuestion(dto: AdminQuestionDto) {
    return this.database.createQuestion(dto);
  }

  updateQuestion(id: string, dto: AdminQuestionDto) {
    return this.database.updateQuestion(id, dto);
  }

  removeQuestion(id: string) {
    return this.database.deleteQuestion(id);
  }
}
