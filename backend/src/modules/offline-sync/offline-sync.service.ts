import { Injectable } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/current-user';
import { DatabaseRepository } from '../../database/database.repository';
import { RecordDownloadDto } from './dto/record-download.dto';
import { SyncProgressDto } from './dto/sync-progress.dto';

@Injectable()
export class OfflineSyncService {
  constructor(private readonly database: DatabaseRepository) {}

  async syncProgress(user: AuthenticatedUser, dto: SyncProgressDto) {
    for (const item of dto.items) {
      await this.database.upsertProgress({
        userId: user.id,
        lessonId: item.lessonId,
        status: item.progressPercent >= 100 ? 'COMPLETED' : 'IN_PROGRESS',
        progressPercent: item.progressPercent,
      });
    }
    return { syncedItems: dto.items.length, conflicts: [] };
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
