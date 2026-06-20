# Module Ownership

| Thanh vien | Module | Folder chinh | Can xin review truoc khi sua | API lien quan | Reviewer chinh |
| --- | --- | --- | --- | --- | --- |
| TV1 | Core Architecture, Auth, User/Profile | `lib/core`, `lib/features/auth`, `lib/features/profile`, `backend/src/modules/auth`, `backend/src/modules/users` | `pubspec.yaml`, `lib/core/router`, `docs/API_CONTRACT.md` | `/api/auth/*`, `/api/users/me` | TV5 |
| TV2 | Learning Content | `lib/features/home`, `lib/features/chapters`, `lib/features/lessons`, `backend/src/modules/chapters`, `backend/src/modules/lessons`, `backend/src/modules/simulations` | shared model, API contract, seed lessons | `/api/chapters`, `/api/lessons`, `/api/lessons/{id}/simulations` | TV1 |
| TV3 | Formula Simulation, Markdown/LaTeX, Offline | `lib/features/formula_simulation`, `lib/features/offline`, `lib/core/storage`, `backend/src/modules/offline-sync` | lesson model, Hive box names, router | `/api/sync/progress` | TV2 |
| TV4 | Quiz, Progress, Gamification | `lib/features/quiz`, `lib/features/progress`, `backend/src/modules/questions`, `backend/src/modules/quiz`, `backend/src/modules/progress`, `backend/src/modules/badges` | shared model, dashboard contract | `/api/quiz/*`, `/api/progress/*`, `/api/badges/me` | TV1 |
| TV5 | Admin/CMS, Statistics, Integration/Deploy | `lib/features/admin`, `backend/src/modules/admin`, `backend/src/modules/statistics`, `.github`, `docs`, root README | module folders cua nguoi khac | `/api/admin/*` | Module owner lien quan |

## Dependencies

- Auth token storage la dependency cua tat ca module goi API.
- Lessons phu thuoc Chapters.
- Simulations phu thuoc Lessons.
- Quiz phu thuoc Lessons va Questions.
- Progress phu thuoc Quiz attempts va Offline sync.
- Badges phu thuoc Progress/Quiz.
- Admin phu thuoc contract cua Chapters/Lessons/Questions.

## Quy tac ownership

- Sua folder chinh cua minh la uu tien.
- Sua folder cua nguoi khac phai tag reviewer trong PR.
- Sua `pubspec.yaml`, `app_router.dart`, `app_theme.dart`, `API_CONTRACT.md`, database schema can thong bao team truoc.
- Khong rename folder/module cua nguoi khac khi chua thong nhat.
