# X-Physics / X-IBook Vat Li

Flutter MVP cho ung dung sach dien tu tuong tac mon Vat Li THCS.

## Da co trong MVP

- Dang nhap/dang ky demo bang mock repository.
- Home Dashboard voi xu, tien do chuong va layout responsive.
- 3 chuong MVP, moi chuong 2 bai, moi bai 5 cau quiz.
- Lesson View co Markdown, LaTeX, progress bar khi doc, nut tai offline va bookmark UI.
- `FormulaSimulationWidget` dung slider va mapping expression an toan, khong dung eval.
- Quiz 5 phut, 4 dap an, chan next khi chua chon, confirm khi nop bai, tu nop khi het gio.
- Quiz Result co diem, so cau dung, xu, huy hieu moi va review loi giai.
- Profile & Achievements.
- Offline Downloads bang Hive, co che do gia lap offline bang switch tren AppBar.
- Backend contract va `.env.example` trong `backend/`.

## Tai khoan demo

- Student: `nam@example.com` / `123456`
- Admin: `admin@example.com` / `123456`

## Chay Flutter app

```powershell
flutter pub get
flutter run
```

Neu wrapper `dart` bi treo tren may Windows nay, co the dung truc tiep Dart SDK:

```powershell
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze lib test
```

## Kiem tra

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
```

Trong phien Codex nay, `flutter pub get` da chay thanh cong. `dart analyze lib test` bao `No issues found`, nhung exit code bi anh huong boi loi telemetry ghi vao `C:\Users\LEGION\AppData\Roaming\.dart-tool`. `flutter test` bi timeout do Flutter wrapper treo trong moi truong hien tai.

## Test offline mode

1. Dang nhap bang tai khoan Nam.
2. Mo mot bai hoc, bam icon tai xuong tren AppBar.
3. Vao man Offline Downloads de thay bai da tai.
4. Bat switch offline tren AppBar.
5. Mo lai bai da tai: app doc tu Hive.
6. Mo bai chua tai khi offline: app hien error state than thien.
7. Lam quiz khi offline: progress duoc luu vao Hive box `pending_progress`, san sang sync qua `/api/sync/progress` khi co backend.

## Backend

Repo chua co backend thuc thi. Thu muc `backend/` hien chua scaffold NestJS ma dang ghi contract API, endpoint bat buoc va env mau de tiep tuc trien khai PostgreSQL/JWT/bcrypt/Swagger.

## Goi y commit

```powershell
git add pubspec.yaml pubspec.lock lib test backend README.md linux/flutter macos/Flutter windows/flutter
git commit -m "Build X-Physics Flutter MVP demo"
```
