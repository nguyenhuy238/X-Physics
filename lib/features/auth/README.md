# Auth Feature

Owner: TV1.

Scope:

- Login/Register.
- Auth check and splash.
- Token storage.
- User profile entry points.
- Remote API flow through `AppState` and `ApiClient`.

Backend endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/users/me`

Demo checklist:

- Login with `nam@example.com` / `123456`.
- Login with `admin@example.com` / `123456` redirects to Admin.
- Register creates a student account and stores tokens in secure storage.
- Logout clears local tokens and returns to Login.
