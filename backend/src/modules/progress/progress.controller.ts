import { Body, Controller, Get, Post } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { UpdateProgressDto } from './dto/update-progress.dto';
import { ProgressService } from './progress.service';

@Controller()
export class ProgressController {
  constructor(private readonly progressService: ProgressService) {}

  @Get('dashboard/me')
  dashboard() {
    return ApiResponseDto.ok(this.progressService.dashboard());
  }

  @Get('progress/me')
  me() {
    return ApiResponseDto.ok(this.progressService.me());
  }

  @Post('progress')
  update(@Body() dto: UpdateProgressDto) {
    return ApiResponseDto.ok(this.progressService.update(dto));
  }
}
