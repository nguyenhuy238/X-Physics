# Multi-user Offline Isolation

## 1. Problem

The device can be shared by more than one student. Offline lessons and pending
reading progress must not be keyed only by `lessonId`, because that allows a
later user on the same device to see, modify, delete, or sync another user's
local data.

## 2. Ownership Model

Offline ownership is scoped to the authenticated backend user id
(`XUser.id`). The client never uses email, display name, JWT, password, list
index, or an unstable hash as a local ownership key.

`AppState` only reads, writes, counts, and syncs offline data when the current
authenticated user has a non-empty id. Logout clears the in-memory offline
lesson list, but does not delete that user's Hive records.

## 3. Composite Key Format

Both Hive boxes keep using a single box per data type:

- `offline_lessons`
- `pending_progress`

Records created after this change use:

```text
<userId>::<lessonId>
```

Example:

```text
usr_student_nam::lesson_motion_01
```

The key is built only by `buildUserLessonKey()` in
`lib/core/storage/local_storage_service.dart`. The helper rejects empty
`userId` and empty `lessonId`.

## 4. Offline Lesson Isolation

Offline lesson values include `userId`, `lessonId`, and the serialized lesson
JSON. Reads require both:

- the Hive key has the expected `<userId>::` prefix
- the stored `userId` matches the authenticated user id

This means two users can download the same lesson id and keep independent
records. User B deleting `<userB>::lessonId` cannot delete
`<userA>::lessonId`.

## 5. Pending Progress Isolation

Pending progress values include `userId` and `lessonId`. Queue reads and
snapshots are scoped by authenticated user id. Sync payloads remove the local
`userId` field before calling the backend because the backend derives
ownership from the JWT.

Progress for User A is never returned by the queue APIs for User B, even when
both users have progress for the same lesson id.

## 6. Login and Logout Behavior

On login or bootstrap after token restore, `AppState` reloads
`downloadedLessons` from the scoped offline records for the authenticated user.

On logout or unauthorized token handling, `AppState`:

- increments the auth generation
- clears user-visible offline lesson state from memory
- clears user-sensitive dashboard/profile/quiz state from memory
- keeps Hive records on disk for the owner to use again after logging back in

Pending sync count is computed from the current user id only. A user switch
therefore changes the visible pending count without deleting another user's
queue.

## 7. Reconnect Sync Safety

`ProgressSyncService.syncPending(userId)` snapshots only that user's queue and
uses a per-user concurrent guard. A sync for User A does not block or reuse a
sync Future for User B.

After a successful backend response, the service deletes only snapshot entries
that still match exactly. If a newer progress item is written while sync is in
flight, it remains queued. If another user's item is written while sync is in
flight, it also remains queued.

`AppState` passes a current-user check into `ProgressSyncService`. If logout or
login changes the active user while a sync is in flight, the old sync result is
not applied to local storage or UI state.

## 8. Legacy Data Handling

Legacy `pending_progress` entries keyed only by `lessonId` and without `userId`
are not synced, not assigned to the current user, and not deleted silently.
They remain in Hive as inert legacy data.

Legacy `offline_lessons` entries keyed only by `lessonId` and without `userId`
are not shown in the current user's Offline Downloads list and are not treated
as owned by the current user. A future explicit download creates a scoped copy
for the authenticated user.

## 9. Security Considerations

- JWT, email, password, and display name are never used as Hive ownership keys.
- Backend ownership remains authoritative for sync because the API uses the JWT
  user id server-side.
- The local `userId` field is used only for client-side consistency checks and
  local isolation.
- User-scoped deletes never clear the whole Hive box.

## 10. Automated Tests

Covered by `test/offline_sync_test.dart`:

- two users saving the same lesson id independently
- user-scoped downloaded lesson listing
- cross-user delete isolation
- user-scoped pending progress queues
- empty user id rejection
- sync of one user not sending another user's queue
- re-login sync of the original user's queue
- concurrent sync and in-flight write safety
- legacy pending progress not syncing
- pending sync count not leaking across user switch

## 11. Manual Test Steps

1. Login User A.
2. Download Lesson 1.
3. Turn network off.
4. Read Lesson 1 and create pending progress.
5. Logout.
6. Login User B.
7. Confirm User B does not see Lesson 1 in Offline Downloads.
8. Confirm pending count is 0 for User B.
9. Confirm sync does not send User A progress.
10. User B downloads the same Lesson 1.
11. Confirm A and B have independent ownership records.
12. Logout User B.
13. Login User A.
14. Confirm User A's lesson and pending progress appear again.
15. Turn network on.
16. Sync User A.
17. Confirm only User A queue is cleared.
18. Login User B.
19. Confirm User B cache and queue are unaffected.
