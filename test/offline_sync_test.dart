import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:x_physics/core/storage/local_storage_service.dart';
import 'package:x_physics/features/offline/models/offline_lesson_model.dart';
import 'package:x_physics/features/offline/services/progress_sync_service.dart';
import 'package:x_physics/features/progress/application/app_state.dart';
import 'package:x_physics/shared/models/x_models.dart';

const userA = 'usr_student_a';
const userB = 'usr_student_b';
const lessonId = 'motion-1';

Lesson _lesson(String title) => Lesson(
  id: lessonId,
  chapterId: 'motion',
  title: title,
  content: 'Lesson content for $title',
  formulaLatex: '',
  estimatedMinutes: 10,
  simulation: FormulaSimulationConfig.empty(),
  questions: const [],
);

Lesson _lessonWithQuestion(String title, String question) => Lesson(
  id: lessonId,
  chapterId: 'motion',
  title: title,
  content: 'Lesson content for $title',
  formulaLatex: r's = v \times t',
  estimatedMinutes: 10,
  simulation: const FormulaSimulationConfig(
    title: 'Motion sim',
    formula: r's = v \times t',
    variables: [
      FormulaVariable(
        symbol: 'v',
        label: 'Velocity',
        unit: 'm/s',
        min: 1,
        max: 10,
        defaultValue: 5,
      ),
    ],
    result: FormulaResult(
      symbol: 's',
      label: 'Distance',
      unit: 'm',
      expression: 'v * t',
    ),
  ),
  questions: [
    Question(
      id: '$lessonId-q1',
      lessonId: lessonId,
      question: question,
      options: const ['A', 'B', 'C', 'D'],
      correctOption: 0,
      explanation: 'Because physics.',
    ),
  ],
);

Map<String, dynamic> _progress(
  String lessonId,
  int percent, [
  String timestamp = '2026-07-14T00:00:00.000Z',
]) => {
  'lessonId': lessonId,
  'progressPercent': percent,
  'clientUpdatedAt': timestamp,
};

