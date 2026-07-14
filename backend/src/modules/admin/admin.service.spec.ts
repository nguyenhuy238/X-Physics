import {
  BadRequestException,
  NotFoundException,
  UnauthorizedException,
} from "@nestjs/common";
import { plainToInstance } from "class-transformer";
import { validate } from "class-validator";

import { AuthGuard } from "../../common/auth.guard";
import { RolesGuard } from "../../common/roles.guard";
import { AdminService } from "./admin.service";
import {
  AdminQuestionQueryDto,
  CreateAdminQuestionDto,
} from "./dto/admin-content.dto";
import { LessonsService } from "../lessons/lessons.service";

class FakeAdminDatabase {
  lessons = new Map([
    ["lesson-1", { id: "lesson-1", chapterId: "chapter-1", isPublished: true }],
    ["lesson-2", { id: "lesson-2", chapterId: "chapter-2", isPublished: true }],
  ]);

  questions = new Map<string, any>([
    [
      "q1",
      this.makeQuestion({
        id: "q1",
        lessonId: "lesson-1",
        questionText: "Ohm law?",
        difficulty: "EASY",
        orderIndex: 1,
      }),
    ],
    [
      "q2",
      this.makeQuestion({
        id: "q2",
        lessonId: "lesson-2",
        questionText: "Pressure formula?",
        difficulty: "HARD",
        orderIndex: 1,
      }),
    ],
  ]);

  async withTransaction<T>(work: (client: this) => Promise<T>) {
    const snapshot = new Map(this.questions);
    try {
      return await work(this);
    } catch (error) {
      this.questions = snapshot;
      throw error;
    }
  }

  private makeQuestion(input: Partial<any>) {
    const lessonId = input.lessonId ?? "lesson-1";
    return {
      id: input.id ?? "q-new",
      lessonId,
      lessonTitle: lessonId === "lesson-1" ? "Ohm" : "Pressure",
      chapterId: lessonId === "lesson-1" ? "chapter-1" : "chapter-2",
      chapterTitle: lessonId === "lesson-1" ? "Electric" : "Force",
      question: input.questionText ?? "Question text",
      questionText: input.questionText ?? "Question text",
      options: input.options ?? ["A", "B", "C", "D"],
      correctOption: input.correctOption ?? 0,
      explanation: input.explanation ?? "Explanation text",
      difficulty: input.difficulty ?? "MEDIUM",
      orderIndex: input.orderIndex ?? 0,
    };
  }

