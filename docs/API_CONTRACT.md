# API Contract

Base URL local: `http://localhost:3000`

All endpoints return the envelope from `docs/API_RESPONSE_STANDARD.md`.

## Auth Header

```http
Authorization: Bearer <accessToken>
```

## Auth

### POST /api/auth/register

Request:

```json
{
  "name": "Nguyen Van Nam",
  "email": "nam@example.com",
  "password": "123456"
}
```

Response:

```json
{
  "success": true,
  "message": "Registered",
  "data": {
    "user": {
      "id": "usr_001",
      "name": "Nguyen Van Nam",
      "email": "nam@example.com",
      "role": "STUDENT"
    },
    "accessToken": "jwt",
    "refreshToken": "jwt"
  }
}
```

### POST /api/auth/login

Request:

```json
{
  "email": "nam@example.com",
  "password": "123456"
}
```

Response data is the same as register.

### POST /api/auth/refresh

Request:

```json
{
  "refreshToken": "jwt"
}
```

Response:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "accessToken": "jwt",
    "refreshToken": "jwt"
  }
}
```

### GET /api/users/me

Auth: required.

Response:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": "usr_001",
    "name": "Nguyen Van Nam",
    "email": "nam@example.com",
    "role": "STUDENT",
    "coins": 120
  }
}
```

### PUT /api/users/me

Auth: required.

Request:

```json
{
  "name": "Nguyen Van Nam"
}
```

### POST /api/auth/logout

Auth: required.

Response data: `{}`.

## Chapters and Lessons

### GET /api/chapters

Response:

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "motion",
      "title": "Chuyen dong co hoc",
      "description": "Van toc, quang duong va thoi gian",
      "orderIndex": 1,
      "lessonCount": 2
    }
  ]
}
```

### GET /api/chapters/{id}

Response data: chapter detail.

### GET /api/chapters/{id}/lessons

Response data: list of lesson summaries.

### GET /api/lessons/{id}

Response:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": "motion-1",
    "chapterId": "motion",
    "title": "Chuyen dong deu",
    "contentMarkdown": "# Chuyen dong deu",
    "formulaLatex": "s = v \\times t",
    "estimatedMinutes": 12,
    "orderIndex": 1,
    "updatedAt": "2026-07-14T08:00:00.000Z"
  }
}
```

### GET /api/lessons/{id}/simulations

Response data:

```json
[
  {
    "id": "sim-svt",
    "lessonId": "motion-1",
    "title": "Mo phong s = v * t",
    "formula": "s = v \\times t",
    "expression": "v * t",
    "variables": [
      {
        "symbol": "v",
        "label": "Van toc",
        "unit": "m/s",
        "min": 1,
        "max": 30,
        "defaultValue": 5
      }
    ],
    "result": {
      "symbol": "s",
      "label": "Quang duong",
      "unit": "m"
    }
  }
]
```

### GET /api/lessons/{id}/questions

