import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';

import { DatabaseRepository } from '../../database/database.repository';
import {
  AdminChapterDto,
  AdminLessonDto,
  AdminQuestionQueryDto,
  CreateAdminQuestionDto,
  QuestionDifficulty,
  ReorderAdminQuestionsDto,
  UpdateAdminQuestionDto,
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
    return this.database.adminListChapters();
  }

  lessons() {
    return this.database.adminLessons();
  }

  questions(query: AdminQuestionQueryDto = {}) {
    return this.database.adminListQuestions({
      lessonId: query.lessonId,
      chapterId: query.chapterId,
      search: query.search,
      difficulty: query.difficulty,
      page: query.page,
      limit: query.limit,
    });
  }

  question(id: string) {
    return this.database.findAdminQuestion(id);
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

  async createQuestion(dto: CreateAdminQuestionDto) {
    return this.database.withTransaction(async (client) => {
      const input = await this.validateQuestionInput(dto, undefined, client);
      const existing = await this.database.listAdminQuestionsByLesson(
        input.lessonId,
        client,
      );
      const id = randomUUID();
      const insertAt = this.clampInsertPosition(input.orderIndex, existing.length);
      await this.database.upsertQuestion(
        {
          id,
          ...input,
          orderIndex: 0,
        },
        client,
      );
      const ids = existing.map((question) => question.id);
      ids.splice(insertAt - 1, 0, id);
      await this.database.setQuestionOrder(input.lessonId, ids, client);
      return this.database.findAdminQuestion(id, client);
    });
  }

  async updateQuestion(id: string, dto: UpdateAdminQuestionDto) {
    return this.database.withTransaction(async (client) => {
      const current = await this.database.findAdminQuestion(id, client);
      const input = await this.validateQuestionInput(dto, id, client);
      const oldLessonId = current.lessonId;
      const newLessonId = input.lessonId;
      await this.database.updateQuestion(
        id,
        {
          ...input,
          orderIndex: 0,
        },
        client,
      );

      if (oldLessonId !== newLessonId) {
        const oldIds = (await this.database.listAdminQuestionsByLesson(
          oldLessonId,
          client,
        ))
          .filter((question) => question.id !== id)
          .map((question) => question.id);
        await this.database.setQuestionOrder(oldLessonId, oldIds, client);
      }

      const newQuestions = (await this.database.listAdminQuestionsByLesson(
        newLessonId,
        client,
      )).filter((question) => question.id !== id);
      const moveTo = this.clampInsertPosition(input.orderIndex, newQuestions.length);
      const newIds = newQuestions.map((question) => question.id);
      newIds.splice(moveTo - 1, 0, id);
      await this.database.setQuestionOrder(newLessonId, newIds, client);
      return this.database.findAdminQuestion(id, client);
    });
  }

  async removeQuestion(id: string) {
    return this.database.withTransaction(async (client) => {
      const current = await this.database.findAdminQuestion(id, client);
      const result = await this.database.deleteQuestion(id, client);
      const ids = (await this.database.listAdminQuestionsByLesson(
        current.lessonId,
        client,
      )).map((question) => question.id);
      await this.database.setQuestionOrder(current.lessonId, ids, client);
      return result;
    });
  }

  async reorderQuestions(dto: ReorderAdminQuestionsDto) {
    return this.database.withTransaction(async (client) => {
      const lesson = await this.database.findAdminLesson(dto.lessonId, client);
      if (!lesson) {
        throw new NotFoundException('Lesson not found');
      }
      const ids = dto.questionIds.map((id) => id.trim()).filter(Boolean);
      if (ids.length === 0) {
        throw new BadRequestException('questionIds must not be empty');
      }
      if (new Set(ids).size !== ids.length) {
        throw new BadRequestException('questionIds must be unique');
      }
      const existing = await this.database.listAdminQuestionsByLesson(
        dto.lessonId,
        client,
      );
      const existingIds = existing.map((question) => question.id);
      const existingSet = new Set(existingIds);
      const submittedSet = new Set(ids);
      const missing = existingIds.filter((id) => !submittedSet.has(id));
      const extra = ids.filter((id) => !existingSet.has(id));
      if (missing.length > 0) {
        throw new BadRequestException('questionIds is missing lesson questions');
      }
      if (extra.length > 0) {
        throw new BadRequestException(
          'questionIds contains unknown or foreign questions',
        );
      }
      const items = await this.database.setQuestionOrder(
        dto.lessonId,
        ids,
        client,
      );
      return { lessonId: dto.lessonId, items };
    });
  }

  private async validateQuestionInput(
    dto: CreateAdminQuestionDto | UpdateAdminQuestionDto,
    questionId?: string,
    db?: Parameters<Parameters<DatabaseRepository["withTransaction"]>[0]>[0],
  ) {
    const lesson = await this.database.findAdminLesson(dto.lessonId, db);
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    const questionText = dto.questionText.trim();
    const explanation = dto.explanation.trim();
    const options = dto.options.map((option) => option.trim());
    if (!questionText) {
      throw new BadRequestException('Question text is required');
    }
    if (!explanation) {
      throw new BadRequestException('Explanation is required');
    }
    if (options.length !== 4) {
      throw new BadRequestException('Question must have exactly 4 options');
    }
    if (options.some((option) => option.length === 0)) {
      throw new BadRequestException('Options must not be empty');
    }
    const normalizedOptions = new Set(
      options.map((option) => option.toLocaleLowerCase('vi-VN')),
    );
    if (normalizedOptions.size !== options.length) {
      throw new BadRequestException('Options must be unique');
    }
    if (dto.correctOption < 0 || dto.correctOption >= options.length) {
      throw new BadRequestException('Correct option is out of range');
    }
    if (dto.orderIndex < 1) {
      throw new BadRequestException('Order index must be greater than or equal to 1');
    }

    return {
      lessonId: dto.lessonId,
      questionText,
      options,
      correctOption: dto.correctOption,
      explanation,
      difficulty: dto.difficulty ?? QuestionDifficulty.MEDIUM,
      orderIndex: dto.orderIndex,
    };
  }

  private clampInsertPosition(orderIndex: number, existingLength: number) {
    if (orderIndex < 1) return 1;
    return Math.min(orderIndex, existingLength + 1);
  }
}
