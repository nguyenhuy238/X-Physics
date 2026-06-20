import { Controller, Get } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { BadgesService } from './badges.service';

@Controller('badges')
export class BadgesController {
  constructor(private readonly badgesService: BadgesService) {}

  @Get('me')
  me() {
    return ApiResponseDto.ok(this.badgesService.me());
  }
}
