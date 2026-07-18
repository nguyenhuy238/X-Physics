# Offline Sync Audit

Audit date: 2026-07-18

## Scope

Reviewed Flutter offline reading, Hive local storage, connectivity listener, pending progress queue, manual/auto sync, lesson cache versioning, account switching, quiz offline behavior, and backend `/api/sync/*` implementation.

## Source Structure

- Flutter app: `lib/`
- Offline feature: `lib/features/offline`
- App state/orchestration: `lib/features/progress/application/app_state.dart`
- Lesson reading: `lib/features/lessons`
- Quiz: `lib/features/quiz`
- Storage: `lib/core/storage/local_storage_service.dart`
- API client/endpoints: `lib/core/network`, `lib/core/constants`
- Backend sync: `backend/src/modules/offline-sync`
- Backend progress/database: `backend/src/modules/progress`, `backend/src/database`
- Existing tests: `test/offline_sync_test.dart`, `backend/src/modules/offline-sync/offline-sync.service.spec.ts`

## Current Flows

- Download one lesson: UI -> `AppState.downloadLesson` -> fetch lesson, simulations, questions -> `OfflineService.saveLesson` -> Hive `offline_lessons`.
- Download chapter: UI -> `AppState.downloadChapter` -> `loadChapterDetail` if needed -> repeated `downloadLesson`.
- Read online: lesson screen -> `AppState.loadLessonDetail` -> API unless cached.
- Read offline: lesson screen -> `AppState.loadLessonDetail` -> user-scoped Hive snapshot when `effectiveOffline`.
- Queue progress: lesson scroll >= 90% -> `AppState.updateReadingProgress` -> API if online, Hive `pending_progress` if offline/fail.
- Auto sync: connectivity back online or bootstrap online -> `ProgressSyncService.syncPending`.
- Manual sync: Offline Downloads -> `AppState.syncNow`.
- Account switch: `_authGeneration` guard, user-scoped keys, in-memory offline state refresh.
- Admin update detection: downloads screen or cached online lesson load -> fetch complete lesson -> compare fingerprint -> update metadata.

## Audit Table

| Item | Status | Evidence | Issue | Severity |
|---|---|---|---|---|
| Hive bootstrap | COMPLETE | `main.dart` opens `offline_lessons`, `pending_progress` | None found | P3 |
| User-scoped offline cache | COMPLETE | `buildUserLessonKey`, `OfflineService.getSnapshot` | Legacy unscoped entries intentionally inert | P3 |
| Snapshot completeness | PARTIAL | `_fetchCompleteLessonFromApi` fetches lesson/simulation/questions before save | Embedded Markdown images are not asset-cached | P2 |
| Atomic cache replace | COMPLETE | Save occurs only after all fetches complete | None found | P3 |
| Cache fingerprint | COMPLETE | `OfflineLessonVersioning.fingerprintForLesson` includes content, formula, simulation, questions | Does not include external assets | P2 |
| Connectivity detection | PARTIAL | `ConnectivityService` wraps connectivity_plus | Does not prove backend reachability | P1 |
| Bootstrap sync | COMPLETE | `bootstrap()` calls `_syncPendingForCurrentUser()` when online | Uses interface online state only | P2 |
| Pending queue durability | COMPLETE | Hive `pending_progress` | None found | P3 |
| Queue idempotency metadata | PARTIAL -> COMPLETE | Added `operationId`, `createdAt`, retry metadata | No backend idempotency table; progress upsert is idempotent by user/lesson | P2 |
| Prevent progress decrease | COMPLETE | Queue merge and DB `greatest()` | None found after fix | P1 |
| Prevent status regression | BROKEN -> COMPLETE | DB upsert used `status = excluded.status`; fixed to preserve completed status | Fixed | P1 |
| Concurrent sync | COMPLETE | `ProgressSyncService._runningSyncByUser` | None found | P1 |
| Partial sync | BROKEN -> COMPLETE | Backend formerly all-or-failure; now returns accepted/rejected and client deletes accepted only | Fixed for progress sync | P1 |
| Manual sync UI | PARTIAL -> COMPLETE | Added `isSyncingProgress` and `syncError` banner state | Detailed per-item UI not yet shown | P2 |
| Download tracking | COMPLETE | `recordDownload` is best-effort client-side | Duplicate null device rows can be analytics noise | P3 |
| Account isolation | COMPLETE | User-scoped keys and auth generation guard | None found | P0 |
| Quiz offline | BROKEN -> NOT_REQUIRED_FOR_MVP | Offline quiz was reachable; now blocked with explicit limitation | Offline quiz package not implemented | P1 |
| Backend ownership | COMPLETE | `AuthGuard`, `OfflineSyncController` uses `request.user.id` | None found | P0 |
| Backend validation | COMPLETE | Global `ValidationPipe`, DTO validators | Added ISO date validation | P1 |
| Backend idempotency | PARTIAL | `progress` unique `(user_id, lesson_id)` and monotonic merge | No operation-id ledger | P2 |

## Fixed

- Added durable queue metadata: `operationId`, `isCompleted`, retry count, last error, next retry time.
- Queue merge no longer reduces reading progress.
- Progress sync client now deletes only backend-accepted items.
- Backend progress sync now returns per-item accepted/rejected result.
- Backend progress status no longer regresses from `COMPLETED` to `IN_PROGRESS`.
- Manual sync UI has loading/error state and banner disappears when queue is empty.
- Offline quiz is disabled for MVP and documented as intentional.

## Remaining Limitations

- Connectivity does not actively probe backend reachability.
- Markdown images are not downloaded as local assets.
- No backend operation-id ledger for historical idempotency; current progress sync is idempotent by `(userId, lessonId)`.
- Chapter download UI does not expose per-lesson retry detail.
- Integration/device airplane-mode tests were not run in this environment.

## Conclusion

- Offline Mode: PARTIAL
- Progress Sync: COMPLETE for MVP
- Cache Versioning: PARTIAL
- Account Isolation: COMPLETE
- Offline Quiz: NOT_REQUIRED_FOR_MVP
