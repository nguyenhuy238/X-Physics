# Coding Standards

## Flutter

- Dung feature-first architecture.
- File widget dat ten `snake_case.dart`.
- Class dat ten `PascalCase`.
- Bien, ham, provider dat ten `camelCase`.
- Model co `fromJson` va `toJson` khi can map API/cache.
- Repository interface dat ten `<Module>Repository`.
- Mock repository dat ten `Mock<Module>Repository`.
- Provider/Controller dat ten `<Module>Provider` hoac `<Module>Controller`.
- Khong viet business logic trong UI.
- Khong dung magic string cho route, endpoint, Hive box, role.
- Dung `AppColors`, `AppTheme`, `AppTextStyles` khi co.
- UI phai co loading/error/empty state neu co data async.
- UI khong goi Dio truc tiep.

## Backend

- Dung module-based architecture.
- Controller chi nhan request va response.
- Service xu ly business logic.
- DTO validate input bang `class-validator`.
- Entity/Model ro rang, khong leak internal field.
- Khong tra `password_hash` trong response.
- Exception handling theo common filter.
- Tat ca endpoint tra response theo `ApiResponseDto`.
- Guard auth/role dung chung trong `common/guards`.
- Swagger decorator can duoc them khi endpoint thuc thi.

## Naming API

- Field JSON dung `camelCase`.
- ID dung string UUID hoac cuid.
- Date time dung ISO 8601.
- Pagination dung `pageNumber`, `pageSize`, `totalItems`, `totalPages`.
