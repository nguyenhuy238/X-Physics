import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';

import { AuthGuard } from '../../common/auth.guard';
import { QuizController } from './quiz.controller';
import { QuizService } from './quiz.service';

@Module({
  imports: [NotificationsModule],
  controllers: [QuizController],
  providers: [AuthGuard, QuizService],
})
export class QuizModule {}
