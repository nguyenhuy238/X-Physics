# Tổng hợp triển khai TV1 - Auth và Profile

Phụ trách: TV1

Tài liệu này tổng hợp các phần đã triển khai cho nhóm chức năng **Core Architecture + Authentication + User/Profile** của dự án X-Physics.

## 1. Phân tích ban đầu

### Kiến trúc Backend

- Backend dùng NestJS.
- Database dùng PostgreSQL thông qua thư viện `pg`.
- Tầng truy cập dữ liệu tập trung ở `DatabaseRepository`.
- Kiến trúc hiện có gồm Controller, Service, DTO, Guard, Repository, response chuẩn và exception filter.
- DTO dùng `class-validator` và được validate bằng global `ValidationPipe`.
- Auth dùng JWT và bcrypt.
- Swagger đã được cấu hình trong `backend/src/main.ts` và có Bearer authentication.

### Kiến trúc Flutter

- Frontend dùng Flutter.
- State management dùng `provider` với `AppState`.
- Điều hướng dùng `go_router`.
- Gọi API bằng Dio qua `lib/core/network/api_client.dart`.
- Token được lưu bằng `flutter_secure_storage`.
- Dự án có shared widgets trong `lib/shared/widgets`.

## 2. Chức năng Backend đã hoàn thành

- API đăng ký tài khoản.
- Chuẩn hóa email khi đăng ký và đăng nhập.
- Chuẩn hóa họ tên.
- Hash mật khẩu bằng bcrypt.
- Kiểm tra email trùng khi đăng ký.
- Gán role mặc định là `STUDENT`.
- Hỗ trợ `confirmPassword` khi đăng ký.
- API đăng nhập bằng email và mật khẩu.
- Verify mật khẩu bằng bcrypt.
- Sinh JWT access token có các claim: user id, email, role.
- Sinh refresh token.
- Lưu refresh token dưới dạng bcrypt hash trong database.
- Theo dõi thời hạn refresh token bằng `refresh_token_expires_at`.
- Refresh token rotation: refresh thành công thì token cũ bị thay thế.
- Logout revoke refresh token đã lưu.
- API `GET /api/auth/me` lấy user hiện tại từ JWT.
- API `GET /api/users/me` lấy thông tin user hiện tại.
- API `PUT /api/users/me` cập nhật thông tin profile hợp lệ.
- API `PUT /api/users/me/change-password` đổi mật khẩu.
- Đổi mật khẩu có kiểm tra mật khẩu hiện tại.
- Đổi mật khẩu hash mật khẩu mới và revoke refresh token.
- Không trả `passwordHash` về Flutter.
- `AuthGuard` bảo vệ API cần đăng nhập.
- `RolesGuard` hỗ trợ các role `STUDENT`, `TEACHER`, `ADMIN`.
- Admin/statistics API được bảo vệ bằng role guard.
- Quiz/progress/badge/sync API dùng user id từ JWT, không tin user id từ client.
- Các API public như login/register vẫn không yêu cầu token.

## 3. Chức năng Flutter đã hoàn thành

- Splash kiểm tra trạng thái đăng nhập.
- Splash điều hướng về Login, Home hoặc Admin tùy trạng thái và role.
- Login screen gọi API backend thật.
- Register screen gọi API backend thật.
- Register gửi thêm `confirmPassword`.
- Access token và refresh token được lưu bằng Secure Storage.
- API client tự gắn header `Authorization: Bearer <token>` cho API protected.
- API client không gắn Bearer token cho login/register/refresh.
- API client xử lý 401 bằng cách refresh token một lần.
- Sau khi refresh thành công, request cũ được gửi lại.
- Nếu refresh thất bại, app xóa session và chuyển về Login.
- Route guard chặn user chưa đăng nhập vào màn hình protected.
- Route guard chặn user thường vào route admin.
- Profile screen lấy dữ liệu thật từ backend.
- Profile hiển thị thông tin user, coins, tiến độ, điểm quiz gần đây và huy hiệu.
- Profile hỗ trợ cập nhật tên hiển thị.
- Profile hỗ trợ đổi mật khẩu.
- Sau khi đổi mật khẩu thành công, app xóa token và yêu cầu đăng nhập lại.
- Logout gọi API backend và xóa session local.

## 4. Bảo mật

- Không lưu mật khẩu plain text.
- Không trả password hash về client.
- Refresh token không lưu plain text trong database.
- Refresh token được hash bằng bcrypt.
- Logout revoke refresh token.
- Đổi mật khẩu revoke refresh token.
- Client không thể tự gửi role Admin khi đăng ký.
- Backend lấy user hiện tại từ JWT.
- API Admin yêu cầu role phù hợp.
- API Quiz/Progress dùng user id từ JWT để tránh sửa dữ liệu của user khác.

## 5. Database và Migration

Đã bổ sung các cột refresh token cho bảng `users`:

- `refresh_token_hash`
- `refresh_token_expires_at`

Đã bổ sung các phần schema còn thiếu để Profile hoạt động ổn định với database cũ:

- Bảng `learning_activity`.
- Cột `quiz_attempts.duration_seconds`.
- Cột `quiz_attempts.review_json`.
- Cột `progress.latest_quiz_score`.
- Cột `progress.best_quiz_score`.
- Cột `badges.condition_value`.
- Cột `badges.metadata_json`.

File `backend/src/database/database.provider.ts` đã được cập nhật để chạy migration nhẹ khi backend khởi động. Migration này chỉ thêm bảng/cột còn thiếu, không reset và không truncate dữ liệu hiện có.

Đã chạy sửa trực tiếp database local:

- Auth schema: `auth columns ready`.
- Profile schema: `profile schema ready`.

