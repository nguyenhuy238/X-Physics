import { Body, Controller, Get, Put } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  me() {
    return ApiResponseDto.ok(this.usersService.me());
  }

  @Put('me')
  updateMe(@Body() dto: UpdateUserDto) {
    return ApiResponseDto.ok(this.usersService.updateMe(dto));
  }
}
