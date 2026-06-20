# Git Rules

## Main rules

- Khong push truc tiep vao `main`.
- Khong commit `.env`.
- Khong commit build output: `build/`, `.dart_tool/`, `node_modules/`, `dist/`, coverage.
- Khong format toan bo repo neu PR chi sua mot module.
- Khong sua file ngoai scope neu khong giai thich trong PR.

## Branch naming

- `feature/auth-profile`
- `feature/learning-content`
- `feature/formula-offline`
- `feature/quiz-progress`
- `feature/admin-statistics`
- `fix/<module>-<short-description>`
- `docs/<topic>`
- `chore/<topic>`

## Commit convention

```text
feat(auth): implement login screen
fix(quiz): prevent submit without answer
docs(api): update quiz submit contract
refactor(lessons): split repository and service
chore(project): update dependencies
```

## Rebase/Merge

- Branch ca nhan co the rebase voi `main`/`develop`.
- Khong force push vao branch dung chung.
- Neu conflict o core/API/schema, tag owner file de review.
