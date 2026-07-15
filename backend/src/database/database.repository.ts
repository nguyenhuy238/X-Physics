import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { Pool, PoolClient } from 'pg';

import { DATABASE_POOL } from './database.constants';

type Db = Pool | PoolClient;

interface UserRow {
  id: string;
  name: string;
  email: string;
  password_hash: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
  coins: number;
  created_at: Date;
}

interface ChapterRow {
  id: string;
  title: string;
  description: string;
  order_index: number;
  is_published: boolean;
  lesson_count?: string;
  lesson_published_count?: string;
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
  question_count?: string;
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
  difficulty: 'EASY' | 'MEDIUM' | 'HARD';
  order_index: number;
}

interface BadgeRow {
  id: string;
  name: string;
  description: string;
  icon: string | null;
  rule_key: string;
}

interface AttemptRow {
  id: string;
  user_id: string;
  lesson_id: string;
  answers_json: unknown;
  score: string;
  correct_count: number;
  total_questions: number;
  coins_earned: number;
  created_at: Date;
}

interface ProgressRow {
  id: string;
  user_id: string;
  lesson_id: string;
  status: 'NOT_STARTED' | 'IN_PROGRESS' | 'COMPLETED';
  progress_percent: number;
  updated_at: Date;
}

@Injectable()
export class DatabaseRepository {
  constructor(@Inject(DATABASE_POOL) private readonly pool: Pool) {}

