create extension if not exists pgcrypto;

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  name varchar(120) not null,
  email varchar(180) unique not null,
  password_hash text not null,
  role varchar(30) not null check (role in ('STUDENT', 'TEACHER', 'ADMIN')),
  coins integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists chapters (
  id varchar(80) primary key,
  title varchar(180) not null,
  description text not null,
  order_index integer unique not null,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists lessons (
  id varchar(80) primary key,
  chapter_id varchar(80) not null references chapters(id) on delete cascade,
  title varchar(180) not null,
  content_markdown text not null,
  formula_latex text,
  estimated_minutes integer not null default 10,
  order_index integer not null,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists lessons_chapter_order_idx on lessons(chapter_id, order_index);

create table if not exists simulations (
  id varchar(80) primary key,
  lesson_id varchar(80) not null references lessons(id) on delete cascade,
  title varchar(180) not null,
  formula text not null,
  expression varchar(120) not null,
  variables_json jsonb not null,
  result_json jsonb not null
);

create index if not exists simulations_lesson_idx on simulations(lesson_id);

create table if not exists questions (
  id varchar(100) primary key,
  lesson_id varchar(80) not null references lessons(id) on delete cascade,
  question_text text not null,
  options_json jsonb not null,
  correct_option integer not null,
  explanation text not null,
  order_index integer not null
);

create index if not exists questions_lesson_order_idx on questions(lesson_id, order_index);

create table if not exists quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  lesson_id varchar(80) not null references lessons(id) on delete cascade,
  answers_json jsonb not null,
  score numeric(4,2) not null,
  correct_count integer not null,
  total_questions integer not null,
  coins_earned integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists quiz_attempts_user_lesson_idx on quiz_attempts(user_id, lesson_id);

create table if not exists progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  lesson_id varchar(80) not null references lessons(id) on delete cascade,
  status varchar(30) not null check (status in ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED')),
  progress_percent integer not null check (progress_percent between 0 and 100),
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);

create table if not exists badges (
  id varchar(80) primary key,
  name varchar(120) unique not null,
  description text not null,
  icon varchar(80),
  rule_key varchar(120) not null
);

create table if not exists user_badges (
  user_id uuid not null references users(id) on delete cascade,
  badge_id varchar(80) not null references badges(id) on delete cascade,
  awarded_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

create table if not exists downloaded_lessons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  lesson_id varchar(80) not null references lessons(id) on delete cascade,
  downloaded_at timestamptz not null default now(),
  client_device_id varchar(120),
  unique (user_id, lesson_id, client_device_id)
);
