import { Module } from '@nestjs/common';

import { AuthGuard } from '../../common/auth.guard';
import { QuizController } from './quiz.controller';
import { QuizService } from './quiz.service';

@Module({
  controllers: [QuizController],
  providers: [AuthGuard, QuizService],
})
export class QuizModule {}
