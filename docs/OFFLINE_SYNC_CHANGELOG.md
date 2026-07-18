# Offline Sync Changelog

## Files Added

- `docs/OFFLINE_SYNC_AUDIT.md`: audit findings and status table.
- `docs/OFFLINE_SYNC_ARCHITECTURE.md`: architecture, schema and diagrams.
- `docs/OFFLINE_SYNC_TEST_PLAN.md`: automated/manual test plan.
- `docs/OFFLINE_MODE_USER_GUIDE.md`: end-user offline guide.
- `docs/OFFLINE_SYNC_CHANGELOG.md`: this changelog.

## Files Modified

- `lib/core/storage/local_storage_service.dart`
  - Added operation ids, completion flag, retry metadata and monotonic queue merge.
- `lib/features/offline/services/progress_sync_service.dart`
  - Handles per-item accepted response and only deletes accepted queue entries.
- `lib/features/progress/application/app_state.dart`
  - Added sync loading/error state, response acceptance handling and offline quiz limitation.
- `lib/features/offline/screens/offline_downloads_screen.dart`
  - Pending banner now hides at zero, shows loading and sync errors.
- `lib/features/lessons/screens/lesson_screen.dart`
  - Offline quiz button is disabled for MVP.
- `backend/src/modules/offline-sync/dto/sync-progress.dto.ts`
  - Added `operationId`, `isCompleted` and ISO timestamp validation.
- `backend/src/modules/offline-sync/offline-sync.service.ts`
  - Returns per-item accepted/rejected sync results.
- `backend/src/database/database.repository.ts`
  - Prevents completed progress status regression.
- `test/offline_sync_test.dart`
  - Added queue merge, partial success, retry metadata and offline quiz tests.
- `backend/src/modules/offline-sync/offline-sync.service.spec.ts`
  - Added accepted/rejected backend sync tests.

## Database/Hive Migration

- No Hive box name change.
- Existing pending queue items without `operationId` receive one on next local update.
- Existing offline lesson snapshots remain readable through the legacy metadata fallback.
- No SQL schema migration was required for the MVP patch.

## API Contract Changes

- `POST /api/sync/progress` request items may include `operationId` and `isCompleted`.
- Response now includes `accepted`, `rejected`, `conflicts`, and `syncedItems`.

## Remaining Risk

- Backend reachability is inferred from request success/failure, not from a dedicated health probe.
- Embedded Markdown image assets are not cached locally.
- Offline quiz is intentionally not implemented for MVP.
