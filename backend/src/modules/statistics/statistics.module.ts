import { Module } from '@nestjs/common';

import { AuthGuard } from '../../common/auth.guard';
import { RolesGuard } from '../../common/roles.guard';
import { StatisticsController } from './statistics.controller';
import { StatisticsService } from './statistics.service';

@Module({
  controllers: [StatisticsController],
  providers: [AuthGuard, RolesGuard, StatisticsService],
})
export class StatisticsModule {}
