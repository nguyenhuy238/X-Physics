import { Inject, Injectable, NotFoundException } from "@nestjs/common";
import { Pool, PoolClient } from "pg";

import { DATABASE_POOL } from "./database.constants";

type Db = Pool | PoolClient;

interface UserRow {
  id: string;
  name: string;
  email: string;
  password_hash: string;
  role: "STUDENT" | "TEACHER" | "ADMIN";
  coins: number;
  refresh_token_hash: string | null;
  refresh_token_expires_at: Date | null;
}

interface ChapterRow {
  id: string;
  title: string;
  description: string;
  order_index: number;
  is_published: boolean;
  lesson_count?: string;
}

interface LessonRow {
  id: string;
  chapter_id: string;
  title: string;
  content_markdown: string;
  formula_latex: string | null;
  estimated_minutes: number;
  order_index: number;
  is_published: boolean;
  created_at: Date;
  updated_at: Date;
}

interface SimulationRow {
  id: string;
  lesson_id: string;
  title: string;
  formula: string;
  expression: string;
  variables_json: unknown;
  result_json: unknown;
}

interface QuestionRow {
  id: string;
  lesson_id: string;
  question_text: string;
  options_json: unknown;
  correct_option: number;
  explanation: string;
  difficulty: "EASY" | "MEDIUM" | "HARD";
  order_index: number;
}

interface AdminQuestionRow extends QuestionRow {
  lesson_title: string;
  chapter_id: string;
  chapter_title: string;
}

interface BadgeRow {
  id: string;
  name: string;
  description: string;
  icon: string | null;
  rule_key: string;
  condition_value: string | null;
  metadata_json: unknown;
  awarded_at?: Date;
}

interface AttemptRow {
  id: string;
  user_id: string;
  lesson_id: string;
  answers_json: unknown;
  review_json: unknown | null;
  score: string;
  correct_count: number;
  total_questions: number;
  duration_seconds: number;
  coins_earned: number;
  created_at: Date;
  lesson_title?: string;
  chapter_id?: string;
}

interface ProgressRow {
  id: string;
  user_id: string;
  lesson_id: string;
  status: "NOT_STARTED" | "IN_PROGRESS" | "COMPLETED";
  progress_percent: number;
  latest_quiz_score: string | null;
  best_quiz_score: string | null;
  updated_at: Date;
}

interface RewardEventRow {
  id: string;
  user_id: string;
  reward_type: string;
  source_type: string;
  source_id: string;
  reward_level: number;
  coins: number;
  metadata_json: unknown;
  created_at: Date;
}

interface ChapterProgressRow {
  chapter_id: string;
  chapter_title: string;
  completed_lessons: string;
  total_lessons: string;
}

@Injectable()
export class DatabaseRepository {
  private learningActivitySchemaReady = false;
  private questionsSchemaReady = false;
  private quizAttemptsSchemaReady = false;
  private rewardEventsSchemaReady = false;

  constructor(@Inject(DATABASE_POOL) private readonly pool: Pool) {}