Response data: list of questions for taking a quiz. This endpoint must not return
`correctOption`, `correctAnswer`, or `explanation`.

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "motion-1-q1",
      "lessonId": "motion-1",
      "question": "Cong thuc tinh quang duong trong chuyen dong deu la gi?",
      "options": ["s = v * t", "v = s * t", "t = s * v", "s = v / t"],
      "orderIndex": 1
    }
  ]
}
```

## Quiz

### POST /api/quiz/submit

Auth: required.
Role: `STUDENT`.

Validation:

- `lessonId` must exist and have questions.
- `answers` must be a non-empty array.
- Each question in the lesson must be answered exactly once.
- Duplicate question IDs, question IDs from another lesson, and out-of-range
  `selectedOption` values return `400`.
- `durationSeconds` must be an integer from `0` to `3600`.
- Backend ignores any frontend score/correct count/coins values and calculates
  them from stored questions.
- Submitted question IDs must match the current question set for the lesson.
  If Admin changed the question set while a student was taking the quiz, the
  server returns `409` with message
  `B? c�u h?i d� du?c c?p nh?t. Vui l�ng t?i l?i quiz.`

Reward idempotency:

- First valid lesson completion creates `LESSON_COMPLETE` reward `+10`.
- Quiz score reward uses best-score delta: tier `15`, `20`, `30`.
- Chapter completion creates `CHAPTER_COMPLETE` reward `+50` once per chapter.
- A valid attempt is always saved, but rewards are only created when idempotency
  rules allow them.

Request:

```json
{
  "lessonId": "motion-1",
  "durationSeconds": 123,
  "answers": [
    {
      "questionId": "motion-1-q1",
      "selectedOption": 0
    }
  ]
}
```

Response:

```json
{
  "success": true,
  "message": "Submitted",
  "data": {
    "attemptId": "att_001",
    "lessonId": "motion-1",
    "score": 8,
    "correctCount": 4,
    "totalQuestions": 5,
    "durationSeconds": 123,
    "earnedCoins": 20,
    "totalCoins": 150,
    "newBadges": [
      {
        "id": "starter",
        "name": "Khoi dau Vat Li",
        "description": "Hoan thanh bai hoc dau tien.",
        "iconUrl": "school",
        "ruleKey": "complete_first_lesson"
      }
    ],
    "review": [
      {
        "questionId": "motion-1-q1",
        "question": "Cong thuc tinh quang duong trong chuyen dong deu la gi?",
        "options": ["s = v * t", "v = s * t", "t = s * v", "s = v / t"],
        "selectedOption": 0,
        "correctOption": 0,
        "isCorrect": true,
        "explanation": "Quang duong bang van toc nhan voi thoi gian."
      }
    ]
  }
}
```

### GET /api/quiz/attempts/me

Auth: required. Supports `pageNumber` and `pageSize`.

### GET /api/quiz/attempts/{id}

Auth: required.

## Progress and Badges

### GET /api/progress/dashboard/me

Auth: required. Returns summary for home/progress dashboard.

Compatibility route: `GET /api/dashboard/me`.

Response:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "overallProgress": 50.0,
    "completedLessons": 3,
    "totalLessons": 6,
    "averageScore": 8.33,
    "totalCoins": 150,
    "chapterProgress": [
      {
        "chapterId": "motion",
        "title": "Chuyen dong co hoc",
        "completedLessons": 2,
        "totalLessons": 2,
        "progressPercent": 100.0
      }
    ],
    "recentAttempts": [
      {
        "attemptId": "att_001",
        "lessonId": "motion-1",
        "lessonTitle": "Chuyen dong deu",
        "score": 8,
        "durationSeconds": 123,
        "submittedAt": "2026-07-13T09:00:00.000Z"
      }
    ]
  }
}
```

### GET /api/progress/me

Auth: required. Returns lesson/chapter progress.

### POST /api/progress

Auth: required.

Request:

```json
{
  "lessonId": "motion-1",
  "status": "COMPLETED",
  "progressPercent": 100
}
```

### GET /api/badges/me

Auth: required. Compatibility endpoint that returns earned badges only.

### GET /api/profile/achievements

Auth: required. Preferred endpoint for Profile/Achievements.

Compatibility route: `GET /api/profile/me`.

