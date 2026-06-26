import { Controller, Get, Param } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { LessonsService } from './lessons.service';

@Controller('lessons')
export class LessonsController {
  constructor(private readonly lessonsService: LessonsService) {}

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.lessonsService.findOne(id));
  }

  @Get(':id/simulations')
  async simulations(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.lessonsService.simulations(id));
  }

  @Get(':id/questions')
  async questions(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.lessonsService.questions(id));
  }
}