// Covers the offline lesson cache, user-scoped pending-progress queue, and
// sync to POST /api/sync/progress. Pure Dart Hive test: no widget pump or
// platform channel needed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const storage = LocalStorageService();

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('x_physics_offline_test');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>('offline_lessons');
    await Hive.openBox<Map>('pending_progress');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('composite key helper', () {
    test('builds stable user/lesson keys and rejects empty parts', () {
      expect(buildUserLessonKey(userA, lessonId), '$userA::$lessonId');
      expect(() => buildUserLessonKey('', lessonId), throwsArgumentError);
      expect(() => buildUserLessonKey(userA, ''), throwsArgumentError);
    });
  });

  group('offline lesson isolation', () {
    test(
      'User A and User B save the same lessonId without overwriting',
      () async {
        await storage.saveOfflineLesson(
          userId: userA,
          lesson: _lesson('A copy'),
        );
        await storage.saveOfflineLesson(
          userId: userB,
          lesson: _lesson('B copy'),
        );

        expect(
          storage.getOfflineLesson(userId: userA, lessonId: lessonId)?.title,
          'A copy',
        );
        expect(
          storage.getOfflineLesson(userId: userB, lessonId: lessonId)?.title,
          'B copy',
        );
      },
    );

    test('User A only reads downloaded lessons owned by A', () async {
      await storage.saveOfflineLesson(userId: userA, lesson: _lesson('A copy'));
      await storage.saveOfflineLesson(userId: userB, lesson: _lesson('B copy'));

      expect(storage.getOfflineLessonIds(userA), [lessonId]);
      expect(storage.getOfflineLessons(userA).single.title, 'A copy');
    });

    test('User B does not see downloads owned by A', () async {
      await storage.saveOfflineLesson(userId: userA, lesson: _lesson('A copy'));

      expect(storage.getOfflineLessonIds(userB), isEmpty);
      expect(
        storage.getOfflineLesson(userId: userB, lessonId: lessonId),
        isNull,
      );
    });

    test('User B cannot delete User A offline lesson', () async {
      await storage.saveOfflineLesson(userId: userA, lesson: _lesson('A copy'));

      await storage.deleteOfflineLesson(userId: userB, lessonId: lessonId);

      expect(
        storage.getOfflineLesson(userId: userA, lessonId: lessonId),
        isNotNull,
      );
    });

    test('empty userId does not write offline lesson', () async {
      expect(
        () => storage.saveOfflineLesson(userId: '', lesson: _lesson('bad')),
        throwsArgumentError,
      );
      expect(storage.offlineLessonsBox().isEmpty, isTrue);
    });

    test(
      'new offline lesson records metadata and stable fingerprint',
      () async {
        final lesson = _lessonWithQuestion(
          'Versioned copy',
          'Original question',
        );

        await storage.saveOfflineLesson(userId: userA, lesson: lesson);

        final snapshot = storage.getOfflineLessonSnapshot(
          userId: userA,
          lessonId: lessonId,
        );
        expect(snapshot, isNotNull);
        expect(snapshot!.metadata.userId, userA);
        expect(snapshot.metadata.lessonId, lessonId);
        expect(snapshot.metadata.contentFingerprint, isNotEmpty);
        expect(snapshot.metadata.updateAvailable, isFalse);
        expect(
          snapshot.metadata.contentFingerprint,
          OfflineLessonVersioning.fingerprintForLesson(lesson),
        );
      },
    );

    test('legacy offline lesson without metadata is still readable', () async {
      await storage.offlineLessonsBox().put('$userA::$lessonId', {
        'userId': userA,
        'lessonId': lessonId,
        'lesson': _lesson('Legacy copy').toJson(),
      });

      final snapshot = storage.getOfflineLessonSnapshot(
        userId: userA,
        lessonId: lessonId,
      );

      expect(snapshot?.lesson.title, 'Legacy copy');
      expect(snapshot?.metadata.contentFingerprint, isNotEmpty);
      expect(snapshot?.metadata.lastCheckedAt, isNull);
      expect(snapshot?.metadata.updateAvailable, isFalse);
    });
  });

  group('offline lesson freshness', () {
    test('compares numeric version before other metadata', () {
      expect(
        OfflineLessonVersioning.compare(localVersion: 1, serverVersion: 2),
        OfflineLessonFreshness.serverNewer,
      );
      expect(
        OfflineLessonVersioning.compare(localVersion: 2, serverVersion: 1),
        OfflineLessonFreshness.localNewer,
      );
      expect(
        OfflineLessonVersioning.compare(localVersion: 2, serverVersion: 2),
        OfflineLessonFreshness.same,
      );
    });

    test('compares UTC timestamps and returns unknown for invalid dates', () {
      expect(
        OfflineLessonVersioning.compare(
          localUpdatedAt: '2026-07-14T08:00:00+07:00',
          serverUpdatedAt: '2026-07-14T02:00:00Z',
        ),
        OfflineLessonFreshness.serverNewer,
      );
      expect(
        OfflineLessonVersioning.compare(
          localUpdatedAt: 'not-a-date',
          serverUpdatedAt: '2026-07-14T02:00:00Z',
        ),
        OfflineLessonFreshness.unknown,
      );
    });

    test('fingerprint changes when cached content changes', () {
      final original = _lessonWithQuestion(
        'Versioned copy',
        'Original question',
      );
      final changedQuestion = _lessonWithQuestion(
        'Versioned copy',
        'Updated question',
      );

      final originalFingerprint = OfflineLessonVersioning.fingerprintForLesson(
        original,
      );
      final updatedFingerprint = OfflineLessonVersioning.fingerprintForLesson(
        changedQuestion,
      );

      expect(updatedFingerprint, isNot(originalFingerprint));
      expect(
        OfflineLessonVersioning.compare(
          localFingerprint: originalFingerprint,
          serverFingerprint: updatedFingerprint,
        ),
        OfflineLessonFreshness.serverNewer,
      );
    });
  });

  group('pending progress isolation', () {
    test('queue progress for A does not appear in B queue', () async {
      await storage.queuePendingProgress(userA, _progress(lessonId, 80));

      expect(storage.pendingProgressItems(userA), hasLength(1));
      expect(storage.pendingProgressItems(userB), isEmpty);
    });

    test('two users can queue the same lessonId independently', () async {
      await storage.queuePendingProgress(userA, _progress(lessonId, 40));
      await storage.queuePendingProgress(userB, _progress(lessonId, 90));

      expect(storage.pendingProgressItems(userA).single['progressPercent'], 40);
      expect(storage.pendingProgressItems(userB).single['progressPercent'], 90);
    });

    test('empty userId does not queue progress', () async {
      expect(
        () => storage.queuePendingProgress('', _progress(lessonId, 80)),
        throwsArgumentError,
      );
      expect(storage.pendingProgressBox().isEmpty, isTrue);
    });

    test('legacy pending progress is not returned for any user', () async {
      await storage.pendingProgressBox().put(
        'legacy-lesson',
        _progress(lessonId, 100),
      );

      expect(storage.pendingProgressItems(userA), isEmpty);
      expect(storage.pendingProgressItems(userB), isEmpty);
    });
  });

  group('ProgressSyncService', () {
    test('Sync B does not send progress owned by A', () async {
      await storage.queuePendingProgress(userA, _progress(lessonId, 100));

      var callCount = 0;
      final service = ProgressSyncService(
        localStorage: storage,
        post: (userId, path, data) async {
          callCount++;
          return {'success': true};
        },
      );

      expect(await service.syncPending(userB), 0);
      expect(callCount, 0);
      expect(storage.pendingProgressItems(userA), hasLength(1));
    });

    test('Login again as A can still sync A queue', () async {
      await storage.queuePendingProgress(userA, _progress(lessonId, 100));

      String? calledUserId;
      final service = ProgressSyncService(
        localStorage: storage,
        post: (userId, path, data) async {
          calledUserId = userId;
          return {'success': true};
        },
      );

      expect(await service.syncPending(userB), 0);
      expect(await service.syncPending(userA), 1);
      expect(calledUserId, userA);
      expect(storage.pendingProgressItems(userA), isEmpty);
    });

    test('empty userId does not call sync API', () async {
      var callCount = 0;
      final service = ProgressSyncService(
        localStorage: storage,
        post: (userId, path, data) async {
          callCount++;
          return {'success': true};
        },
      );

      expect(await service.syncPending(''), 0);
      expect(callCount, 0);
    });

    test(
      'posts every queued item and clears only that user on success',
      () async {
        await storage.queuePendingProgress(userA, _progress('motion-1', 100));
        await storage.queuePendingProgress(userA, _progress('force-1', 50));
        await storage.queuePendingProgress(userB, _progress('electric-1', 30));

        String? calledPath;
        Map<String, dynamic>? calledData;
        final service = ProgressSyncService(
          localStorage: storage,
          post: (userId, path, data) async {
            calledPath = path;
            calledData = data;
            return {
              'success': true,
              'data': {'syncedItems': 2, 'conflicts': []},
            };
          },
        );

        final syncedCount = await service.syncPending(userA);

        expect(syncedCount, 2);
        expect(calledPath, '/api/sync/progress');
        expect(calledData!['items'], hasLength(2));
        expect((calledData!['items'] as List).first, isNot(contains('userId')));
        expect(storage.pendingProgressItems(userA), isEmpty);
        expect(storage.pendingProgressItems(userB), hasLength(1));
      },
    );

    test('keeps items queued when the sync request fails', () async {
      await storage.queuePendingProgress(userA, _progress(lessonId, 100));

      final service = ProgressSyncService(
        localStorage: storage,
        post: (userId, path, data) async => throw Exception('network down'),
      );

      expect(await service.syncPending(userA), 0);
      expect(storage.hasPendingProgress(userA), isTrue);
    });

    test(
      'does not run two sync requests for the same user concurrently',
      () async {
        await storage.queuePendingProgress(userA, _progress(lessonId, 100));

        var callCount = 0;
        final releasePost = Completer<void>();
        final service = ProgressSyncService(
          localStorage: storage,
          post: (userId, path, data) async {
            callCount++;
            await releasePost.future;
            return {'success': true};
          },
        );

        final first = service.syncPending(userA);
        final second = service.syncPending(userA);
        releasePost.complete();

        expect(await Future.wait([first, second]), [1, 1]);
        expect(callCount, 1);
        expect(storage.hasPendingProgress(userA), isFalse);
      },
    );

    test(
      'concurrent sync only deletes matching snapshot for that user',
      () async {
        await storage.queuePendingProgress(userA, _progress(lessonId, 40));

        final service = ProgressSyncService(
          localStorage: storage,
          post: (userId, path, data) async {
            await storage.queuePendingProgress(
              userA,
              _progress(lessonId, 100, '2026-07-14T00:05:00.000Z'),
            );
            return {'success': true};
          },
        );

        expect(await service.syncPending(userA), 1);
        expect(storage.pendingProgressItems(userA), hasLength(1));
        expect(
          storage.pendingProgressItems(userA).single['progressPercent'],
          100,
        );
      },
    );

    test(
      'item from another user written while sync is in flight is not deleted',
      () async {
        await storage.queuePendingProgress(userA, _progress(lessonId, 40));

        final service = ProgressSyncService(
          localStorage: storage,
          post: (userId, path, data) async {
            await storage.queuePendingProgress(userB, _progress(lessonId, 90));
            return {'success': true};
          },
        );

        expect(await service.syncPending(userA), 1);
        expect(storage.pendingProgressItems(userA), isEmpty);
        expect(storage.pendingProgressItems(userB), hasLength(1));
      },
    );

    test('legacy pending progress is never synced automatically', () async {
      await storage.pendingProgressBox().put(
        'legacy-lesson',
        _progress(lessonId, 100),
      );

      var callCount = 0;
      final service = ProgressSyncService(
        localStorage: storage,
        post: (userId, path, data) async {
          callCount++;
          return {'success': true};
        },
      );

      expect(await service.syncPending(userA), 0);
      expect(callCount, 0);
      expect(storage.pendingProgressBox().containsKey('legacy-lesson'), isTrue);
    });

    test(
      'does not remove queue if user becomes inactive before apply',
      () async {
        await storage.queuePendingProgress(userA, _progress(lessonId, 100));
        var activeUser = userA;

        final service = ProgressSyncService(
          localStorage: storage,
          isUserActive: (userId) => activeUser == userId,
          post: (userId, path, data) async {
            activeUser = userB;
            return {'success': true};
          },
        );

        expect(await service.syncPending(userA), 0);
        expect(storage.pendingProgressItems(userA), hasLength(1));
      },
    );
  });

  group('AppState user switching', () {
    test('logout/login user switch does not leak pendingSyncCount', () async {
      await storage.queuePendingProgress(userA, _progress(lessonId, 100));

      final state = AppState();
      addTearDown(state.dispose);

      state.user = const XUser(
        id: userA,
        name: 'Student A',
        email: 'a@example.com',
        role: 'STUDENT',
      );
      expect(state.pendingSyncCount, 1);

      state.user = const XUser(
        id: userB,
        name: 'Student B',
        email: 'b@example.com',
        role: 'STUDENT',
      );
      expect(state.pendingSyncCount, 0);

      state.user = const XUser(
        id: userA,
        name: 'Student A',
        email: 'a@example.com',
        role: 'STUDENT',
      );
      expect(state.pendingSyncCount, 1);
    });
  });
}
