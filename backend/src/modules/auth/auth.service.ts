import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

import { AuthenticatedUser } from '../../common/current-user';
import { DatabaseRepository } from '../../database/database.repository';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly database: DatabaseRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.database.findUserByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Email already exists');
    }
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.database.createUser({
      name: dto.name,
      email: dto.email,
      passwordHash,
    });
    return {
      user: this.database.toPublicUser(user),
      ...(await this.issueTokens(user)),
    };
  }

  async login(dto: LoginDto) {
    const user = await this.database.findUserByEmail(dto.email);
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return {
      user: this.database.toPublicUser(user),
      ...(await this.issueTokens(user)),
    };
  }

  async refresh(dto: RefreshTokenDto) {
    const secret = this.refreshSecret();
    try {
      const payload = await this.jwtService.verifyAsync<AuthenticatedUser>(
        dto.refreshToken,
        { secret },
      );
      const user = await this.database.findUserById(payload.id);
      if (!user) {
        throw new UnauthorizedException('Invalid refresh token');
      }
      return this.issueTokens(user);
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  logout() {
    return {};
  }

  private async issueTokens(user: {
    id: string;
    email: string;
    role: 'STUDENT' | 'TEACHER' | 'ADMIN';
  }) {
    const payload: AuthenticatedUser = {
      id: user.id,
      email: user.email,
      role: user.role,
    };
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.accessSecret(),
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: this.refreshSecret(),
        expiresIn: '7d',
      }),
    ]);
    return { accessToken, refreshToken };
  }

  private accessSecret() {
    const secret = this.configService.get<string>('JWT_ACCESS_SECRET');
    if (!secret) {
      throw new UnauthorizedException('JWT access secret is not configured');
    }
    return secret;
  }

  private refreshSecret() {
    const secret = this.configService.get<string>('JWT_REFRESH_SECRET');
    if (!secret) {
      throw new UnauthorizedException('JWT refresh secret is not configured');
    }
    return secret;
  }
}
