import { Controller, Get, Param } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { ChaptersService } from './chapters.service';

@Controller('chapters')
export class ChaptersController {
  constructor(private readonly chaptersService: ChaptersService) {}

  @Get()
  findAll() {
    return ApiResponseDto.ok(this.chaptersService.findAll());
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return ApiResponseDto.ok(this.chaptersService.findOne(id));
  }

  @Get(':id/lessons')
  lessons(@Param('id') id: string) {
    return ApiResponseDto.ok(this.chaptersService.lessons(id));
  }
}
