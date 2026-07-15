# Quy chuẩn Seed Data

Seed data nằm trong thư mục `seed-data/`.

## Tài khoản demo

- Student: Nguyễn Văn Nam, `nam@example.com`, mật khẩu `123456`, role `STUDENT`.
- Admin: Admin User, `admin@example.com`, mật khẩu `123456`, role `ADMIN`.

Mật khẩu trong JSON chỉ dùng cho môi trường demo. Script seed của backend phải hash bằng bcrypt trước khi insert vào database.

## Chương học

1. Chuyển động cơ học.
2. Lực và áp suất.
3. Điện học.

## Bài học

1. Chuyển động đều - `s = v * t`.
2. Vận tốc trung bình - `v = s / t`.
3. Áp suất - `p = F / S`.
4. Lực đẩy Ác-si-mét - `FA = d * V`.
5. Định luật Ohm - `I = U / R`.
6. Công suất điện - `P = U * I`.

## Câu hỏi

- Mỗi bài học có 5 câu.
- Mỗi câu có 4 đáp án.
- Có `correctOption` theo index bắt đầu từ 0.
- Có `explanation` bằng tiếng Việt.

## Cấu hình mô phỏng

- `s = v * t`: biến `v`, `t`, kết quả `s`.
- `p = F / S`: biến `F`, `S`, kết quả `p`.
- `I = U / R`: biến `U`, `R`, kết quả `I`.
- Tùy chọn: `P = U * I`.

## Huy hiệu

- Khởi đầu Vật Lí.
- Điểm tuyệt đối.
- Bậc thầy chuyển động.
- Điện thần.
- Nhà bác học.
