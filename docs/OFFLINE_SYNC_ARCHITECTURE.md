# Offline Sync Architecture

## Overview

The MVP offline architecture follows:

Flutter UI -> `AppState` -> offline/progress services -> Hive or REST API -> NestJS backend -> PostgreSQL.

Hive boxes:

- `offline_lessons`: complete lesson snapshots for offline reading.
- `pending_progress`: durable reading-progress queue.

Keys are scoped as `<userId>::<lessonId>`.

## Local Data Schema

Offline lesson snapshot:

- `userId`, `lessonId`
- `lesson`: title, chapter, content Markdown, formula LaTeX, simulation config, public questions, estimated minutes, timestamps
- `metadata`: `contentFingerprint`, `downloadedAt`, `lastCheckedAt`, `serverUpdatedAt`, `updateAvailable`

Pending progress item:

- `userId`, `lessonId`
- `progressPercent`, `isCompleted`
- `clientUpdatedAt`
- `operationId`
- `createdAt`, `retryCount`, `lastError`, `nextRetryAt`

## Conflict Policy

- Reading progress is monotonic: lower values do not replace higher values locally or on the server.
- `COMPLETED` status is preserved once reached.
- Latest queued progress per user/lesson replaces older lower progress.
- Partial backend failures keep rejected items in Hive.

## Retry Policy

Sync uses a per-user single-flight guard. Failed request snapshots stay queued and receive retry metadata. Auto sync is triggered on bootstrap when online and on reconnect. Manual sync is available from Offline Downloads.

## Security

The backend ignores any client-supplied `userId` and uses JWT identity from `AuthGuard`. Offline Hive keys use backend user id, never email/password/token.

Quiz offline is intentionally disabled for MVP to avoid storing answer material or answer-checking logic locally.

## Diagrams

### Download Lesson

```mermaid
sequenceDiagram
  participant UI as Lesson/Offline UI
  participant S as AppState
  participant API as REST API
  participant H as Hive offline_lessons
  UI->>S: downloadLesson(lessonId)
  S->>API: GET lesson
  S->>API: GET simulations
  S->>API: GET questions
  S->>H: save complete snapshot
  S-->>UI: downloadedLessons updated
  S-->>API: POST /api/sync/downloads (best effort)
```

### Read Lesson Offline

```mermaid
sequenceDiagram
  participant UI as LessonScreen
  participant S as AppState
  participant H as Hive offline_lessons
  UI->>S: loadLessonDetail(id)
  S->>S: effectiveOffline == true
  S->>H: get <userId>::<lessonId>
  H-->>S: snapshot
  S-->>UI: Lesson content/simulation/formula
```

### Offline Progress Queue

```mermaid
sequenceDiagram
  participant UI as LessonScreen
  participant S as AppState
  participant H as Hive pending_progress
  UI->>S: updateReadingProgress(lessonId, percent)
  S->>S: effectiveOffline or API failure
  S->>H: put merged item with operationId
  H-->>S: durable queue
```

### Reconnect And Sync

```mermaid
sequenceDiagram
  participant C as Connectivity
  participant S as AppState
  participant P as ProgressSyncService
  participant H as Hive pending_progress
  participant API as POST /api/sync/progress
  C->>S: back online
  S->>P: syncPending(userId)
  P->>H: snapshot queue
  P->>API: items
  API-->>P: accepted/rejected
  P->>H: delete accepted matching snapshot only
  P-->>S: synced count
```

### Cache Version Update

```mermaid
sequenceDiagram
  participant UI as Offline Downloads
  participant S as AppState
  participant API as REST API
  participant H as Hive offline_lessons
  UI->>S: checkDownloadedLessonsForUpdates()
  S->>H: current fingerprint
  S->>API: fetch complete server snapshot
  S->>S: compare fingerprints
  S->>H: update metadata updateAvailable
  UI->>S: updateOfflineLesson()
  S->>API: fetch complete server snapshot
  S->>H: replace only after success
```

### Account Switching

```mermaid
sequenceDiagram
  participant Auth as Auth Flow
  participant S as AppState
  participant H as Hive
  Auth->>S: logout user A
  S->>S: increment authGeneration, clear memory
  Auth->>S: login user B
  S->>H: load keys with B prefix
  H-->>S: B-only downloads/queue
  S-->>Auth: A data remains hidden
```
