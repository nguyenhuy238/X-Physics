import { config } from "dotenv";
import { Pool, PoolClient } from "pg";

config();

const practiceQuestions = [
  {
    id: "practice-motion-1-1",
    lessonId: "motion-1",
    question:
      "Một vật chuyển động đều đi được 36 m trong 9 s. Vận tốc của vật là bao nhiêu?",
    options: ["3 m/s", "4 m/s", "9 m/s", "27 m/s"],
    correctOption: 1,
    explanation: "Vận tốc v = s / t = 36 / 9 = 4 m/s.",
    hint: "Lấy quãng đường chia cho thời gian.",
    isOfflineEnabled: true,
    difficulty: "EASY",
    orderIndex: 1,
  },
  {
    id: "practice-motion-1-2",
    lessonId: "motion-1",
    question:
      "Một xe chuyển động đều với vận tốc 5 m/s trong 8 s. Quãng đường xe đi được là bao nhiêu?",
    options: ["13 m", "20 m", "40 m", "80 m"],
    correctOption: 2,
    explanation: "Quãng đường s = v x t = 5 x 8 = 40 m.",
    hint: "Dùng công thức s = v x t.",
    isOfflineEnabled: true,
    difficulty: "EASY",
    orderIndex: 2,
  },
  {
    id: "practice-motion-2-1",
    lessonId: "motion-2",
    question:
      "Một học sinh đi 120 m trong 60 s. Vận tốc trung bình là bao nhiêu?",
    options: ["0,5 m/s", "1 m/s", "2 m/s", "4 m/s"],
    correctOption: 2,
    explanation: "Vận tốc trung bình v = s / t = 120 / 60 = 2 m/s.",
    hint: "Chú ý đơn vị m và s đã cùng hệ SI.",
    isOfflineEnabled: true,
    difficulty: "EASY",
    orderIndex: 1,
  },
  {
    id: "practice-force-1-1",
    lessonId: "force-1",
    question:
      "Một lực 100 N tác dụng lên diện tích 2 m². Áp suất tạo ra là bao nhiêu?",
    options: ["20 Pa", "50 Pa", "100 Pa", "200 Pa"],
    correctOption: 1,
    explanation: "Áp suất p = F / S = 100 / 2 = 50 Pa.",
    hint: "Áp suất bằng áp lực chia cho diện tích bị ép.",
    isOfflineEnabled: true,
    difficulty: "MEDIUM",
    orderIndex: 1,
  },
  {
    id: "practice-electric-1-1",
    lessonId: "electric-1",
    question:
      "Đặt hiệu điện thế 12 V vào điện trở 6 Ω. Cường độ dòng điện là bao nhiêu?",
    options: ["0,5 A", "2 A", "6 A", "18 A"],
    correctOption: 1,
    explanation: "Theo định luật Ohm: I = U / R = 12 / 6 = 2 A.",
    hint: "Dòng điện tỉ lệ thuận với hiệu điện thế và tỉ lệ nghịch với điện trở.",
    isOfflineEnabled: false,
    difficulty: "MEDIUM",
    orderIndex: 1,
  },
] as const;

const practiceBadges = [
  {
    id: "practice-starter",
    name: "Chăm luyện tập",
    description: "Hoàn thành 5 phiên luyện tập.",
    icon: "fitness_center",
    ruleKey: "practice_count",
    conditionValue: "5",
  },
  {
    id: "practice-streak-3",
    name: "Chuỗi luyện tập 3 ngày",
    description: "Luyện tập 3 ngày liên tiếp.",
    icon: "local_fire_department",
    ruleKey: "practice_streak",
    conditionValue: "3",
  },
] as const;

const sampleSessions = [
  {
    id: "sample-practice-nam-motion-1-20260719",
    email: "nam@example.com",
    lessonId: "motion-1",
    questionsAttempted: 2,
    correctCount: 2,
    answers: [
      { questionId: "practice-motion-1-1", selectedOption: 1, isCorrect: true },
      { questionId: "practice-motion-1-2", selectedOption: 2, isCorrect: true },
    ],
    startedAt: "2026-07-19T02:00:00.000Z",
    completedAt: "2026-07-19T02:06:00.000Z",
    coins: 5,
  },
  {
    id: "sample-practice-nam-motion-2-20260720",
    email: "nam@example.com",
    lessonId: "motion-2",
    questionsAttempted: 1,
    correctCount: 1,
    answers: [
      { questionId: "practice-motion-2-1", selectedOption: 2, isCorrect: true },
    ],
    startedAt: "2026-07-20T02:10:00.000Z",
    completedAt: "2026-07-20T02:15:00.000Z",
    coins: 5,
  },
  {
    id: "sample-practice-mai-force-1-20260720",
    email: "mai@example.com",
    lessonId: "force-1",
    questionsAttempted: 1,
    correctCount: 0,
    answers: [
      { questionId: "practice-force-1-1", selectedOption: 3, isCorrect: false },
    ],
    startedAt: "2026-07-20T03:00:00.000Z",
    completedAt: "2026-07-20T03:04:00.000Z",
    coins: 2,
  },
] as const;

