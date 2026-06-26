import { Injectable } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/current-user';
import { DatabaseRepository } from '../../database/database.repository';
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
}
