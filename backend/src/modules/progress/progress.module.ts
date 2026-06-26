import { Module } from '@nestjs/common';

import { AuthGuard } from '../../common/auth.guard';
import { ProgressController } from './progress.controller';
import { ProgressService } from './progress.service';

@Module({
  controllers: [ProgressController],
  providers: [AuthGuard, ProgressService],
})
export class ProgressModule {}
