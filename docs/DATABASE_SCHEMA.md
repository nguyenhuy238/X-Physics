# Database Schema

Suggested database: PostgreSQL.

## users

| Column        | Type         | Constraint              |
| ------------- | ------------ | ----------------------- |
| id            | uuid         | primary key             |
| name          | varchar(120) | not null                |
| email         | varchar(180) | unique, not null        |
| password_hash | text         | not null                |
| role          | varchar(30)  | STUDENT, TEACHER, ADMIN |
| coins         | integer      | default 0, >= 0         |
| created_at    | timestamptz  | not null                |
| updated_at    | timestamptz  | not null                |

Index: unique `email`.

## chapters

| Column       | Type         | Constraint       |
| ------------ | ------------ | ---------------- |
| id           | varchar(80)  | primary key      |
| title        | varchar(180) | not null         |
| description  | text         | not null         |
| order_index  | integer      | unique, not null |
| is_published | boolean      | default true     |
| created_at   | timestamptz  | not null         |
| updated_at   | timestamptz  | not null         |

## lessons

| Column            | Type         | Constraint     |
| ----------------- | ------------ | -------------- |
| id                | varchar(80)  | primary key    |
| chapter_id        | varchar(80)  | fk chapters.id |
| title             | varchar(180) | not null       |
| content_markdown  | text         | not null       |
| formula_latex     | text         | nullable       |
| estimated_minutes | integer      | default 10     |
| order_index       | integer      | not null       |
| is_published      | boolean      | default true   |
| created_at        | timestamptz  | not null       |
| updated_at        | timestamptz  | not null       |

Index: `(chapter_id, order_index)`.

## simulations

| Column         | Type         | Constraint    |
| -------------- | ------------ | ------------- |
| id             | varchar(80)  | primary key   |
| lesson_id      | varchar(80)  | fk lessons.id |
| title          | varchar(180) | not null      |
| formula        | text         | not null      |
| expression     | varchar(120) | not null      |
| variables_json | jsonb        | not null      |
| result_json    | jsonb        | not null      |

Index: `lesson_id`.

## questions

| Column         | Type         | Constraint    |
| -------------- | ------------ | ------------- |
| id             | varchar(100) | primary key   |
| lesson_id      | varchar(80)  | fk lessons.id |
| question_text  | text         | not null      |
| options_json   | jsonb        | not null      |
| correct_option | integer      | not null      |
| explanation    | text         | not null      |
| difficulty     | varchar(20)  | EASY/MEDIUM/HARD, default MEDIUM |
| order_index    | integer      | not null      |

Index: `(lesson_id, order_index)`.
Unique: `(lesson_id, order_index)`.
Checks:

- `questions_correct_option_range`: `correct_option between 0 and 3`.
- `questions_options_json_four_items`: `options_json` must be a JSON array with
  exactly 4 items.

Ordering convention: question order starts at `1` inside each lesson and is kept
compact by Admin create/update/delete/reorder transactions.

Existing databases should run:

```sql
alter table questions
  add column if not exists difficulty varchar(20) not null default 'MEDIUM';

alter table questions
  add constraint questions_difficulty_check
  check (difficulty in ('EASY', 'MEDIUM', 'HARD'));
```

If `questions_difficulty_check` already exists, skip the second statement.

Existing-data compatibility checks before enabling V1 constraints:

```sql
select id, correct_option
from questions
where correct_option < 0 or correct_option > 3;

select id, options_json
from questions
where jsonb_typeof(options_json) <> 'array'
   or jsonb_array_length(options_json) <> 4;
```

Existing databases with duplicate or sparse order can compact safely with:

```sql
with ordered_questions as (
  select id, row_number() over (partition by lesson_id order by order_index asc, id asc) as next_order
  from questions
)
update questions q
set order_index = ordered_questions.next_order
from ordered_questions
where q.id = ordered_questions.id;
```

## quiz_attempts

| Column           | Type         | Constraint    |
| ---------------- | ------------ | ------------- |
| id               | uuid         | primary key   |
| user_id          | uuid         | fk users.id   |
| lesson_id        | varchar(80)  | fk lessons.id |
| answers_json     | jsonb        | not null      |
| review_json      | jsonb        | nullable      |
| score            | numeric(4,2) | not null      |
| correct_count    | integer      | not null      |
| total_questions  | integer      | not null      |
| duration_seconds | integer      | default 0     |
| coins_earned     | integer      | default 0     |
| created_at       | timestamptz  | not null      |

Index: `(user_id, lesson_id)`.
Checks:

- `quiz_attempts_score_range`: score is `0..10`.
- `quiz_attempts_counts_valid`: `correct_count >= 0`,
  `total_questions > 0`, and `correct_count <= total_questions`.
- `quiz_attempts_duration_non_negative`: `duration_seconds >= 0`.
- `quiz_attempts_coins_non_negative`: `coins_earned >= 0`.

Existing-data compatibility checks:

```sql
select id, score
from quiz_attempts
where score < 0 or score > 10;

select id, correct_count, total_questions
from quiz_attempts
where correct_count < 0
   or total_questions <= 0
   or correct_count > total_questions;

select id, duration_seconds
from quiz_attempts
where duration_seconds < 0;

select id, coins_earned
from quiz_attempts
where coins_earned < 0;
```