Response:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "user": {
      "id": "usr_001",
      "name": "Nguyen Van Nam",
      "email": "nam@example.com",
      "role": "STUDENT",
      "coins": 150,
      "avatarUrl": null
    },
    "totalCoins": 150,
    "completedLessons": 3,
    "totalLessons": 6,
    "overallProgress": 0.5,
    "averageScore": 8.33,
    "recentAttempts": [],
    "earnedBadges": [
      {
        "id": "starter",
        "name": "Khoi dau Vat Li",
        "description": "Hoan thanh bai hoc dau tien.",
        "iconUrl": "school",
        "ruleKey": "complete_first_lesson",
        "achievedAt": "2026-07-13T09:00:00.000Z"
      }
    ],
    "lockedBadges": [
      {
        "id": "scientist",
        "name": "Nha bac hoc",
        "description": "Hoan thanh toan bo MVP.",
        "iconUrl": "science",
        "ruleKey": "complete_all_lessons",
        "progressCurrent": 3,
        "progressTarget": 6
      }
    ]
  }
}
```

### POST /api/sync/progress

Auth: required. Used by offline mode.
The backend uses the JWT user id and ignores client ownership fields.

Request:

```json
{
  "items": [
    {
      "lessonId": "motion-1",
      "progressPercent": 100,
      "isCompleted": true,
      "operationId": "7a1f-motion-1-1780000000000",
      "quizAttempt": {
        "score": 8,
        "answers": []
      },
      "clientUpdatedAt": "2026-06-20T09:00:00.000Z"
    }
  ]
}
```

Response data:

```json
{
  "syncedItems": 1,
  "accepted": [
    {
      "operationId": "7a1f-motion-1-1780000000000",
      "lessonId": "motion-1",
      "serverState": {
        "lessonId": "motion-1",
        "status": "COMPLETED",
        "progressPercent": 100
      }
    }
  ],
  "rejected": [],
  "conflicts": []
}
```

The client deletes only accepted pending items. Rejected items remain queued
with retry/error metadata.

### POST /api/sync/downloads

Auth: required. Records a "lesson downloaded for offline" event (owned by
TV3, `backend/src/modules/offline-sync`). Best-effort from the client: the
Flutter app calls this after a successful local download but does not fail
the download if this call errors.

Request:

```json
{
  "lessonId": "motion-1",
  "clientDeviceId": "device-abc123"
}
```

`clientDeviceId` is optional. Response data: `{ "recorded": true }`.
`lessonId` must reference a published lesson (`404` otherwise).

## Admin

Admin content-management endpoints require an authenticated `ADMIN` or
`TEACHER` role. Missing token returns `401`; authenticated `STUDENT` returns
`403`.

- `GET /api/admin/users`
- `POST /api/admin/users/{id}/notify`
- `GET /api/admin/statistics`
- `POST /api/admin/chapters`
- `PUT /api/admin/chapters/{id}`
- `DELETE /api/admin/chapters/{id}`
- `POST /api/admin/lessons`
- `PUT /api/admin/lessons/{id}`
- `DELETE /api/admin/lessons/{id}`
- `GET /api/admin/questions`
- `GET /api/admin/questions/{id}`
- `POST /api/admin/questions`
- `PUT /api/admin/questions/{id}`
- `PUT /api/admin/questions/reorder`
- `DELETE /api/admin/questions/{id}`

### POST /api/admin/users/{id}/notify

Auth: required.
Role: `ADMIN` or `TEACHER`.

Sends one notification to a user selected from the Admin Students screen.

Request:

```json
{
  "title": "Nhac hoc bai",
  "message": "Hay hoan thanh bai hoc hom nay.",
  "type": "INFO"
}
```

Validation:

- `title` is trimmed, required, length `3..150`.
- `message` is trimmed, required, length `3..2000`.
- `type` is optional and defaults to `INFO`.
- Allowed `type` values: `INFO`, `SYSTEM`, `ACHIEVEMENT`.
- Unknown request fields are rejected by the global `ValidationPipe`.
- Unknown target user returns `404` with message `Khong tim thay hoc sinh.`
- `ADMIN` and `TEACHER` callers are allowed; `STUDENT` callers return `403`.
- Missing token returns `401`.

Validation error examples:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "title",
      "message": "Tieu de thong bao khong duoc de trong."
    }
  ]
}
```

Recommended user-facing messages:

- Empty `title`: `Tieu de thong bao khong duoc de trong.`
- Too-long `title`: `Tieu de thong bao khong duoc vuot qua 150 ky tu.`
- Empty `message`: `Noi dung thong bao khong duoc de trong.`
- Too-long `message`: `Noi dung thong bao khong duoc vuot qua 2000 ky tu.`
- Invalid `type`: `Loai thong bao khong hop le.`
- Unknown user: `Khong tim thay hoc sinh.`

### POST/PUT /api/admin/chapters

Request fields:

- `id`: trimmed slug, required, length `3..50`, pattern `^[a-z0-9-]+$`.
- `title`: trimmed, required, length `3..100`.
- `description`: trimmed, required, length `5..500`.
- `orderIndex`: integer `>= 0`.
- `isPublished`: optional boolean.

Business validation:

- Chapter titles are compared after trim, whitespace collapse, and Vietnamese
  lowercase normalization. Duplicate titles return `400`.
- Chapter ordering is server-owned. `orderIndex` is zero-based for existing
  Chapter/Lesson compatibility. Create/update at position `N` shifts later
  chapters and compacts the list.
- Delete is blocked while the chapter still has lessons. Successful delete
  compacts remaining chapter order.

Recommended user-facing messages:

- Duplicate title: `Ten chuong hoc da ton tai.`
- Unknown chapter: `Chuong hoc khong ton tai hoac da bi xoa.`
- Chapter with lessons: `Khong the xoa chuong vi van con bai hoc.`

### POST/PUT /api/admin/lessons

Request fields:

- `id`: trimmed slug, required, length `3..50`, pattern `^[a-z0-9-]+$`.
- `chapterId`: trimmed, required.
- `title`: trimmed, required, length `3..100`.
- `contentMarkdown`: trimmed, required, length `10..10000`.
- `formulaLatex`: optional string, max `500`.
- `estimatedMinutes`: integer `1..180`.
- `orderIndex`: integer `>= 0`.
- `isPublished`: optional boolean.
- `simulation`: optional formula simulation object.

Business validation:

- `chapterId` must reference an existing chapter; unknown chapter returns `404`.
- Lesson titles are unique inside the same chapter after trim, whitespace
  collapse, and Vietnamese lowercase normalization.
