# X-Physics / X-IBook Vat Li

Ung dung sach dien tu tuong tac cho hoc sinh THCS hoc mon Vat Li.

Repo hien la Flutter project o root (`lib/`, `pubspec.yaml`, platform folders). Vi project da chay o root, tam thoi khong di chuyen sang `mobile/` de tranh pha cau hinh Flutter. Backend skeleton nam trong `backend/`, tai lieu team nam trong `docs/`, seed data nam trong `seed-data/`.

## MVP hien co

- Dang nhap/dang ky demo bang mock repository.
- Home Dashboard voi xu, tien do chuong va layout responsive.
- 3 chuong, moi chuong 2 bai, moi bai 5 cau quiz.
- Lesson View co Markdown, LaTeX, progress bar, tai offline.
- Formula simulation bang slider cho cac cong thuc Vat Li.
- Quiz, result, xu, huy hieu va loi giai.
- Profile, offline downloads bang Hive va pending progress sync skeleton.
- Backend NestJS skeleton va API contract.

## Cau truc thu muc

```text
lib/
  core/
  shared/
  features/
    auth/
    home/
    chapters/
    lessons/
    formula_simulation/
    quiz/
    progress/
    profile/
    offline/
    admin/
backend/
docs/
seed-data/
.github/
```

## Tai khoan demo

- Student: `nam@example.com` / `123456`
- Admin: `admin@example.com` / `123456`

## Chay Flutter app

```powershell
flutter pub get
flutter run
```

Kiem tra:

```powershell
dart format .
flutter analyze
flutter test
```

## Chay backend

```powershell
cd backend
npm install
Copy-Item .env.example .env
npm run start:dev
```

Swagger: `http://localhost:3000/api/docs`.

## Branch goi y cho 5 thanh vien

- TV1: `feature/auth-profile`
- TV2: `feature/learning-content`
- TV3: `feature/formula-offline`
- TV4: `feature/quiz-progress`
- TV5: `feature/admin-statistics`

## Cach tao PR

1. Pull code moi nhat tu `main`.
2. Tao branch theo module.
3. Code trong folder ownership cua minh.
4. Chay format/analyze/test lien quan.
5. Push branch va tao PR theo template.
6. Tag reviewer theo `docs/MODULE_OWNERSHIP.md`.

## Quy tac tranh conflict

- Khong push truc tiep `main`.
- Khong commit `.env`, build output, cache.
- Khong sua `pubspec.yaml`, router, theme, API contract, schema neu chua bao team.
- UI khong goi Dio truc tiep; di qua Provider/Repository.
- Doi API/model phai cap nhat `docs/API_CONTRACT.md`.

## Tai lieu quan trong

- `docs/PROJECT_RULES.md`
- `docs/MODULE_OWNERSHIP.md`
- `docs/API_CONTRACT.md`
- `docs/API_RESPONSE_STANDARD.md`
- `docs/DATABASE_SCHEMA.md`
- `docs/SEED_DATA_SPEC.md`
- `docs/DEFINITION_OF_DONE.md`

## Goi y commit

```powershell
git add .
git commit -m "chore(project): add team skeleton and contracts"
git push origin <branch-name>
```
