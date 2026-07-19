import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";

import { DatabaseRepository } from "../../database/database.repository";
import { NotificationsService } from "../notifications/notifications.service";
import {
  AdminChapterDto,
  AdminFormulaSimulationDto,
  AdminLessonDto,
  AdminQuestionQueryDto,
  CreateAdminQuestionDto,
  QuestionDifficulty,
  ReorderAdminQuestionsDto,
  UpdateAdminQuestionDto,
  AdminQuizAttemptQueryDto,
  CreateAdminQuizAttemptDto,
  UpdateAdminQuizAttemptDto,
} from "./dto/admin-content.dto";
import { FormulaExpression } from "./formula-expression";

@Injectable()
export class AdminService {
  constructor(
    private readonly database: DatabaseRepository,
    private readonly notificationsService: NotificationsService,
  ) {}

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

  quizAttempts(query: AdminQuizAttemptQueryDto) {
    return this.database.adminListQuizAttempts(query);
  }

  quizAttempt(id: string) {
    return this.database.findAdminQuizAttempt(id);
  }

  createQuizAttempt(dto: CreateAdminQuizAttemptDto) {
    return this.database.createAdminQuizAttempt(dto);
  }

  updateQuizAttempt(id: string, dto: UpdateAdminQuizAttemptDto) {
    return this.database.updateAdminQuizAttempt(id, dto);
  }

  removeQuizAttempt(id: string) {
    return this.database.deleteAdminQuizAttempt(id);
  }

  userProgress(userId: string) {
    return this.database.adminUserProgress(userId);
  }

