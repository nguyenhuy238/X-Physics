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
    "orderIndex": 1
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

Request:

```json
{
  "items": [
    {
      "lessonId": "motion-1",
      "progressPercent": 100,
      "quizAttempt": {
        "score": 8,
        "answers": []
      },
      "clientUpdatedAt": "2026-06-20T09:00:00.000Z"
    }
  ]
}
```

## Admin

Admin endpoints require `ADMIN` or `TEACHER` role.

- `GET /api/admin/users`
- `GET /api/admin/statistics`
- `POST /api/admin/chapters`
- `PUT /api/admin/chapters/{id}`
- `DELETE /api/admin/chapters/{id}`
- `POST /api/admin/lessons`
- `PUT /api/admin/lessons/{id}`
- `DELETE /api/admin/lessons/{id}`
- `POST /api/admin/questions`
- `PUT /api/admin/questions/{id}`
- `DELETE /api/admin/questions/{id}`

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

- `pageNumber`, default `1`.
- `pageSize`, default `10`, max `100`.

Do not change response field names without team agreement.
