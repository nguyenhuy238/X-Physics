import { Injectable } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/current-user';
import { DatabaseRepository } from '../../database/database.repository';
import { RecordDownloadDto } from './dto/record-download.dto';
import { SyncProgressDto } from './dto/sync-progress.dto';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class OfflineSyncService {
  constructor(
    private readonly database: DatabaseRepository,
    private readonly notificationsService: NotificationsService,
  ) {}

  async syncProgress(user: AuthenticatedUser, dto: SyncProgressDto) {
    const accepted: Array<{
      operationId?: string;
      lessonId: string;
      serverState: unknown;
    }> = [];
    const rejected: Array<{
      operationId?: string;
      lessonId: string;
      reason: string;
    }> = [];

    for (const item of dto.items) {
      try {
        const status =
          item.isCompleted || item.progressPercent >= 100
            ? 'COMPLETED'
            : 'IN_PROGRESS';
        const progress = await this.database.upsertProgress({
          userId: user.id,
          lessonId: item.lessonId,
          status,
          progressPercent: item.progressPercent,
        });

        if (status === 'COMPLETED') {
          const lesson = await this.database.findAdminLesson(item.lessonId);
          if (lesson) {
            await this.notificationsService.awardBadgesAndNotify(
              user.id,
              item.lessonId,
              lesson.chapterId,
              false,
            );
          }
        }

        accepted.push({
          operationId: item.operationId,
          lessonId: item.lessonId,
          serverState: progress,
        });
      } catch (error) {
        rejected.push({
          operationId: item.operationId,
          lessonId: item.lessonId,
          reason: error instanceof Error ? error.message : 'Sync item failed',
        });
      }
    }
    return {
      syncedItems: accepted.length,
      accepted,
      rejected,
      conflicts: [],
    };
  }

  // Records a real "lesson downloaded for offline" event so Admin
  // statistics (recent activity, most-downloaded lessons) reflect real
  // usage instead of only seed data. Best-effort from the client's point
  // of view — see AppState.downloadLesson in the Flutter app, which does
  // not block the local download if this call fails.
  async recordDownload(user: AuthenticatedUser, dto: RecordDownloadDto) {
    // Validates the lesson exists (and is published) before recording,
    // mirroring the pattern already used in lessons.service.ts.
    await this.database.findLesson(dto.lessonId);
    await this.database.recordLessonDownload({
      userId: user.id,
      lessonId: dto.lessonId,
      clientDeviceId: dto.clientDeviceId,
    });
    return { recorded: true };
  }
}
