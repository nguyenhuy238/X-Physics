import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthGuard } from '../../common/auth.guard';
import { AuthenticatedUser } from '../../common/current-user';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return ApiResponseDto.ok(await this.authService.register(dto), 'Registered');
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    return ApiResponseDto.ok(await this.authService.login(dto), 'OK');
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshTokenDto) {
    return ApiResponseDto.ok(await this.authService.refresh(dto));
  }

  @Post('refresh-token')
  async refreshToken(@Body() dto: RefreshTokenDto) {
    return ApiResponseDto.ok(await this.authService.refresh(dto));
  }

  @Post('logout')
  @UseGuards(AuthGuard)
  async logout(@Req() request: { user: AuthenticatedUser }) {
    return ApiResponseDto.ok(await this.authService.logout(request.user.id));
  }

  @Get('me')
  @UseGuards(AuthGuard)
  async me(@Req() request: { user: AuthenticatedUser }) {
    return ApiResponseDto.ok(await this.authService.me(request.user.id));
  }

  @Get('health')
  health() {
    return ApiResponseDto.ok({ module: 'auth' });
  }
}
