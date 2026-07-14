import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:x_physics/core/storage/local_storage_service.dart';
import 'package:x_physics/features/offline/services/progress_sync_service.dart';

// Covers the offline "pending progress" queue and its sync to
// POST /api/sync/progress — see docs/OFFLINE_FLOW.md. This is the
// automated "test mất mạng" deliverable for TV3 (Offline Mode).
//
// Pure Dart Hive test: no widget pump, no platform channel, so it does not
// need a device/emulator to run.
void main() {
  late Directory tempDir;
  const storage = LocalStorageService();

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('x_physics_offline_test');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>('pending_progress');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LocalStorageService pending progress queue', () {
    test('queuePendingProgress stores the item keyed by lessonId', () async {
      await storage.queuePendingProgress({
        'lessonId': 'motion-1',
        'progressPercent': 100,
        'clientUpdatedAt': '2026-07-14T00:00:00.000Z',
      });

      final items = storage.pendingProgressItems();
      expect(items, hasLength(1));
      expect(items.first['lessonId'], 'motion-1');
      expect(storage.hasPendingProgress, isTrue);
    });

    test(
      'queuing twice for the same lesson keeps only the latest value',
      () async {
        await storage.queuePendingProgress({
          'lessonId': 'motion-1',
          'progressPercent': 40,
          'clientUpdatedAt': '2026-07-14T00:00:00.000Z',
        });
        await storage.queuePendingProgress({
          'lessonId': 'motion-1',
          'progressPercent': 100,
          'clientUpdatedAt': '2026-07-14T00:05:00.000Z',
        });

        final items = storage.pendingProgressItems();
        expect(items, hasLength(1));
        expect(items.first['progressPercent'], 100);
      },
    );

    test('different lessons are queued as separate items', () async {
      await storage.queuePendingProgress({
        'lessonId': 'motion-1',
        'progressPercent': 100,
        'clientUpdatedAt': '2026-07-14T00:00:00.000Z',
      });
      await storage.queuePendingProgress({
        'lessonId': 'force-1',
        'progressPercent': 50,
        'clientUpdatedAt': '2026-07-14T00:01:00.000Z',
      });

      expect(storage.pendingProgressItems(), hasLength(2));
    });
  });

  group('ProgressSyncService', () {
    test('posts every queued item and clears the queue on success', () async {
      await storage.queuePendingProgress({
        'lessonId': 'motion-1',
        'progressPercent': 100,
        'clientUpdatedAt': '2026-07-14T00:00:00.000Z',
      });
      await storage.queuePendingProgress({
        'lessonId': 'force-1',
        'progressPercent': 50,
        'clientUpdatedAt': '2026-07-14T00:01:00.000Z',
      });

      String? calledPath;
      Map<String, dynamic>? calledData;
      final service = ProgressSyncService(
        localStorage: storage,
        post: (path, data) async {
          calledPath = path;
          calledData = data;
          return {
            'success': true,
            'data': {'syncedItems': 2, 'conflicts': []},
          };
        },
      );

      final syncedCount = await service.syncPending();

      expect(syncedCount, 2);
      expect(calledPath, '/api/sync/progress');
      expect(calledData!['items'], hasLength(2));
      expect(storage.hasPendingProgress, isFalse);
    });

    test('keeps items queued when the sync request fails', () async {
      await storage.queuePendingProgress({
        'lessonId': 'motion-1',
        'progressPercent': 100,
        'clientUpdatedAt': '2026-07-14T00:00:00.000Z',
      });

      final service = ProgressSyncService(
        localStorage: storage,
        post: (path, data) async => throw Exception('network down'),
      );

      final syncedCount = await service.syncPending();

      expect(syncedCount, 0);
      expect(storage.hasPendingProgress, isTrue);
    });

    test('does nothing when the queue is empty', () async {
      var callCount = 0;
      final service = ProgressSyncService(
        localStorage: storage,
        post: (path, data) async {
          callCount++;
          return {'success': true};
        },
      );

      final syncedCount = await service.syncPending();

      expect(syncedCount, 0);
      expect(callCount, 0);
    });

    test('does not run two sync requests concurrently', () async {
      await storage.queuePendingProgress({
        'lessonId': 'motion-1',
        'progressPercent': 100,
        'clientUpdatedAt': '2026-07-14T00:00:00.000Z',
      });

      var callCount = 0;
      final releasePost = Completer<void>();
      final service = ProgressSyncService(
        localStorage: storage,
        post: (path, data) async {
          callCount++;
          await releasePost.future;
          return {'success': true};
        },
      );

      final first = service.syncPending();
      final second = service.syncPending();
      releasePost.complete();

      expect(await Future.wait([first, second]), [1, 1]);
      expect(callCount, 1);
      expect(storage.hasPendingProgress, isFalse);
    });

    test(
      'keeps newer queued progress written while sync is in flight',
      () async {
        await storage.queuePendingProgress({
          'lessonId': 'motion-1',
          'progressPercent': 40,
          'clientUpdatedAt': '2026-07-14T00:00:00.000Z',
        });

        final releasePost = Completer<void>();
        final service = ProgressSyncService(
          localStorage: storage,
          post: (path, data) async {
            await storage.queuePendingProgress({
              'lessonId': 'motion-1',
              'progressPercent': 100,
              'clientUpdatedAt': '2026-07-14T00:05:00.000Z',
            });
            releasePost.complete();
            return {'success': true};
          },
        );

        final syncedCount = await service.syncPending();
        await releasePost.future;

        expect(syncedCount, 1);
        final items = storage.pendingProgressItems();
        expect(items, hasLength(1));
        expect(items.first['progressPercent'], 100);
      },
    );
  });
}
