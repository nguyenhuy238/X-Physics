import { Controller, Get } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { QuestionsService } from './questions.service';

@Controller('questions')
export class QuestionsController {
  constructor(private readonly questionsService: QuestionsService) {}

  @Get()
  findAll() {
    return ApiResponseDto.ok(this.questionsService.findAll());
  }
}