- Lesson ordering is server-owned and zero-based inside each chapter. Create,
  update, move between chapters, and delete shift/compact order in a transaction.
- Deleting a lesson hard-deletes related questions, quiz attempts, progress,
  downloaded lessons, and simulations through database foreign keys.

Recommended user-facing messages:

- Unknown chapter: `Chuong hoc khong ton tai hoac da bi xoa.`
- Duplicate title in chapter: `Ten bai hoc da ton tai trong chuong nay.`
- Unknown lesson: `Bai hoc khong ton tai hoac da bi xoa.`

### GET /api/admin/questions

Query params:

- `lessonId`: optional lesson filter.
- `chapterId`: optional chapter filter.
- `search`: optional case-insensitive search in question text.
- `difficulty`: optional `EASY`, `MEDIUM`, or `HARD`.
- `page`: optional, default `1`.
- `limit`: optional, default `20`, max `100`.

Response:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [
      {
        "id": "motion-1-q1",
        "lessonId": "motion-1",
        "lessonTitle": "Chuyen dong deu",
        "chapterId": "motion",
        "chapterTitle": "Co hoc",
        "question": "Cong thuc tinh quang duong trong chuyen dong deu la gi?",
        "questionText": "Cong thuc tinh quang duong trong chuyen dong deu la gi?",
        "options": ["s = v * t", "v = s * t", "t = s * v", "s = v / t"],
        "correctOption": 0,
        "explanation": "Quang duong bang van toc nhan voi thoi gian.",
        "difficulty": "MEDIUM",
        "orderIndex": 1
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 40,
    "totalPages": 2
  }
}
```

Ordering: chapter order, lesson order, question `orderIndex`, then question id.

### GET /api/admin/questions/{id}

Returns one admin question with lesson and chapter information. Unknown id
returns `404`.

### POST /api/admin/questions

Request:

```json
{
  "lessonId": "motion-1",
  "questionText": "Question text",
  "options": ["A", "B", "C", "D"],
  "correctOption": 0,
  "explanation": "Explanation text",
  "difficulty": "MEDIUM",
  "orderIndex": 2
}
```

Rules:

- `lessonId` must reference a published lesson.
- `questionText` and `explanation` are trimmed, required, and length-limited.
- `options` must contain exactly 4 non-empty unique strings after trim and
  case normalization.
- `correctOption` must be an integer from `0` to `3`.
- `difficulty` is `EASY`, `MEDIUM`, or `HARD`; default is `MEDIUM`.
- `orderIndex` must be an integer `>= 1`.
- Question ordering is server-owned. Within each lesson, `orderIndex` starts at
  `1` and is compact: `1, 2, 3, ...`.
- Create at position `N` shifts later questions down. If `N` is greater than the
  current count plus one, the question is appended.
- Update/move compacts the old and new lesson order. Delete compacts following
  questions.

### PUT /api/admin/questions/{id}

Uses the same body and validation as create. The id is taken from the route.
Unknown question returns `404`.

### DELETE /api/admin/questions/{id}

Hard-deletes the question. Unknown question returns `404`.

### PUT /api/admin/questions/reorder

Request:

```json
{
  "lessonId": "motion-1",
  "questionIds": ["motion-1-q2", "motion-1-q1", "motion-1-q3"]
}
```

Rules:

- `lessonId` must reference a published lesson.
- `questionIds` must be non-empty and unique.
- The list must contain every current question id for the lesson exactly once.
- IDs from another lesson, missing IDs, duplicate IDs, and unknown IDs return
  `400`.
- The update runs in one transaction.

Response:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "lessonId": "motion-1",
    "items": [
      { "id": "motion-1-q2", "orderIndex": 1 },
      { "id": "motion-1-q1", "orderIndex": 2 }
    ]
  }
}
```

### Admin-to-Student Question Flow

Admin create/update/delete writes the same `questions` table used by:

- `GET /api/lessons/{id}/questions`
- `POST /api/quiz/submit`

Student question responses remain sanitized and never include `correctOption` or
`explanation`. Quiz attempts store a `review` snapshot at submit time so older
results do not change when Admin later edits or deletes a question.

### Public Questions API Finding

`GET /api/questions` remains public for compatibility and returns sanitized
questions without `correctOption` or `explanation`. If no current client depends
on it, prefer removing it or protecting it in a later cleanup.

## Error Response

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email is invalid"
    }
  ]
}
```

## Pagination

List endpoints with many rows accept:

- `page`, default `1`.
- `limit`, default `20`, max `100`.

Paginated list responses return:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [],
    "total": 0,
    "page": 1,
    "limit": 20
  }
}
```

Do not change response field names without team agreement.
