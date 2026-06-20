import { Body, Controller, Get, Param, Post } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { SubmitQuizDto } from './dto/submit-quiz.dto';
import { QuizService } from './quiz.service';

@Controller('quiz')
export class QuizController {
  constructor(private readonly quizService: QuizService) {}

  @Post('submit')
  submit(@Body() dto: SubmitQuizDto) {
    return ApiResponseDto.ok(this.quizService.submit(dto), 'Submitted');
  }

  @Get('attempts/me')
  myAttempts() {
    return ApiResponseDto.ok(this.quizService.myAttempts());
  }

  @Get('attempts/:id')
  attempt(@Param('id') id: string) {
    return ApiResponseDto.ok(this.quizService.attempt(id));
  }
}
