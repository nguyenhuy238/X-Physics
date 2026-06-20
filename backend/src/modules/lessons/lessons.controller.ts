import { Controller, Get, Param } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { LessonsService } from './lessons.service';

@Controller('lessons')
export class LessonsController {
  constructor(private readonly lessonsService: LessonsService) {}

  @Get(':id')
  findOne(@Param('id') id: string) {
    return ApiResponseDto.ok(this.lessonsService.findOne(id));
  }

  @Get(':id/simulations')
  simulations(@Param('id') id: string) {
    return ApiResponseDto.ok(this.lessonsService.simulations(id));
  }

  @Get(':id/questions')
  questions(@Param('id') id: string) {
    return ApiResponseDto.ok(this.lessonsService.questions(id));
  }
}
