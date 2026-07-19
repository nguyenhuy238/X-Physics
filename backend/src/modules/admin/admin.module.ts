import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';

import { AuthGuard } from '../../common/auth.guard';
import { RolesGuard } from '../../common/roles.guard';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';

@Module({
  imports: [NotificationsModule],
  controllers: [AdminController],
  providers: [AuthGuard, RolesGuard, AdminService],
})
export class AdminModule {}
