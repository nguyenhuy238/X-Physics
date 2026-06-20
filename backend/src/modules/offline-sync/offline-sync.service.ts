import { Injectable } from '@nestjs/common';

import { SyncProgressDto } from './dto/sync-progress.dto';

@Injectable()
export class OfflineSyncService {
  syncProgress(dto: SyncProgressDto) {
    return { syncedItems: dto.items.length, conflicts: [] };
  }
}