## 6. Danh sách API đã hoàn thiện

### Auth API

#### `POST /api/auth/register`

- Authentication: Không yêu cầu.
- Request chính: `name`, `email`, `password`, `confirmPassword` nếu có.
- Response chính: user an toàn, access token, refresh token.

#### `POST /api/auth/login`

- Authentication: Không yêu cầu.
- Request chính: `email`, `password`.
- Response chính: user an toàn, access token, refresh token.

#### `POST /api/auth/refresh`

- Authentication: Không yêu cầu access token.
- Request chính: `refreshToken`.
- Response chính: access token mới, refresh token mới.

#### `POST /api/auth/refresh-token`

- Authentication: Không yêu cầu access token.
- Đây là alias cho refresh token flow.
- Request chính: `refreshToken`.
- Response chính: access token mới, refresh token mới.

#### `POST /api/auth/logout`

- Authentication: Bắt buộc.
- Xử lý: revoke refresh token của user hiện tại.

#### `GET /api/auth/me`

- Authentication: Bắt buộc.
- Xử lý: lấy user id từ JWT và trả thông tin user an toàn.

### User/Profile API

#### `GET /api/users/me`

- Authentication: Bắt buộc.
- Xử lý: lấy thông tin user hiện tại.

#### `PUT /api/users/me`

- Authentication: Bắt buộc.
- Request chính: `name`.
- Xử lý: chỉ cho cập nhật trường hợp lệ, không cho cập nhật role, password hash hoặc trường hệ thống.

#### `PUT /api/users/me/change-password`

- Authentication: Bắt buộc.
- Request chính: `currentPassword`, `newPassword`, `confirmNewPassword`.
- Xử lý: kiểm tra mật khẩu hiện tại, kiểm tra confirm password, không cho mật khẩu mới trùng mật khẩu cũ, hash mật khẩu mới và revoke refresh token.

#### `GET /api/profile/me`

- Authentication: Bắt buộc.
- Response chính: user profile, tổng coins, số bài đã hoàn thành, tổng số bài học, tiến độ tổng, điểm trung bình, quiz gần đây, huy hiệu đã đạt và huy hiệu chưa đạt.

## 7. File đã chỉnh sửa hoặc thêm mới

### Backend

- `backend/src/database/schema.sql`: thêm cột refresh token và schema phục vụ profile/progress.
- `backend/src/database/database.provider.ts`: thêm migration nhẹ khi backend khởi động.
- `backend/src/database/database.repository.ts`: thêm hàm lưu/revoke refresh token, cập nhật password hash và map thông tin refresh token nội bộ.
- `backend/src/modules/auth/auth.controller.ts`: thêm `/auth/me`, `/auth/refresh-token`, cập nhật logout để revoke refresh token.
- `backend/src/modules/auth/auth.service.ts`: chuẩn hóa email, kiểm tra confirm password, sinh token, hash refresh token, rotate refresh token và revoke khi logout.
- `backend/src/modules/auth/dto/register.dto.ts`: thêm `confirmPassword`.
- `backend/src/modules/users/dto/change-password.dto.ts`: thêm DTO đổi mật khẩu.
- `backend/src/modules/users/users.controller.ts`: thêm route đổi mật khẩu.
- `backend/src/modules/users/users.service.ts`: thêm logic đổi mật khẩu.

### Flutter

- `lib/core/constants/api_endpoints.dart`: thêm endpoint refresh-token alias và endpoint đổi mật khẩu.
- `lib/core/network/api_client.dart`: không gắn token cho login/register/refresh, refresh token khi gặp 401, retry request sau khi refresh thành công.
- `lib/features/auth/screens/register_screen.dart`: thêm confirm password và gửi `confirmPassword` lên backend.
- `lib/features/profile/data/profile_repository.dart`: thêm API đổi mật khẩu.
- `lib/features/profile/screens/profile_screen.dart`: thêm cập nhật profile, đổi mật khẩu và logout.
- `lib/features/progress/application/app_state.dart`: thêm flow register có confirm password, cập nhật profile, đổi mật khẩu và xóa session.

## 8. Kết quả kiểm thử đã chạy thật

Đã chạy backend:

```powershell
cd backend
npm run build
npm run test
```

Kết quả:

- `npm run build`: pass.
- `npm run test`: pass.
- Tổng kết test: `6` test suites pass, `75` tests pass.

Các lệnh Flutter đã bỏ qua theo yêu cầu vì chạy lâu:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- Flutter build/run

Không ghi nhận các bước Flutter là pass vì chưa chạy hoàn tất.

## 9. Checklist demo thủ công

1. Khởi động backend.
2. Đăng nhập student: `nam@example.com` / `123456`.
3. Vào Profile.
4. Kiểm tra Profile không còn lỗi `Internal server error`.
5. Cập nhật tên hiển thị.
6. Refresh Profile và kiểm tra tên mới.
7. Đổi mật khẩu.
8. Kiểm tra app quay về Login sau khi đổi mật khẩu.
9. Đăng nhập lại bằng mật khẩu mới.
10. Logout.
11. Kiểm tra không thể back về màn protected.
12. Đăng nhập admin: `admin@example.com` / `123456`.
13. Kiểm tra admin vào được màn Admin.
14. Đăng nhập student và kiểm tra student bị chặn khi vào Admin.

## 10. Ghi chú còn lại

- Database local cũ có thể thiếu bảng/cột so với `schema.sql`; backend hiện đã có migration nhẹ khi start để tự bổ sung.
- Không cần chạy `npm run db:seed` nếu không muốn reset dữ liệu seed/demo activity.
- Flutter analyze/test chưa được xác nhận vì đã bỏ qua theo yêu cầu.
