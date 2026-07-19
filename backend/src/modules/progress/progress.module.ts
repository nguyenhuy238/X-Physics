import { Module } from '@nestjs/common';

import { AuthGuard } from '../../common/auth.guard';
import { ProgressController } from './progress.controller';
import { ProgressService } from './progress.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [ProgressController],
  providers: [AuthGuard, ProgressService],
})
export class ProgressModule {}
