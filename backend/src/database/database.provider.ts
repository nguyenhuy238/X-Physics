import { ConfigService } from "@nestjs/config";
import { Pool } from "pg";

import { DATABASE_POOL } from "./database.constants";

export const databaseProvider = {
  provide: DATABASE_POOL,
  inject: [ConfigService],
  useFactory: async (configService: ConfigService) => {
    const connectionString = configService.get<string>("DATABASE_URL");
    if (!connectionString) {
      throw new Error("DATABASE_URL is required for backend database access");
    }
    const pool = new Pool({ connectionString });
    await pool.query(`
      do $$
      begin
        if to_regclass('public.users') is not null then
          alter table users
            add column if not exists refresh_token_hash text,
            add column if not exists refresh_token_expires_at timestamptz;
        end if;

        if to_regclass('public.quiz_attempts') is not null then
          alter table quiz_attempts
            add column if not exists duration_seconds integer not null default 0,
            add column if not exists review_json jsonb;
        end if;

        if to_regclass('public.progress') is not null then
          alter table progress
            add column if not exists latest_quiz_score numeric(4,2),
            add column if not exists best_quiz_score numeric(4,2);
        end if;

        if to_regclass('public.badges') is not null then
          alter table badges
            add column if not exists condition_value varchar(120),
            add column if not exists metadata_json jsonb not null default '{}'::jsonb;
        end if;

        if to_regclass('public.simulations') is not null then
          alter table simulations
            add column if not exists type varchar(60) not null default 'formula_simulation',
            add column if not exists order_index integer not null default 0,
            add column if not exists created_at timestamptz not null default now(),
            add column if not exists updated_at timestamptz not null default now();
        end if;
      end $$;

      create table if not exists learning_activity (
        id uuid primary key default gen_random_uuid(),
        user_id uuid not null references users(id) on delete cascade,
        activity_date date not null,
        source_type varchar(60) not null,
        source_id varchar(120) not null,
        created_at timestamptz not null default now(),
        unique (user_id, activity_date)
      );

      create index if not exists learning_activity_user_date_idx
        on learning_activity(user_id, activity_date desc);
    `);
    return pool;
  },
};
