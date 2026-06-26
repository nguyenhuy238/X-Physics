import { Module } from '@nestjs/common';

import { AuthGuard } from '../../common/auth.guard';
import { RolesGuard } from '../../common/roles.guard';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';

@Module({
  controllers: [AdminController],
  providers: [AuthGuard, RolesGuard, AdminService],
})
export class AdminModule {}
