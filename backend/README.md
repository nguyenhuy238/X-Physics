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
Copy-Item .env.example .env
npm run start:dev
```

Swagger sau khi chay server: `http://localhost:3000/api/docs`.

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
