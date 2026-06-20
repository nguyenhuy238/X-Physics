# Database Schema

Suggested database: PostgreSQL.

## users

| Column | Type | Constraint |
| --- | --- | --- |
| id | uuid | primary key |
| name | varchar(120) | not null |
| email | varchar(180) | unique, not null |
| password_hash | text | not null |
| role | varchar(30) | STUDENT, TEACHER, ADMIN |
| coins | integer | default 0 |
| created_at | timestamptz | not null |
| updated_at | timestamptz | not null |

Index: unique `email`.

## chapters

| Column | Type | Constraint |
| --- | --- | --- |
| id | varchar(80) | primary key |
| title | varchar(180) | not null |
| description | text | not null |
| order_index | integer | unique, not null |
| is_published | boolean | default true |
| created_at | timestamptz | not null |
| updated_at | timestamptz | not null |

## lessons

| Column | Type | Constraint |
| --- | --- | --- |
| id | varchar(80) | primary key |
| chapter_id | varchar(80) | fk chapters.id |
| title | varchar(180) | not null |
| content_markdown | text | not null |
| formula_latex | text | nullable |
| estimated_minutes | integer | default 10 |
| order_index | integer | not null |
| is_published | boolean | default true |
| created_at | timestamptz | not null |
| updated_at | timestamptz | not null |

Index: `(chapter_id, order_index)`.

## simulations

| Column | Type | Constraint |
| --- | --- | --- |
| id | varchar(80) | primary key |
| lesson_id | varchar(80) | fk lessons.id |
| title | varchar(180) | not null |
| formula | text | not null |
| expression | varchar(120) | not null |
| variables_json | jsonb | not null |
| result_json | jsonb | not null |

Index: `lesson_id`.

## questions

| Column | Type | Constraint |
| --- | --- | --- |
| id | varchar(100) | primary key |
| lesson_id | varchar(80) | fk lessons.id |
| question_text | text | not null |
| options_json | jsonb | not null |
| correct_option | integer | not null |
| explanation | text | not null |
| order_index | integer | not null |

Index: `(lesson_id, order_index)`.

## quiz_attempts

| Column | Type | Constraint |
| --- | --- | --- |
| id | uuid | primary key |
| user_id | uuid | fk users.id |
| lesson_id | varchar(80) | fk lessons.id |
| answers_json | jsonb | not null |
| score | numeric(4,2) | not null |
| correct_count | integer | not null |
| total_questions | integer | not null |
| coins_earned | integer | default 0 |
| created_at | timestamptz | not null |

Index: `(user_id, lesson_id)`.

## progress

| Column | Type | Constraint |
| --- | --- | --- |
| id | uuid | primary key |
| user_id | uuid | fk users.id |
| lesson_id | varchar(80) | fk lessons.id |
| status | varchar(30) | NOT_STARTED, IN_PROGRESS, COMPLETED |
| progress_percent | integer | 0..100 |
| updated_at | timestamptz | not null |

Unique: `(user_id, lesson_id)`.

## badges

| Column | Type | Constraint |
| --- | --- | --- |
| id | varchar(80) | primary key |
| name | varchar(120) | unique, not null |
| description | text | not null |
| icon | varchar(80) | nullable |
| rule_key | varchar(120) | not null |

## user_badges

| Column | Type | Constraint |
| --- | --- | --- |
| user_id | uuid | fk users.id |
| badge_id | varchar(80) | fk badges.id |
| awarded_at | timestamptz | not null |

Primary key: `(user_id, badge_id)`.

## downloaded_lessons

Server-side metadata is optional, but useful for analytics.

| Column | Type | Constraint |
| --- | --- | --- |
| id | uuid | primary key |
| user_id | uuid | fk users.id |
| lesson_id | varchar(80) | fk lessons.id |
| downloaded_at | timestamptz | not null |
| client_device_id | varchar(120) | nullable |

Unique: `(user_id, lesson_id, client_device_id)`.
