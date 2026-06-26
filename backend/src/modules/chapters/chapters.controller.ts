import { Controller, Get, Param } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { ChaptersService } from './chapters.service';

@Controller('chapters')
export class ChaptersController {
  constructor(private readonly chaptersService: ChaptersService) {}

  @Get()
  async findAll() {
    return ApiResponseDto.ok(await this.chaptersService.findAll());
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.chaptersService.findOne(id));
  }

  @Get(':id/lessons')
  async lessons(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.chaptersService.lessons(id));
  }
}
