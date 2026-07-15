# Quy trình làm việc nhóm

## Quy trình hằng ngày

1. Pull code mới nhất từ `main` hoặc `develop`.
2. Kiểm tra `docs/MODULE_OWNERSHIP.md` để chắc chắn task đúng phạm vi.
3. Tạo branch theo module.
4. Code trong folder module chính.
5. Commit nhỏ theo từng thay đổi có ý nghĩa.
6. Push branch.
7. Tạo Pull Request.
8. Chờ review và sửa feedback.
9. Merge sau khi pass checklist.

## Trước khi tạo branch

```powershell
git checkout main
git pull origin main
git checkout -b feature/auth-profile
```

Nếu team dùng `develop`, tạo branch từ `develop`.

## Commit

- Mỗi commit nên có một mục đích rõ.
- Không gom nhiều module không liên quan trong một commit.
- Không commit file generated/build/cache.
- Không commit `.env`.

Ví dụ:

```text
feat(auth): implement login screen
fix(quiz): prevent submit without answer
docs(api): update quiz submit contract
refactor(lessons): split repository and service
chore(project): update dependencies
```

## Pull Request

- PR phải ghi rõ module bị ảnh hưởng.
- PR UI nên có screenshot hoặc video ngắn.
- PR đổi API/model phải cập nhật docs.
- Không push trực tiếp vào `main`.
- Không tự merge PR của mình khi chưa có review.

## Resolve conflict

1. Pull hoặc rebase branch mới nhất.
2. Đọc conflict theo từng file.
3. Giữ logic của cả hai bên nếu không mâu thuẫn.
4. Chạy format/analyze/test liên quan.
5. Báo owner file nếu conflict ở core, router, theme, API contract hoặc schema.
