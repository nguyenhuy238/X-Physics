# X-Physics Backend

Backend API cho ứng dụng sách điện tử tương tác môn Vật Lý THCS.

## Yêu cầu

- Node.js >= 18
- PostgreSQL >= 15
- npm hoặc yarn

## Cài đặt

```bash
cd backend
cp .env.example .env
npm install
```

## Biến môi trường

```env
DATABASE_URL=postgres://user:password@localhost:5432/x_physics
JWT_ACCESS_SECRET=super_secret_access_key
JWT_REFRESH_SECRET=super_secret_refresh_key
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
PORT=3000
```

## Chạy migration + seed

```bash
npm run db:seed
```

## Chạy backend

```bash
npm run start:dev
```

## API Docs

- Swagger UI: http://localhost:3000/api/docs
- Postman collection: `docs/x-physics-admin.postman_collection.json`
