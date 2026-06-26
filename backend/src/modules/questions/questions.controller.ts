import { Controller, Get } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { QuestionsService } from './questions.service';

@Controller('questions')
export class QuestionsController {
  constructor(private readonly questionsService: QuestionsService) {}

  @Get()
  async findAll() {
    return ApiResponseDto.ok(await this.questionsService.findAll());
  }
}