  async withTransaction<T>(work: (client: PoolClient) => Promise<T>) {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      const result = await work(client);
      await client.query("COMMIT");
      return result;
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  async findUserByEmail(email: string, db: Db = this.pool) {
    const result = await db.query<UserRow>(
      "select * from users where email = $1",
      [email],
    );
    return result.rows[0] ? this.mapUser(result.rows[0]) : null;
  }

  async findUserById(id: string, db: Db = this.pool) {
    const result = await db.query<UserRow>(
      "select * from users where id = $1",
      [id],
    );
    return result.rows[0] ? this.mapUser(result.rows[0]) : null;
  }

  async createUser(input: {
    name: string;
    email: string;
    passwordHash: string;
    role?: "STUDENT" | "TEACHER" | "ADMIN";
  }) {
    const result = await this.pool.query<UserRow>(
      `insert into users (name, email, password_hash, role)
       values ($1, $2, $3, $4)
       returning *`,
      [input.name, input.email, input.passwordHash, input.role ?? "STUDENT"],
    );
    return this.mapUser(result.rows[0]);
  }

  async updateUser(id: string, input: { name?: string }) {
    const result = await this.pool.query<UserRow>(
      `update users
       set name = coalesce($2, name), updated_at = now()
       where id = $1
       returning *`,
      [id, input.name ?? null],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("User not found");
    }
    return this.mapUser(result.rows[0]);
  }

  async updatePassword(id: string, passwordHash: string) {
    const result = await this.pool.query<UserRow>(
      `update users
       set password_hash = $2,
           refresh_token_hash = null,
           refresh_token_expires_at = null,
           updated_at = now()
       where id = $1
       returning *`,
      [id, passwordHash],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("User not found");
    }
    return this.mapUser(result.rows[0]);
  }

  async saveRefreshToken(
    userId: string,
    refreshTokenHash: string,
    refreshTokenExpiresAt: Date,
  ) {
    await this.pool.query(
      `update users
       set refresh_token_hash = $2,
           refresh_token_expires_at = $3,
           updated_at = now()
       where id = $1`,
      [userId, refreshTokenHash, refreshTokenExpiresAt],
    );
  }

  async clearRefreshToken(userId: string) {
    await this.pool.query(
      `update users
       set refresh_token_hash = null,
           refresh_token_expires_at = null,
           updated_at = now()
       where id = $1`,
      [userId],
    );
  }

  async addCoins(userId: string, coins: number, db: Db = this.pool) {
    const result = await db.query<UserRow>(
      `update users
       set coins = coins + $2, updated_at = now()
       where id = $1
       returning *`,
      [userId, coins],
    );
    return this.mapUser(result.rows[0]);
  }

  async listChapters() {
    const result = await this.pool.query<ChapterRow>(
      `select c.*, count(l.id) as lesson_count
       from chapters c
       left join lessons l on l.chapter_id = c.id and l.is_published = true
       where c.is_published = true
       group by c.id
       order by c.order_index asc`,
    );
    return result.rows.map((row) => ({
      ...this.mapChapter(row),
      lessonCount: Number(row.lesson_count ?? 0),
    }));
  }

  async findChapter(id: string) {
    const result = await this.pool.query<ChapterRow>(
      "select * from chapters where id = $1 and is_published = true",
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Chapter not found");
    }
    return this.mapChapter(result.rows[0]);
  }

  async listLessonsByChapter(chapterId: string) {
    const result = await this.pool.query<LessonRow>(
      `select * from lessons
       where chapter_id = $1 and is_published = true
       order by order_index asc`,
      [chapterId],
    );
    return result.rows.map((row) => this.mapLesson(row));
  }

  async findLesson(id: string, db: Db = this.pool) {
    const result = await db.query<LessonRow>(
      "select * from lessons where id = $1 and is_published = true",
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Lesson not found");
    }
    return this.mapLesson(result.rows[0]);
  }

  async listSimulationsByLesson(lessonId: string) {
    const result = await this.pool.query<SimulationRow>(
      "select * from simulations where lesson_id = $1 order by id asc",
      [lessonId],
    );
    return result.rows.map((row) => ({
      id: row.id,
      lessonId: row.lesson_id,
      title: row.title,
      formula: row.formula,
      expression: row.expression,
      variables: row.variables_json,
      result: row.result_json,
    }));
  }

  async listSimulations() {
    const result = await this.pool.query<SimulationRow>(
      "select * from simulations order by lesson_id asc, id asc",
    );
    return result.rows.map((row) => ({
      id: row.id,
      lessonId: row.lesson_id,
      title: row.title,
      formula: row.formula,
      expression: row.expression,
      variables: row.variables_json,
      result: row.result_json,
    }));
  }

  async listQuestionsByLesson(lessonId: string, db: Db = this.pool) {
    await this.ensureQuestionsSchema(db);
    const result = await db.query<QuestionRow>(
      "select * from questions where lesson_id = $1 order by order_index asc",
      [lessonId],
    );
    return result.rows.map((row) => this.mapQuestion(row));
  }

  async listAdminQuestionsByLesson(lessonId: string, db: Db = this.pool) {
    await this.ensureQuestionsSchema(db);
    const result = await db.query<QuestionRow>(
      "select * from questions where lesson_id = $1 order by order_index asc, id asc",
      [lessonId],
    );
    return result.rows.map((row) => this.mapQuestion(row));
  }

  async listQuestionsWithoutCorrectOptions() {
    await this.ensureQuestionsSchema();
    const result = await this.pool.query<QuestionRow>(
      "select * from questions order by lesson_id asc, order_index asc",
    );
    return result.rows.map((row) => {
      const {
        correctOption: _correctOption,
        explanation: _explanation,
        ...question
      } = this.mapQuestion(row);
      return question;
    });
  }

  async adminListChapters() {
    const result = await this.pool.query<ChapterRow & { created_at: Date }>(
      `select c.*, count(l.id) as lesson_count
       from chapters c
       left join lessons l on l.chapter_id = c.id
       group by c.id
       order by c.order_index asc`,
    );
    return result.rows.map((row) => ({
      ...this.mapChapter(row),
      createdAt: row.created_at,
      lessonCount: Number(row.lesson_count ?? 0),
    }));
  }

  async lockRewardScope(
    userId: string,
    sourceType: string,
    sourceId: string,
    db: Db,
  ) {
    await db.query("select pg_advisory_xact_lock(hashtext($1))", [
      `${userId}:${sourceType}:${sourceId}`,
    ]);
  }

  async adminListLessons() {
    const result = await this.pool.query<LessonRow>(
      "select * from lessons order by chapter_id asc, order_index asc",
    );
    return result.rows.map((row) => this.mapLesson(row));
  }

  async findAdminLesson(id: string, db: Db = this.pool) {
    const result = await db.query<LessonRow>(
      "select * from lessons where id = $1 and is_published = true",
      [id],
    );
    return result.rows[0] ? this.mapLesson(result.rows[0]) : null;
  }

  async adminListQuestions(query: {
    lessonId?: string;
    chapterId?: string;
    search?: string;
    difficulty?: "EASY" | "MEDIUM" | "HARD";
    page?: number;
    limit?: number;
  }) {
    await this.ensureQuestionsSchema();
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const values: unknown[] = [];
    const addValue = (value: unknown) => {
      values.push(value);
      return `$${values.length}`;
    };

    if (query.lessonId) {
      where.push(`q.lesson_id = ${addValue(query.lessonId)}`);
    }
    if (query.chapterId) {
      where.push(`l.chapter_id = ${addValue(query.chapterId)}`);
    }
    if (query.search) {
      where.push(`q.question_text ilike ${addValue(`%${query.search}%`)}`);
    }
    if (query.difficulty) {
      where.push(`q.difficulty = ${addValue(query.difficulty)}`);
    }

    const whereClause = where.length > 0 ? `where ${where.join(" and ")}` : "";
    const countResult = await this.pool.query<{ total: string }>(
      `select count(*) as total
       from questions q
       join lessons l on l.id = q.lesson_id
       join chapters c on c.id = l.chapter_id
       ${whereClause}`,
      values,
    );
    const total = Number(countResult.rows[0]?.total ?? 0);
    const listValues = [...values, limit, offset];
    const result = await this.pool.query<AdminQuestionRow>(
      `select q.*,
              l.title as lesson_title,
              l.chapter_id,
              c.title as chapter_title
       from questions q
       join lessons l on l.id = q.lesson_id
       join chapters c on c.id = l.chapter_id
       ${whereClause}
       order by c.order_index asc, l.order_index asc, q.order_index asc, q.id asc
       limit $${values.length + 1} offset $${values.length + 2}`,
      listValues,
    );
    return {
      items: result.rows.map((row) => this.mapAdminQuestion(row)),
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findAdminQuestion(id: string, db: Db = this.pool) {
    await this.ensureQuestionsSchema(db);
    const result = await db.query<AdminQuestionRow>(
      `select q.*,
              l.title as lesson_title,
              l.chapter_id,
              c.title as chapter_title
       from questions q
       join lessons l on l.id = q.lesson_id
       join chapters c on c.id = l.chapter_id
       where q.id = $1`,
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Question not found");
    }
    return this.mapAdminQuestion(result.rows[0]);
  }

  async questionOrderIndexExists(input: {
    lessonId: string;
    orderIndex: number;
    excludeQuestionId?: string;
  }) {
    const result = await this.pool.query<{ exists: boolean }>(
      `select exists(
         select 1 from questions
         where lesson_id = $1
           and order_index = $2
           and ($3::varchar is null or id <> $3)
       )`,
      [input.lessonId, input.orderIndex, input.excludeQuestionId ?? null],
    );
    return Boolean(result.rows[0]?.exists);
  }

  async upsertChapter(input: {
    id: string;
    title: string;
    description: string;
    orderIndex: number;
    isPublished?: boolean;
  }) {
    const result = await this.pool.query<ChapterRow>(
      `insert into chapters (id, title, description, order_index, is_published)
       values ($1, $2, $3, $4, $5)
       on conflict (id) do update set
         title = excluded.title,
         description = excluded.description,
         order_index = excluded.order_index,
         is_published = excluded.is_published,
         updated_at = now()
       returning *`,
      [
        input.id,
        input.title,
        input.description,
        input.orderIndex,
        input.isPublished ?? true,
      ],
    );
    return this.mapChapter(result.rows[0]);
  }

  async updateChapter(
    id: string,
    input: Omit<Parameters<DatabaseRepository["upsertChapter"]>[0], "id">,
  ) {
    const result = await this.pool.query<ChapterRow>(
      `update chapters
       set title = $2,
           description = $3,
           order_index = $4,
           is_published = $5,
           updated_at = now()
       where id = $1
       returning *`,
      [
        id,
        input.title,
        input.description,
        input.orderIndex,
        input.isPublished ?? true,
      ],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Chapter not found");
    }
    return this.mapChapter(result.rows[0]);
  }

  async softDeleteChapter(id: string) {
    const result = await this.pool.query<ChapterRow>(
      `delete from chapters
       where id = $1
       returning *`,
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Chapter not found");
    }
    return { id, deleted: true, mode: 'hard' };
  }

  async upsertLesson(input: {
    id: string;
    chapterId: string;
    title: string;
    contentMarkdown: string;
    formulaLatex?: string | null;
    estimatedMinutes: number;
    orderIndex: number;
    isPublished?: boolean;
  }) {
    const result = await this.pool.query<LessonRow>(
      `insert into lessons
        (id, chapter_id, title, content_markdown, formula_latex, estimated_minutes, order_index, is_published)
       values ($1, $2, $3, $4, $5, $6, $7, $8)
       on conflict (id) do update set
         chapter_id = excluded.chapter_id,
         title = excluded.title,
         content_markdown = excluded.content_markdown,
         formula_latex = excluded.formula_latex,
         estimated_minutes = excluded.estimated_minutes,
         order_index = excluded.order_index,
         is_published = excluded.is_published,
         updated_at = now()
       returning *`,
      [
        input.id,
        input.chapterId,
        input.title,
        input.contentMarkdown,
        input.formulaLatex ?? null,
        input.estimatedMinutes,
        input.orderIndex,
        input.isPublished ?? true,
      ],
    );
    return this.mapLesson(result.rows[0]);
  }

  async updateLesson(
    id: string,
    input: Omit<Parameters<DatabaseRepository["upsertLesson"]>[0], "id">,
  ) {
    const result = await this.pool.query<LessonRow>(
      `update lessons
       set chapter_id = $2,
           title = $3,
           content_markdown = $4,
           formula_latex = $5,
           estimated_minutes = $6,
           order_index = $7,
           is_published = $8,
           updated_at = now()
       where id = $1
       returning *`,
      [
        id,
        input.chapterId,
        input.title,
        input.contentMarkdown,
        input.formulaLatex ?? null,
        input.estimatedMinutes,
        input.orderIndex,
        input.isPublished ?? true,
      ],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Lesson not found");
    }
    return this.mapLesson(result.rows[0]);
  }

  async softDeleteLesson(id: string) {
    const result = await this.pool.query<LessonRow>(
      `delete from lessons
       where id = $1
       returning *`,
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Lesson not found");
    }
    return { id, deleted: true, mode: 'hard' };
  }

  async upsertQuestion(
    input: {
      id: string;
      lessonId: string;
      questionText: string;
      options: string[];
      correctOption: number;
      explanation: string;
      difficulty: "EASY" | "MEDIUM" | "HARD";
      orderIndex: number;
    },
    db: Db = this.pool,
  ) {
    await this.ensureQuestionsSchema(db);
    const result = await db.query<QuestionRow>(
      `insert into questions
        (id, lesson_id, question_text, options_json, correct_option, explanation, difficulty, order_index)
       values ($1, $2, $3, $4::jsonb, $5, $6, $7, $8)
       on conflict (id) do update set
         lesson_id = excluded.lesson_id,
         question_text = excluded.question_text,
         options_json = excluded.options_json,
         correct_option = excluded.correct_option,
         explanation = excluded.explanation,
         difficulty = excluded.difficulty,
         order_index = excluded.order_index
       returning *`,
      [
        input.id,
        input.lessonId,
        input.questionText,
        JSON.stringify(input.options),
        input.correctOption,
        input.explanation,
        input.difficulty,
        input.orderIndex,
      ],
    );
    return this.mapQuestion(result.rows[0]);
  }

  async updateQuestion(
    id: string,
    input: Omit<Parameters<DatabaseRepository["upsertQuestion"]>[0], "id">,
    db: Db = this.pool,
  ) {
    await this.ensureQuestionsSchema(db);
    const result = await db.query<QuestionRow>(
      `update questions
       set lesson_id = $2,
           question_text = $3,
           options_json = $4::jsonb,
           correct_option = $5,
           explanation = $6,
           difficulty = $7,
           order_index = $8
       where id = $1
       returning *`,
      [
        id,
        input.lessonId,
        input.questionText,
        JSON.stringify(input.options),
        input.correctOption,
        input.explanation,
        input.difficulty,
        input.orderIndex,
      ],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Question not found");
    }
    return this.mapQuestion(result.rows[0]);
  }

  async deleteQuestion(id: string, db: Db = this.pool) {
    const result = await db.query<QuestionRow>(
      "delete from questions where id = $1 returning *",
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Question not found");
    }
    return { id, deleted: true, mode: "hard" };
  }

  async setQuestionOrder(
    lessonId: string,
    questionIds: string[],
    db: Db = this.pool,
  ) {
    if (questionIds.length === 0) return [];
    await db.query(
      `with numbered as (
         select
           id,
           (
             coalesce(
               min(order_index) over (partition by lesson_id),
               0
             ) - row_number() over (order by order_index asc, id asc)
           )::integer as temporary_order
         from questions
         where lesson_id = $1
       )
       update questions q
       set order_index = numbered.temporary_order
       from numbered
       where q.id = numbered.id`,
      [lessonId],
    );
    const values = questionIds
      .map(
        (id, index) =>
          `($${index * 2 + 2}::varchar, $${index * 2 + 3}::integer)`,
      )
      .join(", ");
    const params: unknown[] = [lessonId];
    questionIds.forEach((id, index) => {
      params.push(id, index + 1);
    });
    const result = await db.query<{ id: string; order_index: number }>(
      `update questions q
       set order_index = v.order_index
       from (values ${values}) as v(id, order_index)
       where q.lesson_id = $1 and q.id = v.id
       returning q.id, q.order_index`,
      params,
    );
    return result.rows
      .map((row) => ({
        id: row.id,
        orderIndex: row.order_index,
      }))
      .sort((a, b) => a.orderIndex - b.orderIndex);
  }

  async createQuizAttempt(
    input: {
      userId: string;
      lessonId: string;
      answers: Array<{ questionId: string; selectedOption: number }>;
      review: unknown[];
      score: number;
      correctCount: number;
      totalQuestions: number;
      durationSeconds: number;
      coinsEarned: number;
    },
    db: Db,
  ) {
    await this.ensureQuizAttemptsSchema(db);
    const result = await db.query<AttemptRow>(
      `insert into quiz_attempts
        (user_id, lesson_id, answers_json, review_json, score, correct_count, total_questions, duration_seconds, coins_earned)
       values ($1, $2, $3::jsonb, $4::jsonb, $5, $6, $7, $8, $9)
       returning *`,
      [
        input.userId,
        input.lessonId,
        JSON.stringify(input.answers),
        JSON.stringify(input.review),
        input.score,
        input.correctCount,
        input.totalQuestions,
        input.durationSeconds,
        input.coinsEarned,
      ],
    );
    return this.mapAttempt(result.rows[0]);
  }

  async listAttemptsByUser(userId: string) {
    const result = await this.pool.query<AttemptRow>(
      `select * from quiz_attempts
       where user_id = $1
       order by created_at desc`,
      [userId],
    );
    return result.rows.map((row) => this.mapAttempt(row));
  }

  async listRecentAttemptsByUser(userId: string, limit = 5) {
    const result = await this.pool.query<AttemptRow>(
      `select qa.*, l.title as lesson_title, l.chapter_id
       from quiz_attempts qa
       join lessons l on l.id = qa.lesson_id
       where qa.user_id = $1
       order by qa.created_at desc
       limit $2`,
      [userId, limit],
    );
    return result.rows.map((row) => this.mapAttempt(row));
  }

  async averageBestScore(userId: string) {
    const result = await this.pool.query<{ average_score: string | null }>(
      `select avg(best_score) as average_score
       from (
         select max(score) as best_score
         from quiz_attempts
         where user_id = $1
         group by lesson_id
       ) best_scores`,
      [userId],
    );
    return Number(result.rows[0]?.average_score ?? 0);
  }

  async findAttempt(id: string, userId: string) {
    const result = await this.pool.query<AttemptRow>(
      "select * from quiz_attempts where id = $1 and user_id = $2",
      [id, userId],
    );
    if (!result.rows[0]) {
      throw new NotFoundException("Quiz attempt not found");
    }
    return this.mapAttempt(result.rows[0]);
  }

  async upsertProgress(
    input: {
      userId: string;
      lessonId: string;
      status: "NOT_STARTED" | "IN_PROGRESS" | "COMPLETED";
      progressPercent: number;
      latestQuizScore?: number | null;
      bestQuizScore?: number | null;
    },
    db: Db = this.pool,
  ) {
    const result = await db.query<ProgressRow>(
      `insert into progress
        (user_id, lesson_id, status, progress_percent, latest_quiz_score, best_quiz_score)
       values ($1, $2, $3, $4, $5, $6)
       on conflict (user_id, lesson_id)
       do update set status = excluded.status,
                     progress_percent = greatest(progress.progress_percent, excluded.progress_percent),
                     latest_quiz_score = excluded.latest_quiz_score,
                     best_quiz_score = greatest(
                       coalesce(progress.best_quiz_score, 0),
                       coalesce(excluded.best_quiz_score, 0)
                     ),
                     updated_at = now()
       returning *`,
      [
        input.userId,
        input.lessonId,
        input.status,
        input.progressPercent,
        input.latestQuizScore ?? null,
        input.bestQuizScore ?? null,
      ],
    );
    return this.mapProgress(result.rows[0]);
  }

  async findProgressForLesson(
    userId: string,
    lessonId: string,
    db: Db = this.pool,
  ) {
    const result = await db.query<ProgressRow>(
      "select * from progress where user_id = $1 and lesson_id = $2",
      [userId, lessonId],
    );
    return result.rows[0] ? this.mapProgress(result.rows[0]) : null;
  }

  // Records a real download event for the `downloaded_lessons` stats table
  // (see schema.sql). Intentionally not deduplicated when clientDeviceId is
  // omitted: Postgres treats each NULL as distinct for the unique
  // constraint, so repeated downloads without a device id simply add more
  // event rows, which matches how this table is consumed as an activity
  // stream (see the "recent activities" union query in getAdminStatistics)
  // rather than as a single "has this lesson" flag.
  async recordLessonDownload(
    input: {
      userId: string;
      lessonId: string;
      clientDeviceId?: string | null;
    },
    db: Db = this.pool,
  ) {
    await db.query(
      `insert into downloaded_lessons (user_id, lesson_id, client_device_id)
       values ($1, $2, $3)
       on conflict (user_id, lesson_id, client_device_id) do nothing`,
      [input.userId, input.lessonId, input.clientDeviceId ?? null],
    );
  }

  async listProgress(userId: string) {
    const result = await this.pool.query<ProgressRow>(
      `select * from progress
       where user_id = $1
       order by updated_at desc`,
      [userId],
    );
    return result.rows.map((row) => this.mapProgress(row));
  }

  async listChapterProgress(userId: string) {
    const result = await this.pool.query<ChapterProgressRow>(
      `select
         c.id as chapter_id,
         c.title as chapter_title,
         count(p.lesson_id) filter (where p.status = 'COMPLETED') as completed_lessons,
         count(l.id) as total_lessons
       from chapters c
       left join lessons l on l.chapter_id = c.id and l.is_published = true
       left join progress p on p.lesson_id = l.id and p.user_id = $1
       where c.is_published = true
       group by c.id, c.title, c.order_index
       order by c.order_index asc`,
      [userId],
    );
    return result.rows.map((row) => {
      const completedLessons = Number(row.completed_lessons ?? 0);
      const totalLessons = Number(row.total_lessons ?? 0);
      return {
        chapterId: row.chapter_id,
        title: row.chapter_title,
        completedLessons,
        totalLessons,
        progress: totalLessons === 0 ? 0 : completedLessons / totalLessons,
      };
    });
  }

  async awardBadge(userId: string, badgeId: string, db: Db = this.pool) {
    const result = await db.query<BadgeRow>(
      `insert into user_badges (user_id, badge_id)
       values ($1, $2)
       on conflict do nothing
       returning (select id from badges where id = $2) as id,
                 (select name from badges where id = $2) as name,
                 (select description from badges where id = $2) as description,
                 (select icon from badges where id = $2) as icon,
                 (select rule_key from badges where id = $2) as rule_key,
                 (select condition_value from badges where id = $2) as condition_value,
                 (select metadata_json from badges where id = $2) as metadata_json`,
      [userId, badgeId],
    );
    return result.rows[0] ? this.mapBadge(result.rows[0]) : null;
  }

  async listBadgesByUser(userId: string) {
    const result = await this.pool.query<BadgeRow>(
      `select b.*, ub.awarded_at
       from user_badges ub
       join badges b on b.id = ub.badge_id
       where ub.user_id = $1
       order by ub.awarded_at desc`,
      [userId],
    );
    return result.rows.map((row) => this.mapBadge(row));
  }

  async maxRewardLevel(
    userId: string,
    rewardType: string,
    sourceType: string,
    sourceId: string,
    db: Db = this.pool,
  ) {
    const result = await db.query<{ reward_level: number | null }>(
      `select max(reward_level) as reward_level
       from reward_events
       where user_id = $1 and reward_type = $2 and source_type = $3 and source_id = $4`,
      [userId, rewardType, sourceType, sourceId],
    );
    return Number(result.rows[0]?.reward_level ?? 0);
  }

  async createRewardEvent(
    input: {
      userId: string;
      rewardType: string;
      sourceType: string;
      sourceId: string;
      rewardLevel: number;
      coins: number;
      metadata?: unknown;
    },
    db: Db = this.pool,
  ) {
    await this.ensureRewardEventsSchema(db);
    const result = await db.query<RewardEventRow>(
      `insert into reward_events
        (user_id, reward_type, source_type, source_id, reward_level, coins, metadata_json)
       values ($1, $2, $3, $4, $5, $6, $7::jsonb)
       on conflict (user_id, reward_type, source_type, source_id, reward_level) do nothing
       returning *`,
      [
        input.userId,
        input.rewardType,
        input.sourceType,
        input.sourceId,
        input.rewardLevel,
        input.coins,
        JSON.stringify(input.metadata ?? {}),
      ],
    );
    return result.rows[0] ? this.mapRewardEvent(result.rows[0]) : null;
  }

  async listAllBadges() {
    const result = await this.pool.query<BadgeRow>(
      "select * from badges order by id asc",
    );
    return result.rows.map((row) => this.mapBadge(row));
  }

  async listBadgesByRule(ruleKey: string, db: Db = this.pool) {
    const result = await db.query<BadgeRow>(
      "select * from badges where rule_key = $1 order by id asc",
      [ruleKey],
    );
    return result.rows.map((row) => this.mapBadge(row));
  }

  async recordLearningActivity(
    userId: string,
    input: { sourceType: string; sourceId: string; activityDate?: string },
    db: Db = this.pool,
  ) {
    await this.ensureLearningActivitySchema(db);
    const result = await db.query<{ activity_date: Date | string }>(
      `insert into learning_activity (user_id, activity_date, source_type, source_id)
       values ($1, coalesce($2::date, (now() at time zone 'utc')::date), $3, $4)
       on conflict (user_id, activity_date) do update set
         source_type = learning_activity.source_type
       returning activity_date`,
      [userId, input.activityDate ?? null, input.sourceType, input.sourceId],
    );
    return result.rows[0].activity_date;
  }

  private async ensureQuizAttemptsSchema(db: Db = this.pool) {
    if (this.quizAttemptsSchemaReady) return;

    await db.query(`
      alter table quiz_attempts
        add column if not exists duration_seconds integer not null default 0,
        add column if not exists review_json jsonb,
        add column if not exists coins_earned integer not null default 0
    `);

    this.quizAttemptsSchemaReady = true;
  }

  private async ensureQuestionsSchema(db: Db = this.pool) {
    if (this.questionsSchemaReady) return;

    await db.query(`
      alter table questions
        add column if not exists difficulty varchar(20) not null default 'MEDIUM'
    `);
    await db.query(`
      do $$
      begin
        if not exists (
          select 1
          from pg_constraint
          where conname = 'questions_difficulty_check'
        ) then
          alter table questions
            add constraint questions_difficulty_check
            check (difficulty in ('EASY', 'MEDIUM', 'HARD'));
        end if;
      end $$
    `);

    this.questionsSchemaReady = true;
  }

  private async ensureRewardEventsSchema(db: Db = this.pool) {
    if (this.rewardEventsSchemaReady) return;

    await db.query(`
      create table if not exists reward_events (
        id uuid primary key default gen_random_uuid(),
        user_id uuid not null references users(id) on delete cascade,
        reward_type varchar(60) not null,
        source_type varchar(60) not null,
        source_id varchar(120) not null,
        reward_level integer not null default 0,
        coins integer not null,
        metadata_json jsonb not null default '{}'::jsonb,
        created_at timestamptz not null default now()
      )
    `);
    await db.query(`
      alter table reward_events
        add column if not exists reward_level integer not null default 0,
        add column if not exists metadata_json jsonb not null default '{}'::jsonb
    `);
    await db.query(`
      create unique index if not exists reward_events_user_reward_source_level_idx
      on reward_events (user_id, reward_type, source_type, source_id, reward_level)
    `);

    this.rewardEventsSchemaReady = true;
  }

  async currentLearningStreak(userId: string, db: Db = this.pool) {
    await this.ensureLearningActivitySchema(db);
    const result = await db.query<{ activity_date: Date }>(
      `select activity_date
       from learning_activity
       where user_id = $1
       order by activity_date desc`,
      [userId],
    );
    let streak = 0;
    let expected: string | null = null;
    for (const row of result.rows) {
      const date =
        row.activity_date instanceof Date
          ? row.activity_date.toISOString().slice(0, 10)
          : row.activity_date;
      if (expected === null) {
        expected = date;
      }
      if (date !== expected) {
        break;
      }
      streak += 1;
      const previousDate: Date = new Date(`${date}T00:00:00.000Z`);
      previousDate.setUTCDate(previousDate.getUTCDate() - 1);
      expected = previousDate.toISOString().slice(0, 10);
    }
    return streak;
  }

  private async ensureLearningActivitySchema(db: Db = this.pool) {
    if (this.learningActivitySchemaReady) return;

    await db.query(`
      create table if not exists learning_activity (
        id uuid primary key default gen_random_uuid(),
        user_id uuid not null references users(id) on delete cascade,
        activity_date date not null,
        source_type varchar(60) not null,
        source_id varchar(120) not null,
        created_at timestamptz not null default now(),
        unique (user_id, activity_date)
      )
    `);
    await db.query(`
      create index if not exists learning_activity_user_date_idx
      on learning_activity(user_id, activity_date desc)
    `);

    this.learningActivitySchemaReady = true;
  }

  async countCompletedLessons(userId: string, db: Db = this.pool) {
    const result = await db.query<{ count: string }>(
      `select count(*) from progress
       where user_id = $1 and status = 'COMPLETED'`,
      [userId],
    );
    return Number(result.rows[0]?.count ?? 0);
  }

  async countTotalLessons(db: Db = this.pool) {
    const result = await db.query<{ count: string }>(
      "select count(*) from lessons where is_published = true",
    );
    return Number(result.rows[0]?.count ?? 0);
  }

  async countCompletedLessonsInChapter(
    userId: string,
    chapterId: string,
    db: Db = this.pool,
  ) {
    const result = await db.query<{ count: string }>(
      `select count(*)
       from progress p
       join lessons l on l.id = p.lesson_id
       where p.user_id = $1 and l.chapter_id = $2 and p.status = 'COMPLETED'`,
      [userId, chapterId],
    );
    return Number(result.rows[0]?.count ?? 0);
  }

  async countLessonsInChapter(chapterId: string, db: Db = this.pool) {
    const result = await db.query<{ count: string }>(
      "select count(*) from lessons where chapter_id = $1 and is_published = true",
      [chapterId],
    );
    return Number(result.rows[0]?.count ?? 0);
  }

  async adminUsers() {
    const result = await this.pool.query<UserRow>(
      "select * from users order by created_at desc",
    );
    return result.rows.map((row) => this.toPublicUser(this.mapUser(row)));
  }

  async statistics() {
    // Drop unique order_index constraint on chapters to avoid index collision crashes on live database
    await this.pool.query('alter table chapters drop constraint if exists chapters_order_index_key').catch(() => {});

    const [users, attempts, completed, lessons, chapters, questions] = await Promise.all([
      this.pool.query<{ count: string }>("select count(*) from users where role = 'STUDENT'"),
      this.pool.query<{ count: string }>('select count(*) from quiz_attempts'),
      this.pool.query<{ count: string }>(
        "select count(*) from progress where status = 'COMPLETED'",
      ),
      this.pool.query<{ count: string }>(
        "select count(*) from lessons where is_published = true",
      ),
      this.pool.query<{ count: string }>('select count(*) from chapters'),
      this.pool.query<{ count: string }>('select count(*) from questions'),
    ]);
    const completedCount = Number(completed.rows[0]?.count ?? 0);
    const lessonCount = Number(lessons.rows[0]?.count ?? 0);

    // Dynamic Chart Data: Unique active users per day over the last 7 days
    const chartQuery = await this.pool.query<{ day_num: string; active_count: string }>(
      `select to_char(d, 'ID') as day_num, coalesce(count(distinct q.user_id), 0) as active_count
       from generate_series(now() - interval '6 days', now(), '1 day') d
       left join quiz_attempts q on q.created_at::date = d::date
       group by d::date, d
       order by d::date`
    );
    const activeUsersData = chartQuery.rows.map(row => Number(row.active_count));

    // Hardest Lessons: Top 5 lessons with lowest average quiz attempt score
    const hardestQuery = await this.pool.query<{ title: string; avg_score: string }>(
      `select l.title, coalesce(avg(q.score), 0.0) as avg_score
       from lessons l
       left join quiz_attempts q on q.lesson_id = l.id
       where l.is_published = true
       group by l.id, l.title
       order by avg_score asc
       limit 5`
    );
    const hardestLessons = hardestQuery.rows.map(row => ({
      title: row.title,
      percentage: Number(row.avg_score) / 10.0,
    }));

    // Blended Recent Activities: Blending quiz attempts, progress, signups and downloads
    const activityQuery = await this.pool.query<{
      type: string;
      user_name: string;
      action: string;
      detail: string;
      created_at: Date;
    }>(
      `(
         select 'quiz' as type, u.name as user_name, 'Hoàn thành bài kiểm tra' as action, l.title as detail, q.created_at as created_at
         from quiz_attempts q
         join users u on u.id = q.user_id
         join lessons l on l.id = q.lesson_id
       )
       union all
       (
         select 'progress' as type, u.name as user_name, 'Bắt đầu bài học' as action, l.title as detail, p.updated_at as created_at
         from progress p
         join users u on u.id = p.user_id
         join lessons l on l.id = p.lesson_id
         where p.status = 'IN_PROGRESS'
       )
       union all
       (
         select 'user' as type, name as user_name, 'Đăng ký tài khoản' as action, 'Lớp 8' as detail, created_at as created_at
         from users
         where role = 'STUDENT'
       )
       union all
       (
         select 'download' as type, u.name as user_name, 'Tải bài học offline' as action, l.title as detail, d.downloaded_at as created_at
         from downloaded_lessons d
         join users u on u.id = d.user_id
         join lessons l on l.id = d.lesson_id
       )
       order by created_at desc
       limit 4`
    );
    const recentActivities = activityQuery.rows.map(row => ({
      type: row.type,
      userName: row.user_name,
      action: row.action,
      detail: row.detail,
      createdAt: row.created_at,
    }));

    return {
      totalUsers: Number(users.rows[0]?.count ?? 0),
      totalAttempts: Number(attempts.rows[0]?.count ?? 0),
      completionRate: lessonCount === 0 ? 0 : completedCount / lessonCount,
      totalChapters: Number(chapters.rows[0]?.count ?? 0),
      totalLessons: lessonCount,
      totalQuestions: Number(questions.rows[0]?.count ?? 0),
      activeUsersData,
      hardestLessons,
      recentActivities,
    };
  }

  toPublicUser(user: ReturnType<DatabaseRepository["mapUser"]>) {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      coins: user.coins,
    };
  }

  private mapUser(row: UserRow) {
    return {
      id: row.id,
      name: row.name,
      email: row.email,
      passwordHash: row.password_hash,
      role: row.role,
      coins: row.coins,
      refreshTokenHash: row.refresh_token_hash,
      refreshTokenExpiresAt: row.refresh_token_expires_at,
    };
  }

  private mapChapter(row: ChapterRow) {
    return {
      id: row.id,
      title: row.title,
      description: row.description,
      orderIndex: row.order_index,
      isPublished: row.is_published,
    };
  }

  private mapLesson(row: LessonRow) {
    return {
      id: row.id,
      chapterId: row.chapter_id,
      title: row.title,
      contentMarkdown: row.content_markdown,
      formulaLatex: row.formula_latex,
      estimatedMinutes: row.estimated_minutes,
      orderIndex: row.order_index,
      isPublished: row.is_published,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  private mapQuestion(row: QuestionRow) {
    return {
      id: row.id,
      lessonId: row.lesson_id,
      question: row.question_text,
      options: row.options_json,
      correctOption: row.correct_option,
      explanation: row.explanation,
      difficulty: row.difficulty ?? "MEDIUM",
      orderIndex: row.order_index,
    };
  }

  private mapAdminQuestion(row: AdminQuestionRow) {
    return {
      ...this.mapQuestion(row),
      questionText: row.question_text,
      lessonTitle: row.lesson_title,
      chapterId: row.chapter_id,
      chapterTitle: row.chapter_title,
    };
  }

  private mapAttempt(row: AttemptRow) {
    return {
      id: row.id,
      userId: row.user_id,
      lessonId: row.lesson_id,
      lessonTitle: row.lesson_title,
      chapterId: row.chapter_id,
      answers: row.answers_json,
      review: row.review_json ?? [],
      score: Number(row.score),
      correctCount: row.correct_count,
      totalQuestions: row.total_questions,
      durationSeconds: row.duration_seconds,
      earnedCoins: row.coins_earned,
      coinsEarned: row.coins_earned,
      submittedAt: row.created_at,
      createdAt: row.created_at,
    };
  }

  private mapProgress(row: ProgressRow) {
    return {
      id: row.id,
      userId: row.user_id,
      lessonId: row.lesson_id,
      status: row.status,
      progressPercent: row.progress_percent,
      latestQuizScore:
        row.latest_quiz_score === null ? null : Number(row.latest_quiz_score),
      bestQuizScore:
        row.best_quiz_score === null ? null : Number(row.best_quiz_score),
      updatedAt: row.updated_at,
    };
  }

  private mapRewardEvent(row: RewardEventRow) {
    return {
      id: row.id,
      userId: row.user_id,
      rewardType: row.reward_type,
      sourceType: row.source_type,
      sourceId: row.source_id,
      rewardLevel: row.reward_level,
      coins: row.coins,
      metadata: row.metadata_json,
      createdAt: row.created_at,
    };
  }

  private mapBadge(row: BadgeRow) {
    return {
      id: row.id,
      name: row.name,
      description: row.description,
      iconUrl: row.icon,
      icon: row.icon,
      ruleKey: row.rule_key,
      conditionValue: row.condition_value,
      metadata: row.metadata_json,
      achievedAt: row.awarded_at,
    };
  }
}
