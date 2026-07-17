import { Controller, Get, UseGuards } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthGuard } from '../../common/auth.guard';
import { Roles } from '../../common/roles.decorator';
import { RolesGuard } from '../../common/roles.guard';
import { StatisticsService } from './statistics.service';

@Controller('admin/statistics')
@UseGuards(AuthGuard, RolesGuard)
@Roles('ADMIN', 'TEACHER')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get()
  async overview() {
    return ApiResponseDto.ok(await this.statisticsService.overview());
  }
}
