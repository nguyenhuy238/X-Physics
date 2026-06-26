import { Module } from '@nestjs/common';

import { AuthGuard } from '../../common/auth.guard';
import { BadgesController } from './badges.controller';
import { BadgesService } from './badges.service';

@Module({
  controllers: [BadgesController],
  providers: [AuthGuard, BadgesService],
})
export class BadgesModule {}