## progress

| Column            | Type         | Constraint                          |
| ----------------- | ------------ | ----------------------------------- |
| id                | uuid         | primary key                         |
| user_id           | uuid         | fk users.id                         |
| lesson_id         | varchar(80)  | fk lessons.id                       |
| status            | varchar(30)  | NOT_STARTED, IN_PROGRESS, COMPLETED |
| progress_percent  | integer      | 0..100                              |
| latest_quiz_score | numeric(4,2) | nullable                            |
| best_quiz_score   | numeric(4,2) | nullable                            |
| updated_at        | timestamptz  | not null                            |

Unique: `(user_id, lesson_id)`.

## reward_events

Auditable and idempotent coin rewards.

| Column        | Type         | Constraint   |
| ------------- | ------------ | ------------ |
| id            | uuid         | primary key  |
| user_id       | uuid         | fk users.id  |
| reward_type   | varchar(60)  | not null     |
| source_type   | varchar(60)  | not null     |
| source_id     | varchar(120) | not null     |
| reward_level  | integer      | default 0    |
| coins         | integer      | not null     |
| metadata_json | jsonb        | default `{}` |
| created_at    | timestamptz  | not null     |

Unique: `(user_id, reward_type, source_type, source_id, reward_level)`.

Reward event conventions:

- `LESSON_COMPLETE`, source `LESSON`, reward level `0`, coins `10`.
- `QUIZ_SCORE`, source `LESSON`, reward level `15`, `20`, or `30`; coins are best-score delta.
- `CHAPTER_COMPLETE`, source `CHAPTER`, reward level `0`, coins `50`.

## badges

| Column          | Type         | Constraint       |
| --------------- | ------------ | ---------------- |
| id              | varchar(80)  | primary key      |
| name            | varchar(120) | unique, not null |
| description     | text         | not null         |
| icon            | varchar(80)  | nullable         |
| rule_key        | varchar(120) | not null         |
| condition_value | varchar(120) | nullable         |
| metadata_json   | jsonb        | default `{}`     |

## user_badges

| Column     | Type        | Constraint   |
| ---------- | ----------- | ------------ |
| user_id    | uuid        | fk users.id  |
| badge_id   | varchar(80) | fk badges.id |
| awarded_at | timestamptz | not null     |

Primary key: `(user_id, badge_id)`.

## learning_activity

One valid learning activity per UTC day for streak calculation.

| Column        | Type         | Constraint  |
| ------------- | ------------ | ----------- |
| id            | uuid         | primary key |
| user_id       | uuid         | fk users.id |
| activity_date | date         | not null    |
| source_type   | varchar(60)  | not null    |
| source_id     | varchar(120) | not null    |
| created_at    | timestamptz  | not null    |

Unique: `(user_id, activity_date)`.

## downloaded_lessons

Server-side metadata is optional, but useful for analytics.

| Column           | Type         | Constraint    |
| ---------------- | ------------ | ------------- |
| id               | uuid         | primary key   |
| user_id          | uuid         | fk users.id   |
| lesson_id        | varchar(80)  | fk lessons.id |
| downloaded_at    | timestamptz  | not null      |
| client_device_id | varchar(120) | nullable      |

Unique: `(user_id, lesson_id, client_device_id)`.

## V1 ALTER TABLE SQL for existing databases

The project schema adds the new checks with `NOT VALID` so existing databases
can adopt the constraints without silently changing or deleting old rows. New
and updated rows are still protected. Run the compatibility queries above,
clean any reported rows manually, then run `VALIDATE CONSTRAINT`.

```sql
alter table users
  add constraint users_coins_non_negative
  check (coins >= 0) not valid;

alter table questions
  add constraint questions_correct_option_range
  check (correct_option between 0 and 3) not valid;

alter table questions
  add constraint questions_options_json_four_items
  check (
    jsonb_typeof(options_json) = 'array'
    and jsonb_array_length(options_json) = 4
  ) not valid;

alter table quiz_attempts
  add constraint quiz_attempts_score_range
  check (score between 0 and 10) not valid;

alter table quiz_attempts
  add constraint quiz_attempts_counts_valid
  check (
    correct_count >= 0
    and total_questions > 0
    and correct_count <= total_questions
  ) not valid;

alter table quiz_attempts
  add constraint quiz_attempts_duration_non_negative
  check (duration_seconds >= 0) not valid;

alter table quiz_attempts
  add constraint quiz_attempts_coins_non_negative
  check (coins_earned >= 0) not valid;
```

If a constraint already exists, skip its `alter table add constraint` statement.
After cleanup:

```sql
alter table users validate constraint users_coins_non_negative;
alter table questions validate constraint questions_correct_option_range;
alter table questions validate constraint questions_options_json_four_items;
alter table quiz_attempts validate constraint quiz_attempts_score_range;
alter table quiz_attempts validate constraint quiz_attempts_counts_valid;
alter table quiz_attempts validate constraint quiz_attempts_duration_non_negative;
alter table quiz_attempts validate constraint quiz_attempts_coins_non_negative;
```
