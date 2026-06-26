import { Controller, Get, Req, UseGuards } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthGuard } from '../../common/auth.guard';
import { AuthenticatedUser } from '../../common/current-user';
import { BadgesService } from './badges.service';

@Controller('badges')
@UseGuards(AuthGuard)
export class BadgesController {
  constructor(private readonly badgesService: BadgesService) {}

  @Get('me')
  async me(@Req() request: { user: AuthenticatedUser }) {
    return ApiResponseDto.ok(await this.badgesService.me(request.user));
  }
}
