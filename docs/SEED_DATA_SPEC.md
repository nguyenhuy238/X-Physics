# Seed Data Spec

Seed data lives in `seed-data/`.

## Demo users

- Student: Nguyen Van Nam, `nam@example.com`, password `123456`, role `STUDENT`.
- Admin: Admin User, `admin@example.com`, password `123456`, role `ADMIN`.

Passwords in JSON are demo-only. Backend seed script must hash with bcrypt before insert.

## Chapters

1. Chuyen dong co hoc.
2. Luc va ap suat.
3. Dien hoc.

## Lessons

1. Chuyen dong deu - `s = v * t`.
2. Van toc trung binh - `v = s / t`.
3. Ap suat - `p = F / S`.
4. Luc day Ac-si-met - `FA = d * V`.
5. Dinh luat Ohm - `I = U / R`.
6. Cong suat dien - `P = U * I`.

## Questions

- Moi lesson co 5 cau.
- Moi cau co 4 options.
- Co `correctOption` index 0-based.
- Co `explanation` tieng Viet.

## Simulation config

- `s = v * t`: variables `v`, `t`, result `s`.
- `p = F / S`: variables `F`, `S`, result `p`.
- `I = U / R`: variables `U`, `R`, result `I`.
- Optional: `P = U * I`.

## Badges

- Khoi dau Vat Li.
- Diem tuyet doi.
- Bac thay chuyen dong.
- Dien than.
- Nha bac hoc.
