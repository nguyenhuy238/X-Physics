import { Controller, Get } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { StatisticsService } from './statistics.service';

@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get()
  overview() {
    return ApiResponseDto.ok(this.statisticsService.overview());
  }
}
