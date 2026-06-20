import { Body, Controller, Get, Post } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return ApiResponseDto.ok(this.authService.register(dto), 'Registered');
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return ApiResponseDto.ok(this.authService.login(dto), 'OK');
  }

  @Post('refresh')
  refresh() {
    return ApiResponseDto.ok({ accessToken: 'TODO', refreshToken: 'TODO' });
  }

  @Post('logout')
  logout() {
    return ApiResponseDto.ok({});
  }

  @Get('health')
  health() {
    return ApiResponseDto.ok({ module: 'auth' });
  }
}
