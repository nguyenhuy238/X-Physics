import { Inject, Injectable, NotFoundException } from '@nestjs/common';
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
}

interface ChapterRow {
  id: string;
  title: string;
  description: string;
  order_index: number;
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

  async adminUsers() {
    const result = await this.pool.query<UserRow>(
      'select * from users order by created_at desc',
    );
    return result.rows.map((row) => this.toPublicUser(this.mapUser(row)));
  }

  async statistics() {
    const [users, attempts, completed, lessons] = await Promise.all([
      this.pool.query<{ count: string }>('select count(*) from users'),
      this.pool.query<{ count: string }>('select count(*) from quiz_attempts'),
      this.pool.query<{ count: string }>(
        "select count(*) from progress where status = 'COMPLETED'",
      ),
      this.pool.query<{ count: string }>(
        'select count(*) from lessons where is_published = true',
      ),
    ]);
    const completedCount = Number(completed.rows[0]?.count ?? 0);
    const lessonCount = Number(lessons.rows[0]?.count ?? 0);
    return {
      totalUsers: Number(users.rows[0]?.count ?? 0),
      totalAttempts: Number(attempts.rows[0]?.count ?? 0),
      completionRate: lessonCount === 0 ? 0 : completedCount / lessonCount,
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
