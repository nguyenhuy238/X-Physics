import { Module } from '@nestjs/common';

import { AuthGuard } from '../../common/auth.guard';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController],
  providers: [AuthGuard, UsersService],
})
export class UsersModule {}