  async sendNotificationToUser(userId: string, title: string, message: string, type: string = 'INFO') {
    return this.notificationsService.createNotification(
      userId,
      type,
      title,
      message,
    );
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

  async createChapter(dto: AdminChapterDto) {
    const chapter = await this.database.createChapter(dto);
    await this.notificationsService.notifyAllStudents(
      "SYSTEM",
      "Chương học mới!",
      `Chương học "${chapter.title}" vừa được thêm vào. Bắt đầu học ngay nhé!`,
      { chapterId: chapter.id },
    );
    return chapter;
  }

  updateChapter(id: string, dto: AdminChapterDto) {
    return this.database.updateChapter(id, dto);
  }

  removeChapter(id: string) {
    return this.database.removeChapterWithLessonCheck(id);
  }

  createLesson(dto: AdminLessonDto) {
    return this.database.withTransaction(async (client) => {
      const lesson = await this.database.createLesson(dto, client);
      if (dto.simulation) {
        await this.saveLessonSimulation(lesson.id, dto.simulation, client);
      }
      const simulations = await this.database.listSimulationsByLesson(
        lesson.id,
        client,
      );

      await this.notificationsService.notifyAllStudents(
        "SYSTEM",
        "Bài học mới!",
        `Bài học "${lesson.title}" vừa được thêm vào. Vào học ngay thôi!`,
        { lessonId: lesson.id },
      );

      return { ...lesson, simulation: simulations[0] ?? null };
    });
  }

  updateLesson(id: string, dto: AdminLessonDto) {
    return this.database.withTransaction(async (client) => {
      const lesson = await this.database.updateLesson(id, dto, client);
      if (Object.prototype.hasOwnProperty.call(dto, "simulation")) {
        if (dto.simulation) {
          await this.saveLessonSimulation(id, dto.simulation, client);
        } else {
          await this.database.deleteFormulaSimulationsByLesson(id, client);
        }
      }
      const simulations = await this.database.listSimulationsByLesson(
        id,
        client,
      );
      return { ...lesson, simulation: simulations[0] ?? null };
    });
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
      const insertAt = this.clampInsertPosition(
        input.orderIndex,
        existing.length,
      );
      await this.database.upsertQuestion(
        {
          id,
          ...input,
          orderIndex: this.temporaryOrderIndex(existing),
        },
        client,
      );
      const ids = existing.map((question) => question.id);
      ids.splice(insertAt - 1, 0, id);
      await this.database.setQuestionOrder(input.lessonId, ids, client);
      
      const lesson = await this.database.findAdminLesson(input.lessonId, client);
      if (lesson) {
        await this.notificationsService.notifyAllStudents(
          "SYSTEM",
          "Câu hỏi ôn tập mới!",
          `Bài học "${lesson.title}" vừa cập nhật thêm câu hỏi quiz mới. Thử sức ngay!`,
          { lessonId: lesson.id },
        );
      }

      return this.database.findAdminQuestion(id, client);
    });
  }

  async updateQuestion(id: string, dto: UpdateAdminQuestionDto) {
    return this.database.withTransaction(async (client) => {
      const current = await this.database.findAdminQuestion(id, client);
      const input = await this.validateQuestionInput(dto, id, client);
      const oldLessonId = current.lessonId;
      const newLessonId = input.lessonId;
      const targetQuestions = (
        await this.database.listAdminQuestionsByLesson(newLessonId, client)
      ).filter((question) => question.id !== id);
      await this.database.updateQuestion(
        id,
        {
          ...input,
          orderIndex: this.temporaryOrderIndex(targetQuestions),
        },
        client,
      );

      if (oldLessonId !== newLessonId) {
        const oldIds = (
          await this.database.listAdminQuestionsByLesson(oldLessonId, client)
        )
          .filter((question) => question.id !== id)
          .map((question) => question.id);
        await this.database.setQuestionOrder(oldLessonId, oldIds, client);
      }

      const moveTo = this.clampInsertPosition(
        input.orderIndex,
        targetQuestions.length,
      );
      const newIds = targetQuestions.map((question) => question.id);
      newIds.splice(moveTo - 1, 0, id);
      await this.database.setQuestionOrder(newLessonId, newIds, client);
      return this.database.findAdminQuestion(id, client);
    });
  }

  async removeQuestion(id: string) {
    return this.database.withTransaction(async (client) => {
      const current = await this.database.findAdminQuestion(id, client);
      const result = await this.database.deleteQuestion(id, client);
      const ids = (
        await this.database.listAdminQuestionsByLesson(current.lessonId, client)
      ).map((question) => question.id);
      await this.database.setQuestionOrder(current.lessonId, ids, client);
      return result;
    });
  }

  async reorderQuestions(dto: ReorderAdminQuestionsDto) {
    return this.database.withTransaction(async (client) => {
      const lesson = await this.database.findAdminLesson(dto.lessonId, client);
      if (!lesson) {
        throw new NotFoundException("Lesson not found");
      }
      const ids = dto.questionIds.map((id) => id.trim()).filter(Boolean);
      if (ids.length === 0) {
        throw new BadRequestException("questionIds must not be empty");
      }
      if (new Set(ids).size !== ids.length) {
        throw new BadRequestException("questionIds must be unique");
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
        throw new BadRequestException(
          "questionIds is missing lesson questions",
        );
      }
      if (extra.length > 0) {
        throw new BadRequestException(
          "questionIds contains unknown or foreign questions",
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
      throw new NotFoundException("Lesson not found");
    }

    const questionText = dto.questionText.trim();
    const explanation = dto.explanation.trim();
    const options = dto.options.map((option) => option.trim());
    if (!questionText) {
      throw new BadRequestException("Question text is required");
    }
    if (!explanation) {
      throw new BadRequestException("Explanation is required");
    }
    if (options.length !== 4) {
      throw new BadRequestException("Question must have exactly 4 options");
    }
    if (options.some((option) => option.length === 0)) {
      throw new BadRequestException("Options must not be empty");
    }
    const normalizedOptions = new Set(
      options.map((option) => option.toLocaleLowerCase("vi-VN")),
    );
    if (normalizedOptions.size !== options.length) {
      throw new BadRequestException("Options must be unique");
    }
    if (dto.correctOption < 0 || dto.correctOption >= options.length) {
      throw new BadRequestException("Correct option is out of range");
    }
    if (dto.orderIndex < 1) {
      throw new BadRequestException(
        "Order index must be greater than or equal to 1",
      );
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

  private temporaryOrderIndex(questions: Array<{ orderIndex: number }>) {
    const minOrder = questions.reduce(
      (min, question) => Math.min(min, question.orderIndex),
      0,
    );
    return minOrder - 1;
  }

  private async saveLessonSimulation(
    lessonId: string,
    dto: AdminFormulaSimulationDto,
    db: Parameters<Parameters<DatabaseRepository["withTransaction"]>[0]>[0],
  ) {
    const input = this.validateFormulaSimulation(dto);
    const existing = await this.database.listSimulationsByLesson(lessonId, db);
    const existingFormulaSimulation = existing.find(
      (simulation) => simulation.type === "formula_simulation",
    );
    const id = existingFormulaSimulation?.id ?? `sim-${lessonId}`;
    return this.database.replaceLessonFormulaSimulation(
      {
        id,
        lessonId,
        ...input,
      },
      db,
    );
  }

  private validateFormulaSimulation(dto: AdminFormulaSimulationDto) {
    const title = dto.title.trim();
    const formula = dto.formula.trim();
    const expression = dto.result.expression.trim();
    const resultLabel = dto.result.label.trim();
    if (!title) {
      throw new BadRequestException("Simulation title is required");
    }
    if (!formula) {
      throw new BadRequestException("Simulation formula is required");
    }
    if (!resultLabel) {
      throw new BadRequestException("Result label is required");
    }
    if (!expression) {
      throw new BadRequestException("Expression is required");
    }
    if (dto.result.decimalPlaces < 0 || dto.result.decimalPlaces > 6) {
      throw new BadRequestException("decimalPlaces must be between 0 and 6");
    }

    const symbols = new Set<string>();
    const values = new Map<string, number>();
    const variables = dto.variables.map((variable, index) => {
      const symbol = variable.symbol.trim();
      if (!symbol) {
        throw new BadRequestException(
          `Variable ${index + 1} symbol is required`,
        );
      }
      if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(symbol)) {
        throw new BadRequestException(
          `Variable "${symbol}" symbol must start with a letter or underscore and contain only letters, numbers, or underscores`,
        );
      }
      if (symbols.has(symbol)) {
        throw new BadRequestException(
          `Variable symbol "${symbol}" is duplicated`,
        );
      }
      symbols.add(symbol);
      if (variable.min >= variable.max) {
        throw new BadRequestException(
          `Variable "${symbol}" min must be less than max`,
        );
      }
      if (variable.step <= 0) {
        throw new BadRequestException(
          `Variable "${symbol}" step must be greater than 0`,
        );
      }
      if (variable.default < variable.min || variable.default > variable.max) {
        throw new BadRequestException(
          `Variable "${symbol}" default must be within min and max`,
        );
      }
      values.set(symbol, variable.default);
      return {
        symbol,
        label: variable.label.trim(),
        unit: variable.unit.trim(),
        min: variable.min,
        max: variable.max,
        step: variable.step,
        default: variable.default,
        defaultValue: variable.default,
      };
    });
    const { usedSymbols } = FormulaExpression.validate(
      expression,
      symbols,
      values,
    );
    if (usedSymbols.size === 0) {
      throw new BadRequestException(
        "Expression must use at least one variable",
      );
    }
    return {
      title,
      formula,
      expression,
      variables,
      result: {
        symbol: dto.result.symbol.trim(),
        label: resultLabel,
        unit: dto.result.unit.trim(),
        expression,
        decimalPlaces: dto.result.decimalPlaces,
      },
    };
  }
}
