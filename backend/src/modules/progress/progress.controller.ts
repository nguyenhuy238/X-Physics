import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthGuard } from '../../common/auth.guard';
import { AuthenticatedUser } from '../../common/current-user';
import { UpdateProgressDto } from './dto/update-progress.dto';
import { ProgressService } from './progress.service';

@Controller()
@UseGuards(AuthGuard)
export class ProgressController {
  constructor(private readonly progressService: ProgressService) {}

  @Get('dashboard/me')
  async dashboard(@Req() request: { user: AuthenticatedUser }) {
    return ApiResponseDto.ok(await this.progressService.dashboard(request.user));
  }

  @Get('progress/me')
  async me(@Req() request: { user: AuthenticatedUser }) {
    return ApiResponseDto.ok(await this.progressService.me(request.user));
  }

  @Post('progress')
  async update(
    @Req() request: { user: AuthenticatedUser },
    @Body() dto: UpdateProgressDto,
  ) {
    return ApiResponseDto.ok(await this.progressService.update(request.user, dto));
  }
}
