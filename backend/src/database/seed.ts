import { readFile } from "node:fs/promises";
import { join } from "node:path";

import * as bcrypt from "bcrypt";
import { config } from "dotenv";
import { Pool } from "pg";

config();

type SeedUser = {
  id: string;
  name: string;
  email: string;
  password: string;
  role: "STUDENT" | "TEACHER" | "ADMIN";
  coins: number;
};

async function readJson<T>(fileName: string): Promise<T> {
  const file = await readFile(
    join(__dirname, "..", "..", "..", "seed-data", fileName),
    "utf8",
  );
  return JSON.parse(file) as T;
}

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL is required");
  }

  const pool = new Pool({ connectionString });
  const schema = await readFile(join(__dirname, "schema.sql"), "utf8");
  const client = await pool.connect();

  try {
    await client.query("BEGIN");
    await client.query(schema);
    await client.query('alter table chapters drop constraint if exists chapters_order_index_key');

    const users = await readJson<SeedUser[]>("users.json");
    const chapters = await readJson<
      Array<{
        id: string;
        title: string;
        description: string;
        orderIndex: number;
      }>
    >("chapters.json");
    const lessons = await readJson<
      Array<{
        id: string;
        chapterId: string;
        title: string;
        contentMarkdown: string;
        formulaLatex: string | null;
        estimatedMinutes: number;
        orderIndex: number;
      }>
    >("lessons.json");
    const simulations = await readJson<
      Array<{
        id: string;
        lessonId: string;
        title: string;
        formula: string;
        expression: string;
        variables: unknown;
        result: unknown;
      }>
    >("simulations.json");
    const questions = await readJson<
      Array<{
        id: string;
        lessonId: string;
        question: string;
        options: string[];
        correctOption: number;
        explanation: string;
        difficulty?: "EASY" | "MEDIUM" | "HARD";
      }>
    >("questions.json");
    const badges = await readJson<
      Array<{
        id: string;
        name: string;
        description: string;
        icon: string;
        ruleKey: string;
        conditionValue?: string | null;
        metadata?: unknown;
      }>
    >("badges.json");

    for (const user of users) {
      const passwordHash = await bcrypt.hash(user.password, 10);
      await client.query(
        `insert into users (name, email, password_hash, role, coins)
         values ($1, $2, $3, $4, $5)
         on conflict (email) do update set
           name = excluded.name,
           password_hash = excluded.password_hash,
           role = excluded.role,
           coins = excluded.coins,
           updated_at = now()`,
        [user.name, user.email, passwordHash, user.role, user.coins],
      );
    }

    for (const chapter of chapters) {
      await client.query(
        `insert into chapters (id, title, description, order_index)
         values ($1, $2, $3, $4)
         on conflict (id) do update set
           title = excluded.title,
           description = excluded.description,
           order_index = excluded.order_index,
           updated_at = now()`,
        [chapter.id, chapter.title, chapter.description, chapter.orderIndex],
      );
    }

    for (const lesson of lessons) {
      await client.query(
        `insert into lessons
          (id, chapter_id, title, content_markdown, formula_latex, estimated_minutes, order_index)
         values ($1, $2, $3, $4, $5, $6, $7)
         on conflict (id) do update set
           chapter_id = excluded.chapter_id,
           title = excluded.title,
           content_markdown = excluded.content_markdown,
           formula_latex = excluded.formula_latex,
           estimated_minutes = excluded.estimated_minutes,
           order_index = excluded.order_index,
           updated_at = now()`,
        [
          lesson.id,
          lesson.chapterId,
          lesson.title,
          lesson.contentMarkdown,
          lesson.formulaLatex,
          lesson.estimatedMinutes,
          lesson.orderIndex,
        ],
      );
    }

    for (const simulation of simulations) {
      await client.query(
        `insert into simulations
          (id, lesson_id, title, formula, expression, variables_json, result_json)
         values ($1, $2, $3, $4, $5, $6::jsonb, $7::jsonb)
         on conflict (id) do update set
           lesson_id = excluded.lesson_id,
           title = excluded.title,
           formula = excluded.formula,
           expression = excluded.expression,
           variables_json = excluded.variables_json,
           result_json = excluded.result_json`,
        [
          simulation.id,
          simulation.lessonId,
          simulation.title,
          simulation.formula,
          simulation.expression,
          JSON.stringify(simulation.variables),
          JSON.stringify(simulation.result),
        ],
      );
    }

    for (const [index, question] of questions.entries()) {
      await client.query(
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
           order_index = excluded.order_index`,
        [
          question.id,
          question.lessonId,
          question.question,
          JSON.stringify(question.options),
          question.correctOption,
          question.explanation,
          question.difficulty ?? 'MEDIUM',
          (index % 5) + 1,
        ],
      );
    }

    for (const badge of badges) {
      await client.query(
        `insert into badges (id, name, description, icon, rule_key, condition_value, metadata_json)
         values ($1, $2, $3, $4, $5, $6, $7::jsonb)
         on conflict (id) do update set
           name = excluded.name,
           description = excluded.description,
           icon = excluded.icon,
           rule_key = excluded.rule_key,
           condition_value = excluded.condition_value,
           metadata_json = excluded.metadata_json`,
        [
          badge.id,
          badge.name,
          badge.description,
          badge.icon,
          badge.ruleKey,
          badge.conditionValue ?? null,
          JSON.stringify(badge.metadata ?? {}),
        ],
      );
    }

    // Seed mock student activity data (attempts, progress, downloads)
    await client.query('truncate table quiz_attempts cascade');
    await client.query('truncate table progress cascade');
    await client.query('truncate table downloaded_lessons cascade');

    const userRows = await client.query<{ id: string; email: string }>('select id, email from users');
    const userMap = new Map<string, string>();
    for (const row of userRows.rows) {
      userMap.set(row.email, row.id);
    }

    const namId = userMap.get('nam@example.com')!;
    const maiId = userMap.get('mai@example.com')!;
    const hungId = userMap.get('hung@example.com')!;
    const lanId = userMap.get('lan@example.com')!;
    const ducId = userMap.get('duc@example.com')!;

    // Align user registration created_at times to match mockup relative timestamps
    await client.query(`update users set created_at = now() - interval '1 hour' where email = 'hung@example.com'`);
    await client.query(`update users set created_at = now() - interval '5 hours' where email = 'lan@example.com'`);
    await client.query(`update users set created_at = now() - interval '1 day' where email = 'mai@example.com'`);
    await client.query(`update users set created_at = now() - interval '2 days' where email = 'nam@example.com'`);

    // 1. Seed quiz attempts over the last 7 days to simulate real activity chart data
    const chartAttempts = [
      // 6 days ago (Monday)
      { userId: namId, lessonId: 'motion-1', score: 7.0, correct: 7, total: 10, daysAgo: 6 },
      { userId: maiId, lessonId: 'motion-1', score: 8.0, correct: 8, total: 10, daysAgo: 6 },
      // 5 days ago (Tuesday)
      { userId: hungId, lessonId: 'motion-1', score: 6.0, correct: 6, total: 10, daysAgo: 5 },
      { userId: lanId, lessonId: 'motion-2', score: 5.0, correct: 5, total: 10, daysAgo: 5 },
      { userId: ducId, lessonId: 'motion-2', score: 7.0, correct: 7, total: 10, daysAgo: 5 },
      // 4 days ago (Wednesday)
      { userId: namId, lessonId: 'force-1', score: 8.0, correct: 8, total: 10, daysAgo: 4 },
      { userId: maiId, lessonId: 'force-1', score: 9.0, correct: 9, total: 10, daysAgo: 4 },
      // 3 days ago (Thursday)
      { userId: hungId, lessonId: 'force-1', score: 5.0, correct: 5, total: 10, daysAgo: 3 },
      { userId: lanId, lessonId: 'force-2', score: 4.0, correct: 4, total: 10, daysAgo: 3 },
      { userId: ducId, lessonId: 'force-2', score: 6.0, correct: 6, total: 10, daysAgo: 3 },
      { userId: namId, lessonId: 'electric-1', score: 7.0, correct: 7, total: 10, daysAgo: 3 },
      // 2 days ago (Friday)
      { userId: maiId, lessonId: 'electric-1', score: 8.0, correct: 8, total: 10, daysAgo: 2 },
      { userId: hungId, lessonId: 'electric-1', score: 6.0, correct: 6, total: 10, daysAgo: 2 },
      { userId: lanId, lessonId: 'electric-2', score: 7.0, correct: 7, total: 10, daysAgo: 2 },
      { userId: ducId, lessonId: 'electric-2', score: 8.5, correct: 8, total: 10, daysAgo: 2 },
      { userId: namId, lessonId: 'motion-1', score: 9.0, correct: 9, total: 10, daysAgo: 2 },
      // 1 day ago (Saturday)
      { userId: maiId, lessonId: 'motion-2', score: 10.0, correct: 10, total: 10, daysAgo: 1 },
      { userId: hungId, lessonId: 'motion-2', score: 8.0, correct: 8, total: 10, daysAgo: 1 },
      { userId: lanId, lessonId: 'force-1', score: 7.0, correct: 7, total: 10, daysAgo: 1 },
      { userId: ducId, lessonId: 'force-1', score: 7.5, correct: 7, total: 10, daysAgo: 1 },
      { userId: namId, lessonId: 'force-2', score: 5.0, correct: 5, total: 10, daysAgo: 1 },
      { userId: maiId, lessonId: 'force-2', score: 6.0, correct: 6, total: 10, daysAgo: 1 },
      // Today (Sunday/CN)
      { userId: maiId, lessonId: 'motion-1', score: 9.5, correct: 9, total: 10, daysAgo: 0 },
      { userId: namId, lessonId: 'motion-2', score: 8.0, correct: 8, total: 10, daysAgo: 0 },
      { userId: lanId, lessonId: 'electric-1', score: 9.0, correct: 9, total: 10, daysAgo: 0 },
      { userId: ducId, lessonId: 'electric-2', score: 8.5, correct: 8, total: 10, daysAgo: 0 },
    ];

    for (const att of chartAttempts) {
      await client.query(
        `insert into quiz_attempts (user_id, lesson_id, answers_json, score, correct_count, total_questions, created_at)
         values ($1, $2, '[]'::jsonb, $3, $4, $5, now() - $6 * interval '1 day')`,
        [att.userId, att.lessonId, att.score, att.correct, att.total, att.daysAgo],
      );
    }

    // 2. Seed progress
    // Nguyễn Văn Nam starting lesson motion-2 (Vận tốc trung bình)
    await client.query(
      `insert into progress (user_id, lesson_id, status, progress_percent, updated_at)
       values ($1, 'motion-2', 'IN_PROGRESS', 50, now() - interval '12 minutes')`,
      [namId],
    );

    // 3. Seed downloaded lessons
    // Phạm Thị Lan downloading force-2 (Lực đẩy Ác-si-mét)
    await client.query(
      `insert into downloaded_lessons (user_id, lesson_id, downloaded_at)
       values ($1, 'force-2', now() - interval '2 hours')`,
      [lanId],
    );

    await client.query('COMMIT');
    console.log('Database schema and seed data are ready.');
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

void main();