  async withTransaction<T>(work: (client: PoolClient) => Promise<T>) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await work(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async findUserByEmail(email: string, db: Db = this.pool) {
    const result = await db.query<UserRow>(
      'select * from users where email = $1',
      [email],
    );
    return result.rows[0] ? this.mapUser(result.rows[0]) : null;
  }

  async findUserById(id: string, db: Db = this.pool) {
    const result = await db.query<UserRow>('select * from users where id = $1', [
      id,
    ]);
    return result.rows[0] ? this.mapUser(result.rows[0]) : null;
  }

  async createUser(input: {
    name: string;
    email: string;
    passwordHash: string;
    role?: 'STUDENT' | 'TEACHER' | 'ADMIN';
  }) {
    const result = await this.pool.query<UserRow>(
      `insert into users (name, email, password_hash, role)
       values ($1, $2, $3, $4)
       returning *`,
      [input.name, input.email, input.passwordHash, input.role ?? 'STUDENT'],
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
      throw new NotFoundException('User not found');
    }
    return this.mapUser(result.rows[0]);
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
      'select * from chapters where id = $1 and is_published = true',
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Chapter not found');
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

  async findLesson(id: string) {
    const result = await this.pool.query<LessonRow>(
      'select * from lessons where id = $1 and is_published = true',
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Lesson not found');
    }
    return this.mapLesson(result.rows[0]);
  }

  async listSimulationsByLesson(lessonId: string) {
    const result = await this.pool.query<SimulationRow>(
      'select * from simulations where lesson_id = $1 order by id asc',
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
      'select * from simulations order by lesson_id asc, id asc',
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
    const result = await db.query<QuestionRow>(
      'select * from questions where lesson_id = $1 order by order_index asc',
      [lessonId],
    );
    return result.rows.map((row) => this.mapQuestion(row));
  }

  async listQuestionsWithoutCorrectOptions() {
    const result = await this.pool.query<QuestionRow>(
      'select * from questions order by lesson_id asc, order_index asc',
    );
    return result.rows.map((row) => {
      const { correctOption: _correctOption, ...question } = this.mapQuestion(row);
      return question;
    });
  }

  async adminListLessons() {
    const result = await this.pool.query<LessonRow>(
      'select * from lessons order by chapter_id asc, order_index asc',
    );
    return result.rows.map((row) => this.mapLesson(row));
  }

  async adminListQuestions() {
    const result = await this.pool.query<QuestionRow>(
      'select * from questions order by lesson_id asc, order_index asc',
    );
    return result.rows.map((row) => this.mapQuestion(row));
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
    input: Omit<Parameters<DatabaseRepository['upsertChapter']>[0], 'id'>,
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
      throw new NotFoundException('Chapter not found');
    }
    return this.mapChapter(result.rows[0]);
  }

  async softDeleteChapter(id: string) {
    const result = await this.pool.query<ChapterRow>(
      `update chapters
       set is_published = false, updated_at = now()
       where id = $1
       returning *`,
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Chapter not found');
    }
    return { id, deleted: true, mode: 'soft' };
  }

  async removeChapterWithLessonCheck(id: string) {
    const lessonCountResult = await this.pool.query<{ count: string }>(
      `select count(*) as count from lessons where chapter_id = $1`,
      [id],
    );
    const lessonCount = Number(lessonCountResult.rows[0]?.count ?? 0);
    if (lessonCount > 0) {
      throw new BadRequestException(
        `Cannot delete chapter because it still has ${lessonCount} lesson(s).`,
      );
    }

    const result = await this.pool.query<ChapterRow>(
      `delete from chapters where id = $1 returning *`,
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Chapter not found');
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
    input: Omit<Parameters<DatabaseRepository['upsertLesson']>[0], 'id'>,
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
      throw new NotFoundException('Lesson not found');
    }
    return this.mapLesson(result.rows[0]);
  }

  async softDeleteLesson(id: string) {
    const result = await this.pool.query<LessonRow>(
      `update lessons
       set is_published = false, updated_at = now()
       where id = $1
       returning *`,
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Lesson not found');
    }
    return { id, deleted: true, mode: 'soft' };
  }

  async upsertQuestion(input: {
    id: string;
    lessonId: string;
    questionText: string;
    options: string[];
    correctOption: number;
    explanation: string;
    orderIndex: number;
  }) {
    const result = await this.pool.query<QuestionRow>(
      `insert into questions
        (id, lesson_id, question_text, options_json, correct_option, explanation, order_index)
       values ($1, $2, $3, $4::jsonb, $5, $6, $7)
       on conflict (id) do update set
         lesson_id = excluded.lesson_id,
         question_text = excluded.question_text,
         options_json = excluded.options_json,
         correct_option = excluded.correct_option,
         explanation = excluded.explanation,
         order_index = excluded.order_index
       returning *`,
      [
        input.id,
        input.lessonId,
        input.questionText,
        JSON.stringify(input.options),
        input.correctOption,
        input.explanation,
        input.orderIndex,
      ],
    );
    return this.mapQuestion(result.rows[0]);
  }

  async updateQuestion(
    id: string,
    input: Omit<Parameters<DatabaseRepository['upsertQuestion']>[0], 'id'>,
  ) {
    const result = await this.pool.query<QuestionRow>(
      `update questions
       set lesson_id = $2,
           question_text = $3,
           options_json = $4::jsonb,
           correct_option = $5,
           explanation = $6,
           order_index = $7
       where id = $1
       returning *`,
      [
        id,
        input.lessonId,
        input.questionText,
        JSON.stringify(input.options),
        input.correctOption,
        input.explanation,
        input.orderIndex,
      ],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Question not found');
    }
    return this.mapQuestion(result.rows[0]);
  }

  async deleteQuestion(id: string) {
    const result = await this.pool.query<QuestionRow>(
      'delete from questions where id = $1 returning *',
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Question not found');
    }
    return { id, deleted: true, mode: 'hard' };
  }

  async createQuizAttempt(
    input: {
      userId: string;
      lessonId: string;
      answers: Array<{ questionId: string; selectedOption: number }>;
      score: number;
      correctCount: number;
      totalQuestions: number;
      coinsEarned: number;
    },
    db: Db,
  ) {
    const result = await db.query<AttemptRow>(
      `insert into quiz_attempts
        (user_id, lesson_id, answers_json, score, correct_count, total_questions, coins_earned)
       values ($1, $2, $3::jsonb, $4, $5, $6, $7)
       returning *`,
      [
        input.userId,
        input.lessonId,
        JSON.stringify(input.answers),
        input.score,
        input.correctCount,
        input.totalQuestions,
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

  async findAttempt(id: string, userId: string) {
    const result = await this.pool.query<AttemptRow>(
      'select * from quiz_attempts where id = $1 and user_id = $2',
      [id, userId],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Quiz attempt not found');
    }
    return this.mapAttempt(result.rows[0]);
  }

  async upsertProgress(
    input: {
      userId: string;
      lessonId: string;
      status: 'NOT_STARTED' | 'IN_PROGRESS' | 'COMPLETED';
      progressPercent: number;
    },
    db: Db = this.pool,
  ) {
    const result = await db.query<ProgressRow>(
      `insert into progress (user_id, lesson_id, status, progress_percent)
       values ($1, $2, $3, $4)
       on conflict (user_id, lesson_id)
       do update set status = excluded.status,
                     progress_percent = greatest(progress.progress_percent, excluded.progress_percent),
                     updated_at = now()
       returning *`,
      [input.userId, input.lessonId, input.status, input.progressPercent],
    );
    return this.mapProgress(result.rows[0]);
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

  async awardBadge(userId: string, badgeId: string, db: Db = this.pool) {
    const result = await db.query<BadgeRow>(
      `insert into user_badges (user_id, badge_id)
       values ($1, $2)
       on conflict do nothing
       returning (select id from badges where id = $2) as id,
                 (select name from badges where id = $2) as name,
                 (select description from badges where id = $2) as description,
                 (select icon from badges where id = $2) as icon,
                 (select rule_key from badges where id = $2) as rule_key`,
      [userId, badgeId],
    );
    return result.rows[0] ? this.mapBadge(result.rows[0]) : null;
  }

  async listBadgesByUser(userId: string) {
    const result = await this.pool.query<BadgeRow>(
      `select b.*
       from user_badges ub
       join badges b on b.id = ub.badge_id
       where ub.user_id = $1
       order by ub.awarded_at desc`,
      [userId],
    );
    return result.rows.map((row) => this.mapBadge(row));
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
      'select count(*) from lessons where is_published = true',
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
      'select count(*) from lessons where chapter_id = $1 and is_published = true',
      [chapterId],
    );
    return Number(result.rows[0]?.count ?? 0);
  }

  async adminUsers(query: { search?: string; sortBy?: string; sortOrder?: string; page?: number; limit?: number }) {
    const whereClauses: string[] = [];
    const params: unknown[] = [];
    if (query.search) {
      whereClauses.push('(u.name ilike $1 or u.email ilike $1)');
      params.push(`%${query.search}%`);
    }

    const orderBy = {
      createdAt: 'u.created_at',
      name: 'u.name',
      email: 'u.email',
    }[query.sortBy ?? 'createdAt'];

    const sortOrder = query.sortOrder ?? 'DESC';
    const whereSql = whereClauses.length ? `where ${whereClauses.join(' and ')}` : '';

    const limit = query.limit ?? 20;
    const page = query.page ?? 1;
    const offset = (page - 1) * limit;

    const [usersResult, countResult] = await Promise.all([
      this.pool.query<UserRow>(
        `select u.*
         from users u
         ${whereSql}
         order by ${orderBy} ${sortOrder}
         limit $${params.length + 1} offset $${params.length + 2}`,
        [...params, limit, offset],
      ),
      this.pool.query<{ count: string }>(
        `select count(*) as count
         from users u
         ${whereSql}`,
        params,
      ),
    ]);

    return {
      items: usersResult.rows.map((row) => this.toPublicUser(this.mapUser(row))),
      total: Number(countResult.rows[0]?.count ?? 0),
      page,
      limit,
    };
  }

  async adminLessons() {
    const result = await this.pool.query<LessonRow>(
      `select l.*, count(q.id) as question_count
       from lessons l
       left join questions q on q.lesson_id = l.id
       group by l.id
       order by l.chapter_id asc, l.order_index asc`,
    );
    return result.rows.map((row) => ({
      ...this.mapLesson(row),
      questionCount: Number(row.question_count ?? 0),
    }));
  }

  async adminQuestions() {
    const result = await this.pool.query<QuestionRow>(
      'select * from questions order by lesson_id asc, order_index asc',
    );
    return result.rows.map((row) => this.mapQuestion(row));
  }

  async adminChapters() {
    const result = await this.pool.query<ChapterRow>(
      `select c.*, count(l.id) as lesson_count
       from chapters c
       left join lessons l on l.chapter_id = c.id
       group by c.id
       order by c.order_index asc`,
    );
    return result.rows.map((row) => ({
      ...this.mapChapter(row),
      lessonCount: Number(row.lesson_count ?? 0),
    }));
  }

  async createChapter(input: {
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



  async createLesson(input: {
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



  async createQuestion(input: {
    id: string;
    lessonId: string;
    questionText: string;
    options: string[];
    correctOption: number;
    explanation: string;
    difficulty?: 'EASY' | 'MEDIUM' | 'HARD';
    orderIndex: number;
  }) {
    const result = await this.pool.query<QuestionRow>(
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
        input.difficulty ?? 'MEDIUM',
        input.orderIndex,
      ],
    );
    return this.mapQuestion(result.rows[0]);
  }



  async statistics() {
    // 1. Basic numbers
    const [overview, totalStudentsResult] = await Promise.all([
      this.pool.query<{
        total_users: string;
        total_attempts: string;
        total_lessons: string;
        total_badges: string;
      }>(`
        select
          (select count(*) from users) as total_users,
          (select count(*) from quiz_attempts) as total_attempts,
          (select count(*) from lessons where is_published = true) as total_lessons,
          (select count(*) from user_badges) as total_badges
      `),
      this.pool.query<{ count: string }>(
        `select count(*)::int as count from users where role = 'STUDENT'`
      ),
    ]);

    const overviewRow = overview.rows[0] ?? {};
    const totalUsers = Number(overviewRow.total_users ?? 0);
    const totalAttempts = Number(overviewRow.total_attempts ?? 0);
    const totalLessons = Number(overviewRow.total_lessons ?? 0);
    const totalBadges = Number(overviewRow.total_badges ?? 0);
    const totalStudents = Number(totalStudentsResult.rows[0]?.count ?? 0);

    // 2. Active users (7 Days / 30 Days)
    const [active7DaysResult, active30DaysResult] = await Promise.all([
      this.pool.query<{ count: string }>(`
        select count(distinct user_id)::int as count
        from (
          select user_id, created_at as activity_time from quiz_attempts
          where created_at >= now() - interval '7 days'
          union all
          select user_id, updated_at as activity_time from progress
          where updated_at >= now() - interval '7 days'
        ) all_activities
        join users u on u.id = all_activities.user_id
        where u.role = 'STUDENT'
      `),
      this.pool.query<{ count: string }>(`
        select count(distinct user_id)::int as count
        from (
          select user_id, created_at as activity_time from quiz_attempts
          where created_at >= now() - interval '30 days'
          union all
          select user_id, updated_at as activity_time from progress
          where updated_at >= now() - interval '30 days'
        ) all_activities
        join users u on u.id = all_activities.user_id
        where u.role = 'STUDENT'
      `),
    ]);
    const activeUsers7Days = Number(active7DaysResult.rows[0]?.count ?? 0);
    const activeUsers30Days = Number(active30DaysResult.rows[0]?.count ?? 0);

    // 3. Growth data (This week vs Last week)
    const [
      newUsersThisWeekResult,
      newUsersLastWeekResult,
      attemptsThisWeekResult,
      attemptsLastWeekResult,
      completionsThisWeekResult,
      completionsLastWeekResult,
    ] = await Promise.all([
      this.pool.query<{ count: string }>(`select count(*)::int as count from users where role = 'STUDENT' and created_at >= now() - interval '7 days'`),
      this.pool.query<{ count: string }>(`select count(*)::int as count from users where role = 'STUDENT' and created_at >= now() - interval '14 days' and created_at < now() - interval '7 days'`),
      this.pool.query<{ count: string }>(`select count(*)::int as count from quiz_attempts where created_at >= now() - interval '7 days'`),
      this.pool.query<{ count: string }>(`select count(*)::int as count from quiz_attempts where created_at >= now() - interval '14 days' and created_at < now() - interval '7 days'`),
      this.pool.query<{ count: string }>(`select count(*)::int as count from progress p join users u on p.user_id = u.id where p.status = 'COMPLETED' and u.role = 'STUDENT' and p.updated_at >= now() - interval '7 days'`),
      this.pool.query<{ count: string }>(`select count(*)::int as count from progress p join users u on p.user_id = u.id where p.status = 'COMPLETED' and u.role = 'STUDENT' and p.updated_at >= now() - interval '14 days' and p.updated_at < now() - interval '7 days'`),
    ]);

    const newUsersThisWeek = Number(newUsersThisWeekResult.rows[0]?.count ?? 0);
    const newUsersLastWeek = Number(newUsersLastWeekResult.rows[0]?.count ?? 0);
    const attemptsThisWeek = Number(attemptsThisWeekResult.rows[0]?.count ?? 0);
    const attemptsLastWeek = Number(attemptsLastWeekResult.rows[0]?.count ?? 0);
    const completionsThisWeek = Number(completionsThisWeekResult.rows[0]?.count ?? 0);
    const completionsLastWeek = Number(completionsLastWeekResult.rows[0]?.count ?? 0);

    const calculateGrowth = (current: number, previous: number) => {
      if (previous === 0) return current > 0 ? 100 : 0;
      return Number((((current - previous) / previous) * 100).toFixed(1));
    };

    const newUsersGrowth = calculateGrowth(newUsersThisWeek, newUsersLastWeek);
    const attemptsGrowth = calculateGrowth(attemptsThisWeek, attemptsLastWeek);
    const completionsGrowth = calculateGrowth(completionsThisWeek, completionsLastWeek);

    // 4. Retention rate
    const retentionResult = await this.pool.query<{ total_active: string; retained: string }>(`
      with student_active_days as (
        select user_id, count(distinct date_trunc('day', activity_time)) as active_days
        from (
          select user_id, created_at as activity_time from quiz_attempts
          where created_at >= now() - interval '7 days'
          union all
          select user_id, updated_at as activity_time from progress
          where updated_at >= now() - interval '7 days'
        ) all_activities
        join users u on u.id = all_activities.user_id
        where u.role = 'STUDENT'
        group by user_id
      )
      select
        count(*)::int as total_active,
        sum(case when active_days > 1 then 1 else 0 end)::int as retained
      from student_active_days
    `);
    const totalActiveStudents = Number(retentionResult.rows[0]?.total_active ?? 0);
    const retainedStudents = Number(retentionResult.rows[0]?.retained ?? 0);
    const retentionRate = totalActiveStudents === 0 ? 0 : Number(((retainedStudents / totalActiveStudents) * 100).toFixed(1));

    // 5. Average study time
    const studyTimeResult = await this.pool.query<{ total_minutes: string }>(`
      select coalesce(sum(l.estimated_minutes), 0)::int as total_minutes
      from progress p
      join lessons l on p.lesson_id = l.id
      join users u on u.id = p.user_id
      where p.status = 'COMPLETED' and u.role = 'STUDENT'
    `);
    const totalMinutes = Number(studyTimeResult.rows[0]?.total_minutes ?? 0);
    const averageStudyTime = totalStudents === 0 ? 0 : Number((totalMinutes / totalStudents).toFixed(1));

    // 6. Most viewed / least viewed / lessons without quiz
    const [mostViewedLessons, leastViewedLessons, lessonsWithoutQuiz] = await Promise.all([
      this.pool.query<{ lesson_id: string; title: string; chapter_title: string; view_count: number }>(`
        select l.id as lesson_id, l.title, c.title as chapter_title, count(p.id)::int as view_count
        from lessons l
        join chapters c on l.chapter_id = c.id
        left join progress p on p.lesson_id = l.id
        where l.is_published = true
        group by l.id, l.title, c.title, l.order_index
        order by view_count desc, l.order_index asc
        limit 5
      `),
      this.pool.query<{ lesson_id: string; title: string; chapter_title: string; view_count: number }>(`
        select l.id as lesson_id, l.title, c.title as chapter_title, count(p.id)::int as view_count
        from lessons l
        join chapters c on l.chapter_id = c.id
        left join progress p on p.lesson_id = l.id
        where l.is_published = true
        group by l.id, l.title, c.title, l.order_index
        order by view_count asc, l.order_index asc
        limit 5
      `),
      this.pool.query<{ lesson_id: string; title: string; chapter_title: string }>(`
        select l.id as lesson_id, l.title, c.title as chapter_title
        from lessons l
        join chapters c on l.chapter_id = c.id
        left join questions q on q.lesson_id = l.id
        where l.is_published = true
        group by l.id, l.title, c.title, c.order_index, l.order_index
        having count(q.id) = 0
        order by c.order_index asc, l.order_index asc
      `),
    ]);

    // 7. Completion Rate calculations (fixed)
    const completedProgressResult = await this.pool.query<{ count: string }>(`
      select count(*)::int as count
      from progress p
      join users u on p.user_id = u.id
      where p.status = 'COMPLETED' and u.role = 'STUDENT'
    `);
    const totalCompletedProgress = Number(completedProgressResult.rows[0]?.count ?? 0);
    const possibleCompletions = totalStudents * totalLessons;
    const completionRate = possibleCompletions === 0 ? 0 : Number((totalCompletedProgress / possibleCompletions).toFixed(4));

    // Per chapter completion rate
    const completionByChapterRaw = await this.pool.query<{
      chapter_id: string;
      title: string;
      total_lessons: number;
      completed_count: number;
    }>(`
      select c.id as chapter_id,
             c.title,
             count(distinct l.id)::int as total_lessons,
             coalesce(sum(case when p.status = 'COMPLETED' then 1 else 0 end), 0)::int as completed_count
      from chapters c
      left join lessons l on l.chapter_id = c.id and l.is_published = true
      left join progress p on p.lesson_id = l.id and p.user_id in (select id from users where role = 'STUDENT')
      group by c.id, c.title, c.order_index
      order by c.order_index asc
    `);

    // 8. Quiz assessments (avg score, difficult questions, trend)
    const [avgScoreResult, difficultQuestionsRaw, quizAttemptsTrendRaw] = await Promise.all([
      this.pool.query<{ avg_score: string }>(`select coalesce(avg(score), 0)::float as avg_score from quiz_attempts`),
      this.pool.query<{
        id: string;
        question: string;
        lesson_title: string;
        total_attempts: number;
        wrong_count: number;
        error_rate: number;
      }>(`
        select
          q.id,
          q.question_text as question,
          l.title as lesson_title,
          count(ans."questionId")::int as total_attempts,
          sum(case when ans."selectedOption" != q.correct_option then 1 else 0 end)::int as wrong_count,
          round(cast(sum(case when ans."selectedOption" != q.correct_option then 1 else 0 end) as numeric) / count(ans."questionId") * 100, 1)::float as error_rate
        from quiz_attempts qa,
        lateral jsonb_to_recordset(qa.answers_json) as ans("questionId" text, "selectedOption" int)
        join questions q on q.id = ans."questionId"
        join lessons l on q.lesson_id = l.id
        group by q.id, q.question_text, l.title
        order by error_rate desc, total_attempts desc
        limit 5
      `),
      this.pool.query<{ date: string; count: number }>(`
        select to_char(day, 'YYYY-MM-DD') as date, coalesce(stats.attempts_count, 0)::int as count
        from (
          select (current_date - val)::date as day
          from generate_series(0, 6) as val
        ) days
        left join (
          select date_trunc('day', created_at)::date as day, count(*) as attempts_count
          from quiz_attempts
          where created_at >= current_date - interval '7 days'
          group by 1
        ) stats using (day)
        order by date asc
      `),
    ]);

    const averageScore = Number(Number(avgScoreResult.rows[0]?.avg_score ?? 0).toFixed(2));

    return {
      activeStudents: activeUsers7Days, // keep variable name compatibility
      totalUsers,
      totalAttempts,
      completionRate,
      totalBadgesAwarded: totalBadges,
      activeUsers7Days,
      activeUsers30Days,
      newUsersThisWeek,
      newUsersGrowth,
      attemptsThisWeek,
      attemptsGrowth,
      completionsThisWeek,
      completionsGrowth,
      retentionRate,
      averageStudyTime,
      mostViewedLessons: mostViewedLessons.rows.map((row) => ({
        lessonId: row.lesson_id,
        title: row.title,
        chapterTitle: row.chapter_title,
        viewCount: row.view_count,
      })),
      leastViewedLessons: leastViewedLessons.rows.map((row) => ({
        lessonId: row.lesson_id,
        title: row.title,
        chapterTitle: row.chapter_title,
        viewCount: row.view_count,
      })),
      lessonsWithoutQuiz: lessonsWithoutQuiz.rows.map((row) => ({
        lessonId: row.lesson_id,
        title: row.title,
        chapterTitle: row.chapter_title,
      })),
      completionByChapter: completionByChapterRaw.rows.map((row) => {
        const tLessons = Number(row.total_lessons ?? 0);
        const cCount = Number(row.completed_count ?? 0);
        const denom = totalStudents * tLessons;
        return {
          chapterId: row.chapter_id,
          title: row.title,
          completedCount: cCount,
          totalLessons: tLessons,
          completionRate: denom === 0 ? 0 : Number((cCount / denom).toFixed(4)),
        };
      }),
      averageScore,
      difficultQuestions: difficultQuestionsRaw.rows,
      quizAttemptsTrend: quizAttemptsTrendRaw.rows,
    };
  }

  toPublicUser(user: ReturnType<DatabaseRepository['mapUser']>) {
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
      orderIndex: row.order_index,
    };
  }

  private mapAttempt(row: AttemptRow) {
    return {
      id: row.id,
      userId: row.user_id,
      lessonId: row.lesson_id,
      answers: row.answers_json,
      score: Number(row.score),
      correctCount: row.correct_count,
      totalQuestions: row.total_questions,
      coinsEarned: row.coins_earned,
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
      updatedAt: row.updated_at,
    };
  }

  private mapBadge(row: BadgeRow) {
    return {
      id: row.id,
      name: row.name,
      description: row.description,
      icon: row.icon,
      ruleKey: row.rule_key,
    };
  }
}
