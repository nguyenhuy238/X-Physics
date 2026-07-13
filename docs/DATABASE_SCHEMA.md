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
| coins         | integer      | default 0               |
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
| order_index    | integer      | not null      |

Index: `(lesson_id, order_index)`.

## quiz_attempts

| Column           | Type         | Constraint    |
| ---------------- | ------------ | ------------- |
| id               | uuid         | primary key   |
| user_id          | uuid         | fk users.id   |
| lesson_id        | varchar(80)  | fk lessons.id |
| answers_json     | jsonb        | not null      |
| score            | numeric(4,2) | not null      |
| correct_count    | integer      | not null      |
| total_questions  | integer      | not null      |
| duration_seconds | integer      | default 0     |
| coins_earned     | integer      | default 0     |
| created_at       | timestamptz  | not null      |

Index: `(user_id, lesson_id)`.

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
