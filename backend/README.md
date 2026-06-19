# X-Physics Backend Contract

The Flutter MVP currently runs with a mock repository so it can be demoed immediately. This folder documents the REST API shape for the next backend implementation.

Suggested stack: NestJS, PostgreSQL, Prisma/TypeORM, JWT, bcrypt, Swagger.

## Demo Accounts

- Student: `nam@example.com` / `123456`
- Admin: `admin@example.com` / `123456`

## Required Endpoints

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/users/me`
- `PUT /api/users/me`
- `GET /api/dashboard/me`
- `GET /api/chapters`
- `GET /api/chapters/:id`
- `GET /api/chapters/:id/lessons`
- `GET /api/lessons/:id`
- `GET /api/lessons/:id/simulations`
- `GET /api/lessons/:id/questions`
- `POST /api/quiz/submit`
- `GET /api/quiz/attempts/me`
- `GET /api/quiz/attempts/:id`
- `GET /api/progress/me`
- `POST /api/progress`
- `GET /api/badges/me`
- `POST /api/sync/progress`
- `GET /api/admin/users`
- `GET /api/admin/statistics`
- CRUD `/api/admin/chapters`, `/api/admin/lessons`, `/api/admin/questions`

## Environment

Copy `.env.example` when the backend is scaffolded. Do not commit real secrets.