  adminListQuestions(query: AdminQuestionQueryDto) {
    let items = Array.from(this.questions.values());
    if (query.lessonId) {
      items = items.filter((item) => item.lessonId === query.lessonId);
    }
    if (query.chapterId) {
      items = items.filter((item) => item.chapterId === query.chapterId);
    }
    if (query.search) {
      items = items.filter((item) =>
        item.questionText.toLowerCase().includes(query.search!.toLowerCase()),
      );
    }
    if (query.difficulty) {
      items = items.filter((item) => item.difficulty === query.difficulty);
    }
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const total = items.length;
    return {
      items: items.slice((page - 1) * limit, page * limit),
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findAdminQuestion(id: string) {
    const question = this.questions.get(id);
    if (!question) throw new NotFoundException("Question not found");
    return question;
  }

  async findAdminLesson(id: string) {
    return this.lessons.get(id) ?? null;
  }

  async questionOrderIndexExists(input: {
    lessonId: string;
    orderIndex: number;
    excludeQuestionId?: string;
  }) {
    return Array.from(this.questions.values()).some(
      (question) =>
        question.lessonId === input.lessonId &&
        question.orderIndex === input.orderIndex &&
        question.id !== input.excludeQuestionId,
    );
  }

  async listAdminQuestionsByLesson(lessonId: string) {
    return Array.from(this.questions.values())
      .filter((question) => question.lessonId === lessonId)
      .sort((a, b) => a.orderIndex - b.orderIndex);
  }

  async upsertQuestion(input: any) {
    const question = this.makeQuestion({ ...input, questionText: input.questionText });
    this.questions.set(question.id, question);
    return question;
  }

  async updateQuestion(id: string, input: any) {
    if (!this.questions.has(id)) throw new NotFoundException("Question not found");
    const question = this.makeQuestion({ id, ...input });
    this.questions.set(id, question);
    return question;
  }

  async deleteQuestion(id: string) {
    if (!this.questions.delete(id)) throw new NotFoundException("Question not found");
    return { id, deleted: true, mode: "hard" };
  }

  async setQuestionOrder(lessonId: string, questionIds: string[]) {
    questionIds.forEach((id, index) => {
      const question = this.questions.get(id);
      if (question && question.lessonId === lessonId) {
        question.orderIndex = index + 1;
      }
    });
    return questionIds.map((id, index) => ({ id, orderIndex: index + 1 }));
  }

  async findLesson(id: string) {
    const lesson = this.lessons.get(id);
    if (!lesson) throw new NotFoundException("Lesson not found");
    return lesson;
  }

  async listQuestionsByLesson(lessonId: string) {
    return Array.from(this.questions.values()).filter(
      (question) => question.lessonId === lessonId,
    );
  }
}

const validQuestionDto: CreateAdminQuestionDto = {
  lessonId: "lesson-1",
  questionText: "What is voltage?",
  options: ["A", "B", "C", "D"],
  correctOption: 0,
  explanation: "Voltage is electric potential difference.",
  difficulty: "MEDIUM" as any,
  orderIndex: 2,
};

describe("AdminService questions", () => {
  let database: FakeAdminDatabase;
  let service: AdminService;

  beforeEach(() => {
    database = new FakeAdminDatabase();
    service = new AdminService(database as any);
  });

  it("lists questions with filter and pagination metadata", async () => {
    const result = await service.questions({
      lessonId: "lesson-1",
      search: "ohm",
      page: 1,
      limit: 10,
    });

    expect(result.items).toHaveLength(1);
    expect(result.items[0]).toMatchObject({
      id: "q1",
      lessonId: "lesson-1",
      chapterId: "chapter-1",
    });
    expect(result.total).toBe(1);
  });

  it("filters questions by chapter and difficulty", async () => {
    const result = await service.questions({
      chapterId: "chapter-2",
      difficulty: "HARD" as any,
    });

    expect(result.items.map((item) => item.id)).toEqual(["q2"]);
  });

  it("returns question detail with lesson and chapter information", async () => {
    await expect(service.question("q1")).resolves.toMatchObject({
      lessonTitle: "Ohm",
      chapterTitle: "Electric",
    });
  });

  it("creates a valid question with default difficulty", async () => {
    const created = await service.createQuestion({
      ...validQuestionDto,
      difficulty: undefined,
    });

    expect(created.id).toBeTruthy();
    expect(created.difficulty).toBe("MEDIUM");
  });

  it("creates at the beginning, middle, end, and clamps beyond the end", async () => {
    const atBeginning = await service.createQuestion({
      ...validQuestionDto,
      questionText: "At beginning",
      orderIndex: 1,
    });
    expect(
      (await database.listAdminQuestionsByLesson("lesson-1")).map((q) => q.id),
    ).toEqual([atBeginning.id, "q1"]);

    const inMiddle = await service.createQuestion({
      ...validQuestionDto,
      questionText: "In middle",
      orderIndex: 2,
    });
    expect(
      (await database.listAdminQuestionsByLesson("lesson-1")).map((q) => q.id),
    ).toEqual([atBeginning.id, inMiddle.id, "q1"]);

    const beyondEnd = await service.createQuestion({
      ...validQuestionDto,
      questionText: "Beyond end",
      orderIndex: 99,
    });
    expect(
      (await database.listAdminQuestionsByLesson("lesson-1")).map((q) => q.id),
    ).toEqual([atBeginning.id, inMiddle.id, "q1", beyondEnd.id]);
  });

  it("updates a valid question", async () => {
    const updated = await service.updateQuestion("q1", {
      ...validQuestionDto,
      orderIndex: 3,
    });

    expect(updated.questionText).toBe("What is voltage?");
    expect(updated.orderIndex).toBe(1);
  });

  it("moves a question up and down while keeping compact order", async () => {
    const q3 = await service.createQuestion({
      ...validQuestionDto,
      questionText: "Third",
      orderIndex: 2,
    });

    await service.updateQuestion("q1", {
      ...validQuestionDto,
      orderIndex: 2,
    });
    expect(
      (await database.listAdminQuestionsByLesson("lesson-1")).map((q) => q.id),
    ).toEqual([q3.id, "q1"]);

    await service.updateQuestion(q3.id, {
      ...validQuestionDto,
      questionText: "Third",
      orderIndex: 2,
    });
    expect(
      (await database.listAdminQuestionsByLesson("lesson-1")).map((q) => q.id),
    ).toEqual(["q1", q3.id]);
  });

  it("deletes an existing question", async () => {
    await expect(service.removeQuestion("q1")).resolves.toEqual({
      id: "q1",
      deleted: true,
      mode: "hard",
    });
  });

  it("compacts order after delete", async () => {
    const created = await service.createQuestion({
      ...validQuestionDto,
      questionText: "Second",
      orderIndex: 2,
    });
    await service.removeQuestion("q1");

    expect(await database.listAdminQuestionsByLesson("lesson-1")).toMatchObject([
      { id: created.id, orderIndex: 1 },
    ]);
  });

  it("reorders a full lesson successfully", async () => {
    const created = await service.createQuestion({
      ...validQuestionDto,
      questionText: "Second",
      orderIndex: 2,
    });
    const result = await service.reorderQuestions({
      lessonId: "lesson-1",
      questionIds: [created.id, "q1"],
    });

    expect(result.items).toEqual([
      { id: created.id, orderIndex: 1 },
      { id: "q1", orderIndex: 2 },
    ]);
  });

  it("rejects reorder duplicate, missing, extra, foreign, and missing lesson", async () => {
    await expect(
      service.reorderQuestions({ lessonId: "lesson-1", questionIds: ["q1", "q1"] }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.reorderQuestions({ lessonId: "lesson-1", questionIds: [] }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.reorderQuestions({ lessonId: "lesson-1", questionIds: ["q1", "extra"] }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.reorderQuestions({ lessonId: "lesson-1", questionIds: ["q2"] }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.reorderQuestions({ lessonId: "missing", questionIds: ["q1"] }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it("returns 404 when lesson does not exist", async () => {
    await expect(
      service.createQuestion({ ...validQuestionDto, lessonId: "missing" }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it("returns 404 when question does not exist", async () => {
    await expect(service.question("missing")).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await expect(
      service.updateQuestion("missing", validQuestionDto as any),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(service.removeQuestion("missing")).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it("rejects empty question text, explanation, option, duplicate option, bad correct option, and negative order", async () => {
    await expect(
      service.createQuestion({ ...validQuestionDto, questionText: "   " }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.createQuestion({ ...validQuestionDto, explanation: "   " }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.createQuestion({ ...validQuestionDto, options: ["A", "", "C", "D"] }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.createQuestion({ ...validQuestionDto, options: ["A", "a", "C", "D"] }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.createQuestion({ ...validQuestionDto, correctOption: 4 }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.createQuestion({ ...validQuestionDto, orderIndex: -1 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it("keeps student lesson questions sanitized", async () => {
    const lessons = new LessonsService(database as any);
    const [question] = await lessons.questions("lesson-1");

    expect(question).not.toHaveProperty("correctOption");
    expect(question).not.toHaveProperty("explanation");
  });
});

describe("AdminQuestionDto validation", () => {
  it("rejects missing, too few, too many, empty, and invalid difficulty fields", async () => {
    const invalidInputs = [
      { ...validQuestionDto, options: ["A", "B", "C"] },
      { ...validQuestionDto, options: ["A", "B", "C", "D", "E"] },
      { ...validQuestionDto, questionText: "" },
      { ...validQuestionDto, explanation: "" },
      { ...validQuestionDto, difficulty: "NORMAL" },
      { ...validQuestionDto, orderIndex: -1 },
    ];

    for (const input of invalidInputs) {
      const dto = plainToInstance(CreateAdminQuestionDto, input);
      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
    }
  });
});

describe("Admin auth and roles", () => {
  function contextFor(input: { authorization?: string; user?: any }) {
    return {
      switchToHttp: () => ({
        getRequest: () => ({
          headers: { authorization: input.authorization },
          user: input.user,
        }),
      }),
      getHandler: () => ({}),
      getClass: () => ({}),
    } as any;
  }

  it("returns 401 when token is missing", async () => {
    const guard = new AuthGuard({} as any, {
      get: () => "secret",
    } as any);

    await expect(guard.canActivate(contextFor({}))).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it("returns 403 for STUDENT and allows ADMIN or TEACHER", () => {
    const reflector = {
      getAllAndOverride: () => ["ADMIN", "TEACHER"],
    };
    const guard = new RolesGuard(reflector as any);

    expect(() =>
      guard.canActivate(contextFor({ user: { role: "STUDENT" } })),
    ).toThrow("Insufficient role");
    expect(
      guard.canActivate(contextFor({ user: { role: "ADMIN" } })),
    ).toBe(true);
    expect(
      guard.canActivate(contextFor({ user: { role: "TEACHER" } })),
    ).toBe(true);
  });
});
