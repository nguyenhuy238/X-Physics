# Team Workflow

## Quy trinh hang ngay

1. Pull code moi nhat tu `main` hoac `develop`.
2. Kiem tra `docs/MODULE_OWNERSHIP.md` de chac chan task dung scope.
3. Tao branch theo module.
4. Code trong folder module chinh.
5. Commit nho theo tung thay doi co y nghia.
6. Push branch.
7. Tao Pull Request.
8. Cho review, sua feedback.
9. Merge sau khi pass checklist.

## Truoc khi tao branch

```powershell
git checkout main
git pull origin main
git checkout -b feature/auth-profile
```

Neu team dung `develop`, tao branch tu `develop`.

## Commit

- Moi commit nen co mot muc dich ro.
- Khong gom nhieu module khong lien quan trong mot commit.
- Khong commit file generated/build/cache.
- Khong commit `.env`.

Vi du:

```text
feat(auth): implement login screen
fix(quiz): prevent submit without answer
docs(api): update quiz submit contract
refactor(lessons): split repository and service
chore(project): update dependencies
```

## Pull Request

- PR phai ghi module affected.
- PR UI nen co screenshot/video ngan.
- PR doi API/model phai cap nhat docs.
- Khong push truc tiep vao `main`.
- Khong merge PR cua minh khi chua co review.

## Resolve conflict

1. Pull/rebase branch moi nhat.
2. Doc conflict theo tung file.
3. Giu logic cua ca hai ben neu khong mau thuan.
4. Chay format/analyze/test lien quan.
5. Bao nguoi owner file neu conflict o core, router, theme, API contract hoac schema.
