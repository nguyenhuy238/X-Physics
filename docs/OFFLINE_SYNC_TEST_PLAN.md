# Offline Sync Test Plan

## Test Matrix

| Scenario | Expected Result | Actual Result |
|---|---|---|
| Download one lesson online then read offline | Content, LaTeX and simulation load from Hive | Covered by unit-level snapshot tests; device test not run |
| Network fails during download | Existing cache remains unchanged | Code path verified by save-after-all-fetch audit |
| Offline reading reaches end | Progress item is queued durably | Covered by storage/sync tests |
| Restart with pending queue | Queue remains in Hive | Covered by Hive-backed tests |
| Reconnect auto sync | Accepted items are deleted | Covered by `ProgressSyncService` tests |
| Backend 500/network failure | Queue remains, retry metadata updated | Covered by test |
| Partial success | Only accepted item is removed | Covered by Flutter and backend unit tests |
| Conflict/status regression | Completed progress does not decrease | Covered by code and tests for local queue; DB merge patched |
| Manual sync repeated taps | Single-flight prevents duplicate request | Covered by existing test |
| User A/B switch | Cache and queue do not leak | Covered by existing tests |
| Admin updates lesson | Update flag set by fingerprint compare | Covered by fingerprint tests; manual API test not run |
| Offline quiz | Blocked with clear limitation | Covered by AppState test |
| Android airplane mode | Must work on device | Not run in this environment |
| Flutter Web offline | Supported by Hive init; not manually verified | Not run in this environment |

## Automated Tests Added/Updated

Flutter:

- Queued progress never decreases.
- Partial success clears only accepted queue items.
- Sync failure keeps queue and records retry metadata.
- Offline quiz returns no questions and a limitation message.

Backend:

- Sync progress returns accepted items.
- Sync progress returns per-item rejection without dropping successful items.

## Verification Commands

Run from repo root:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
cd backend
npm install
npm run lint
npm run build
npm test
```

## Manual Demo

1. Login as Student A.
2. Open a lesson online and tap download.
3. Enable airplane mode or use the demo offline toggle.
4. Open the downloaded lesson.
5. Scroll to the end.
6. Open Offline Downloads and confirm pending count.
7. Reconnect.
8. Tap Sync Now or wait for auto sync.
9. Confirm banner disappears and backend progress shows completed.
10. Logout, login Student B, confirm A's downloads/queue are hidden.

## Known Limitations

- No automated integration test drives a real device through airplane mode.
- No local asset downloader for remote Markdown images.
- No backend operation-id ledger; progress sync relies on monotonic upsert.
