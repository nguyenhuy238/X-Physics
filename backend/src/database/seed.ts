import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

import * as bcrypt from 'bcrypt';
import { Pool } from 'pg';

type SeedUser = {
  id: string;
  name: string;
  email: string;
  password: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
  coins: number;
};

async function readJson<T>(fileName: string): Promise<T> {
  const file = await readFile(join(__dirname, '..', '..', '..', 'seed-data', fileName), 'utf8');
  return JSON.parse(file) as T;
}

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL is required');
  }

  const pool = new Pool({ connectionString });
  const schema = await readFile(join(__dirname, 'schema.sql'), 'utf8');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    await client.query(schema);

    const users = await readJson<SeedUser[]>('users.json');
    const chapters = await readJson<
      Array<{ id: string; title: string; description: string; orderIndex: number }>
    >('chapters.json');
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
    >('lessons.json');
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
    >('simulations.json');
    const questions = await readJson<
      Array<{
        id: string;
        lessonId: string;
        question: string;
        options: string[];
        correctOption: number;
        explanation: string;
      }>
    >('questions.json');
    const badges = await readJson<
      Array<{
        id: string;
        name: string;
        description: string;
        icon: string;
        ruleKey: string;
      }>
    >('badges.json');

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
          (id, lesson_id, question_text, options_json, correct_option, explanation, order_index)
         values ($1, $2, $3, $4::jsonb, $5, $6, $7)
         on conflict (id) do update set
           lesson_id = excluded.lesson_id,
           question_text = excluded.question_text,
           options_json = excluded.options_json,
           correct_option = excluded.correct_option,
           explanation = excluded.explanation,
           order_index = excluded.order_index`,
        [
          question.id,
          question.lessonId,
          question.question,
          JSON.stringify(question.options),
          question.correctOption,
          question.explanation,
          (index % 5) + 1,
        ],
      );
    }

    for (const badge of badges) {
      await client.query(
        `insert into badges (id, name, description, icon, rule_key)
         values ($1, $2, $3, $4, $5)
         on conflict (id) do update set
           name = excluded.name,
           description = excluded.description,
           icon = excluded.icon,
           rule_key = excluded.rule_key`,
        [badge.id, badge.name, badge.description, badge.icon, badge.ruleKey],
      );
    }

    await client.query('COMMIT');
    console.log('Database schema and seed data are ready.');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

void main();
