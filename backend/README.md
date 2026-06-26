# X-Physics Backend

NestJS skeleton cho RESTful API cua X-Physics. Flutter MVP hien van chay bang mock repository, nen backend team co the phat trien doc lap theo contract trong `../docs/API_CONTRACT.md`.

## Stack

- NestJS
- PostgreSQL
- JWT + bcrypt
- Swagger
- DTO validation

## Setup

```powershell
cd backend
npm install
npm run db:seed
npm run start:dev
```

Swagger sau khi chay server: `http://localhost:3000/api/docs`.

## Environment

Backend can ket noi PostgreSQL va JWT secrets qua bien moi truong:

```powershell
$env:DATABASE_URL="postgres://postgres:postgres@localhost:5432/x_physics"
$env:JWT_ACCESS_SECRET="change-me-access-secret"
$env:JWT_REFRESH_SECRET="change-me-refresh-secret"
```

Chay `npm run db:seed` de tao schema va import du lieu tu `../seed-data/`.
Password demo trong seed duoc hash bang bcrypt truoc khi insert.

## Module skeleton

- `auth`
- `users`
- `chapters`
- `lessons`
- `simulations`
- `questions`
- `quiz`
- `progress`
- `badges`
- `offline-sync`
- `admin`
- `statistics`

## Demo accounts

- Student: `nam@example.com` / `123456`
- Admin: `admin@example.com` / `123456`

Password trong seed phai duoc hash bang bcrypt khi import vao database.
