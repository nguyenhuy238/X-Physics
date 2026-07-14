# TV5 – Task List (Admin/CMS + Statistics + Integration/Deploy)

> Dự án: X-Physics – Ứng dụng sách điện tử tương tác môn Vật Lý THCS
> Phạm vi phụ trách: Admin CRUD API, Statistics API, seed dữ liệu admin, Swagger, Admin UI (Flutter), UI polish, shared widgets, README, demo script, deploy, checklist tổng.

---

## 1. Backend – Admin CRUD API

- [ ] Thiết kế route group `/admin/*`, middleware kiểm tra `role = ADMIN` (dựa trên JWT do TV1/TV2 cấp)
- [ ] `GET /admin/users` – danh sách học sinh (phân trang, search theo email/name)
- [ ] `POST /admin/chapters` – tạo chương mới (title, description, order_index, grade_level)
- [ ] `PUT /admin/chapters/:id` – cập nhật chương
- [ ] `DELETE /admin/chapters/:id` – xóa chương (kiểm tra ràng buộc nếu chương còn lesson)
- [ ] `POST /admin/lessons` – tạo bài học (chapter_id, title, content_body, formula_latex, order_index)
- [ ] `PUT /admin/lessons/:id` – cập nhật bài học
- [ ] `DELETE /admin/lessons/:id` – xóa bài học
- [ ] `POST /admin/questions` – tạo câu hỏi (lesson_id, question_text, options_json, correct_option, explanation, difficulty)
- [ ] `PUT /admin/questions/:id` – cập nhật câu hỏi
- [ ] `DELETE /admin/questions/:id` – xóa câu hỏi
- [ ] Validation input (DTO) cho toàn bộ endpoint admin, trả lỗi 400 rõ ràng
- [ ] Exception handling: 401 (chưa login), 403 (không phải admin), 404 (id không tồn tại)

## 2. Backend – Statistics API

- [ ] `GET /admin/statistics` – tổng hợp:
  - [ ] Số active users (theo ngày/tuần)
  - [ ] Completion rate theo chương/bài học
  - [ ] Bài học học sinh làm sai nhiều nhất (từ bảng `QuizAttempts` + `Progress`)
  - [ ] Tổng số huy hiệu đã trao (từ `UserBadges`)
- [ ] Viết query tổng hợp (aggregate) tối ưu, tránh N+1
- [ ] Cân nhắc cache kết quả thống kê nếu load nặng

## 3. Seed dữ liệu Admin

- [ ] Script seed 1 tài khoản ADMIN mặc định (email/password test)
- [ ] Seed dữ liệu mẫu đủ để test admin CRUD (vài chapter/lesson/question) — phối hợp với TV1 để tránh trùng seed
- [ ] Đảm bảo password admin được hash bằng bcrypt giống flow của TV2

## 4. Swagger / API Docs

- [ ] Cấu hình Swagger cho toàn bộ nhóm route `/admin/*`
- [ ] Ghi chú rõ request/response mẫu cho từng endpoint (theo format mục 4.4 trong tài liệu dự án)
- [ ] Export Postman collection cho admin API để TV3/TV4 test độc lập

## 5. Flutter – Admin Screens / Admin Mode

- [ ] Quyết định: màn hình Admin riêng hay "Admin mode" toggle trong app chung
- [ ] Màn hình danh sách Users (bảng/list, tìm kiếm)
- [ ] Màn hình CRUD Chapters (list + form thêm/sửa/xóa)
- [ ] Màn hình CRUD Lessons (gắn với chapter_id)
- [ ] Màn hình CRUD Questions (gắn với lesson_id, nhập 4 options + correct_option + explanation)
- [ ] Màn hình Statistics (biểu đồ active users, completion rate — có thể tái dùng `fl_chart` như TV4 dùng cho Profile)
- [ ] Xử lý Loading/Error/Empty state cho các màn hình admin (đồng bộ pattern với TV3/TV4)

## 6. UI Polish & Shared Widgets

- [ ] Rà soát UI toàn app, đồng bộ theme/màu sắc theo Design System (Figma, TV5 phần Docs)
- [ ] Xây `shared/widgets`: AppButton, LoadingWidget, ErrorView, EmptyView dùng chung cho cả Student & Admin flow
- [ ] Kiểm tra responsive (điện thoại + tablet) — mục rubric 9.3
- [ ] Chuẩn hóa spacing, typography, icon set

## 7. Tài liệu & README

- [ ] Viết README tổng: mô tả dự án, hướng dẫn cài đặt backend + Flutter, biến môi trường (.env)
- [ ] Hướng dẫn chạy migration/seed DB
- [ ] Ghi rõ cấu trúc thư mục (tham chiếu mục 5.1 trong tài liệu dự án)
- [ ] Danh sách API endpoint tổng hợp (link tới Swagger/Postman)

## 8. Kịch bản Demo & Slide

- [ ] Soạn kịch bản demo chi tiết theo mốc thời gian có sẵn (mục 10 tài liệu dự án, 10–15 phút)
- [ ] Chuẩn bị tài khoản demo: 1 student ("Nam"), 1 admin
- [ ] Kịch bản riêng cho phần Admin: đăng nhập Admin → thêm câu hỏi mới → xem thống kê (phút 9:00–12:00)
- [ ] Slide thuyết trình: tổng quan, kiến trúc, demo flow, Q&A
- [ ] Test lại toàn bộ kịch bản demo trước buổi báo cáo (tránh lỗi live)

## 9. Deployment

- [ ] Deploy backend lên Railway/Render (môi trường test) — phối hợp với TV1 (người phụ trách deploy chính theo doc)
- [ ] Cấu hình biến môi trường production (DB connection, JWT secret)
- [ ] Build & test APK/IPA Flutter bản demo
- [ ] Kiểm tra kết nối app ↔ backend production trước demo

## 10. Final Checklist (tổng hợp theo Rubric)

- [ ] Đối chiếu checklist rubric mục 9.1 (Phân tích & Thiết kế) — phần TV5 phụ trách: Use Case Diagram, ERD, Wireframe, User Flow, API Spec doc
- [ ] Đối chiếu checklist mục 9.2 (Backend & API) — phần Admin CRUD, Swagger thuộc TV5
- [ ] Kiểm tra tất cả mục TODO trong rubric đã chuyển sang DONE trước hạn nộp
- [ ] Chốt danh sách issue còn tồn đọng, phân công gấp nếu thiếu người xử lý

---

## Ghi chú Timeline (theo Sprint 4 tuần trong tài liệu)

| Tuần | Việc chính của TV5 |
|---|---|
| Tuần 1 | Chuẩn bị cấu trúc Admin API, phối hợp seed schema với TV1 |
| Tuần 2 | Bắt đầu code Admin CRUD API, dựng khung Admin UI |
| Tuần 3 | Statistics API, hoàn thiện Admin UI, viết Swagger docs |
| Tuần 4 | Deploy, UI polish toàn app, viết README + kịch bản demo, chạy final checklist |

## Phụ thuộc cần lưu ý

- Admin CRUD API cần JWT + role guard từ **TV1/TV2** trước khi build được
- Statistics API cần dữ liệu thật từ `QuizAttempts`, `Progress`, `UserBadges` (do TV1/TV4 tạo ra) để test chính xác
- UI polish cần Design System từ phần Docs (nếu tài liệu gốc phân TV5 làm Design, cần xác nhận lại ai giữ Figma/Design System để tránh chồng chéo
