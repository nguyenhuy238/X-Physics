# Project Rules

## Muc tieu

X-Physics / X-IBook Vat Li la ung dung sach dien tu tuong tac giup hoc sinh THCS hoc Vat Li qua bai hoc Markdown/LaTeX, mo phong cong thuc, quiz, tien do, xu, huy hieu va offline reading.

## MVP Scope

- 3 chuong: Chuyen dong co hoc, Luc va ap suat, Dien hoc.
- Moi chuong 2 bai hoc.
- Moi bai co 5 cau quiz.
- It nhat 3 cong thuc tuong tac: `s = v * t`, `p = F / S`, `I = U / R`.
- Student co the hoc, lam quiz, xem ket qua, tai offline.
- Admin/Teacher co API/skeleton de quan ly noi dung va thong ke.

## Stack duoc phep dung

- Flutter + Dart.
- State management: Provider trong MVP hien tai.
- Routing: go_router.
- HTTP: Dio.
- Offline: Hive.
- Secure token: flutter_secure_storage.
- Markdown: flutter_markdown.
- LaTeX: flutter_math_fork.
- Chart: fl_chart.
- Backend skeleton: NestJS, PostgreSQL, JWT, bcrypt, Swagger.

## Quy tac bat buoc

- Khong hard-code token, password that, API URL production hoac secret.
- Khong commit `.env`, file build output, cache, key store, certificate.
- Khong pha vo API contract da thong nhat trong `docs/API_CONTRACT.md`.
- Moi thay doi response field phai cap nhat contract va bao team truoc khi code UI.
- Khong de man hinh trang khi loi.
- Moi man hinh goi du lieu phai co loading, error va empty state.
- UI khong goi Dio truc tiep.
- UI goi Provider/ViewModel/Controller.
- Provider/ViewModel goi Repository.
- Repository goi RemoteDataSource hoac LocalDataSource.
- Moi module co logic phuc tap nen co `README.md` ngan trong folder feature.

## Kien truc Flutter

Flow chuan:

`Screen/Widget -> Provider/Controller -> Repository -> RemoteDataSource/LocalDataSource -> API/Hive`

Feature-first:

- `lib/core`: theme, router, network, storage, constants, errors.
- `lib/shared`: widget/model dung chung.
- `lib/features/<module>`: model, data, provider/controller, screen, widget rieng module.

## Kien truc Backend

Flow chuan:

`Controller -> Service -> Repository/ORM -> Database`

- Controller chi parse request va tra response.
- Service xu ly business logic.
- DTO validate input.
- Guard xu ly auth/role.
- Khong tra `password_hash`.
- Response theo chuan `docs/API_RESPONSE_STANDARD.md`.
