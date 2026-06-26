import { Body, Controller, Get, Put, Req, UseGuards } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthGuard } from '../../common/auth.guard';
import { AuthenticatedUser } from '../../common/current-user';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(AuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async me(@Req() request: { user: AuthenticatedUser }) {
    return ApiResponseDto.ok(await this.usersService.me(request.user.id));
  }

  @Put('me')
  async updateMe(
    @Req() request: { user: AuthenticatedUser },
    @Body() dto: UpdateUserDto,
  ) {
    return ApiResponseDto.ok(
      await this.usersService.updateMe(request.user.id, dto),
    );
  }
}