async function ensurePracticeSchema(client: PoolClient) {
  await client.query(`
    create table if not exists practice_questions (
      id varchar(100) primary key,
      lesson_id varchar(80) not null references lessons(id) on delete cascade,
      question_text text not null,
      options_json jsonb not null,
      correct_option integer not null,
      explanation text not null,
      hint text,
      is_offline_enabled boolean not null default false,
      difficulty varchar(30) not null default 'MEDIUM',
      order_index integer not null,
      created_at timestamptz not null default now(),
      updated_at timestamptz not null default now()
    )
  `);
  await client.query(`
    create unique index if not exists practice_questions_lesson_order_unique_idx
    on practice_questions(lesson_id, order_index)
  `);
  await client.query(`
    create table if not exists practice_sessions (
      id varchar(120) primary key,
      user_id uuid not null references users(id) on delete cascade,
      lesson_id varchar(80) not null references lessons(id) on delete cascade,
      questions_attempted integer not null,
      correct_count integer not null,
      answers_json jsonb not null default '[]'::jsonb,
      started_at timestamptz not null,
      completed_at timestamptz not null,
      synced_at timestamptz not null default now(),
      created_at timestamptz not null default now()
    )
  `);
}

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL is required");
  }

  const pool = new Pool({ connectionString });
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await ensurePracticeSchema(client);
    let insertedSessions = 0;
    let skippedSessions = 0;
    let awardedCoins = 0;

    for (const question of practiceQuestions) {
      await client.query(
        `insert into practice_questions
          (id, lesson_id, question_text, options_json, correct_option, explanation, hint, is_offline_enabled, difficulty, order_index)
         values ($1, $2, $3, $4::jsonb, $5, $6, $7, $8, $9, $10)
         on conflict (id) do update set
           lesson_id = excluded.lesson_id,
           question_text = excluded.question_text,
           options_json = excluded.options_json,
           correct_option = excluded.correct_option,
           explanation = excluded.explanation,
           hint = excluded.hint,
           is_offline_enabled = excluded.is_offline_enabled,
           difficulty = excluded.difficulty,
           order_index = excluded.order_index,
           updated_at = now()`,
        [
          question.id,
          question.lessonId,
          question.question,
          JSON.stringify(question.options),
          question.correctOption,
          question.explanation,
          question.hint,
          question.isOfflineEnabled,
          question.difficulty,
          question.orderIndex,
        ],
      );
    }

    for (const badge of practiceBadges) {
      await client.query(
        `insert into badges (id, name, description, icon, rule_key, condition_value, metadata_json)
         values ($1, $2, $3, $4, $5, $6, '{}'::jsonb)
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
          badge.conditionValue,
        ],
      );
    }

    for (const session of sampleSessions) {
      const userResult = await client.query<{ id: string }>(
        "select id from users where email = $1",
        [session.email],
      );
      const userId = userResult.rows[0]?.id;
      if (!userId) {
        skippedSessions++;
        continue;
      }

      const insertResult = await client.query<{ inserted: number }>(
        `with inserted as (
           insert into practice_sessions
             (id, user_id, lesson_id, questions_attempted, correct_count, answers_json, started_at, completed_at, synced_at)
           values ($1, $2, $3, $4, $5, $6::jsonb, $7::timestamptz, $8::timestamptz, now())
           on conflict (id) do nothing
           returning 1
         )
         select count(*)::int as inserted from inserted`,
        [
          session.id,
          userId,
          session.lessonId,
          session.questionsAttempted,
          session.correctCount,
          JSON.stringify(session.answers),
          session.startedAt,
          session.completedAt,
        ],
      );
      const inserted = Number(insertResult.rows[0]?.inserted ?? 0) > 0;
      if (inserted) {
        insertedSessions++;
        const rewardResult = await client.query<{ coins: number }>(
          `insert into reward_events
            (user_id, reward_type, source_type, source_id, reward_level, coins, metadata_json)
           values ($1, 'PRACTICE_SESSION', 'PRACTICE_SESSION', $2, 0, $3, $4::jsonb)
           on conflict (user_id, reward_type, source_type, source_id, reward_level) do nothing
           returning coins`,
          [
            userId,
            session.id,
            session.coins,
            JSON.stringify({
              lessonId: session.lessonId,
              questionsAttempted: session.questionsAttempted,
              correctCount: session.correctCount,
              sample: true,
            }),
          ],
        );
        const coins = Number(rewardResult.rows[0]?.coins ?? 0);
        if (coins > 0) {
          awardedCoins += coins;
          await client.query(
            "update users set coins = coins + $2, updated_at = now() where id = $1",
            [userId, coins],
          );
        }
      }
    }

    await client.query("COMMIT");
    console.log(
      `Inserted sample Practice data: ${practiceQuestions.length} questions, ${practiceBadges.length} badges, ${insertedSessions} new sessions, ${awardedCoins} coins awarded, ${skippedSessions} sessions skipped because sample users were missing.`,
    );
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

void main();
