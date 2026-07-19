import { Module } from '@nestjs/common';

import { AuthGuard } from '../../common/auth.guard';
import { OfflineSyncController } from './offline-sync.controller';
import { OfflineSyncService } from './offline-sync.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [OfflineSyncController],
  providers: [AuthGuard, OfflineSyncService],
})
export class OfflineSyncModule {}
