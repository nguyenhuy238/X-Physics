import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { JwtService } from "@nestjs/jwt";
import * as bcrypt from "bcrypt";

import { AuthenticatedUser } from "../../common/current-user";
import { DatabaseRepository } from "../../database/database.repository";
import { LoginDto } from "./dto/login.dto";
import { RefreshTokenDto } from "./dto/refresh-token.dto";
import { RegisterDto } from "./dto/register.dto";

@Injectable()
export class AuthService {
  constructor(
    private readonly database: DatabaseRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    if (dto.confirmPassword && dto.confirmPassword !== dto.password) {
      throw new BadRequestException("Password confirmation does not match");
    }
    const email = this.normalizeEmail(dto.email);
    const name = dto.name.trim();
    const existing = await this.database.findUserByEmail(email);
    if (existing) {
      throw new ConflictException("Email already exists");
    }
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.database.createUser({
      name,
      email,
      passwordHash,
    });
    return {
      user: this.database.toPublicUser(user),
      ...(await this.issueTokens(user)),
    };
  }

  async login(dto: LoginDto) {
    const email = this.normalizeEmail(dto.email);
    const user = await this.database.findUserByEmail(email);
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException("Invalid credentials");
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
      if (
        !user ||
        !user.refreshTokenHash ||
        !user.refreshTokenExpiresAt ||
        user.refreshTokenExpiresAt.getTime() <= Date.now() ||
        !(await bcrypt.compare(dto.refreshToken, user.refreshTokenHash))
      ) {
        throw new UnauthorizedException("Invalid refresh token");
      }
      return this.issueTokens(user);
    } catch {
      throw new UnauthorizedException("Invalid refresh token");
    }
  }

  async logout(userId: string) {
    await this.database.clearRefreshToken(userId);
    return {};
  }

  async me(userId: string) {
    const user = await this.database.findUserById(userId);
    if (!user) {
      throw new UnauthorizedException("Invalid access token");
    }
    return this.database.toPublicUser(user);
  }

  private async issueTokens(user: {
    id: string;
    email: string;
    role: "STUDENT" | "TEACHER" | "ADMIN";
  }) {
    const payload: AuthenticatedUser = {
      id: user.id,
      email: user.email,
      role: user.role,
    };
    const refreshExpiresInMs = this.refreshExpiresInMs();
    const refreshTokenExpiresAt = new Date(Date.now() + refreshExpiresInMs);
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.accessSecret(),
        expiresIn:
          this.configService.get<string>("JWT_ACCESS_EXPIRES_IN") ?? "15m",
      }),
      this.jwtService.signAsync(payload, {
        secret: this.refreshSecret(),
        expiresIn:
          this.configService.get<string>("JWT_REFRESH_EXPIRES_IN") ?? "7d",
      }),
    ]);
    await this.database.saveRefreshToken(
      user.id,
      await bcrypt.hash(refreshToken, 10),
      refreshTokenExpiresAt,
    );
    return { accessToken, refreshToken };
  }

  private accessSecret() {
    const secret = this.configService.get<string>("JWT_ACCESS_SECRET");
    if (!secret) {
      throw new UnauthorizedException("JWT access secret is not configured");
    }
    return secret;
  }

  private refreshSecret() {
    const secret = this.configService.get<string>("JWT_REFRESH_SECRET");
    if (!secret) {
      throw new UnauthorizedException("JWT refresh secret is not configured");
    }
    return secret;
  }

  private normalizeEmail(email: string) {
    return email.trim().toLowerCase();
  }

  private refreshExpiresInMs() {
    const configured =
      this.configService.get<string>("JWT_REFRESH_EXPIRES_IN") ?? "7d";
    const match = configured.match(/^(\d+)([smhd])$/);
    if (!match) {
      return 7 * 24 * 60 * 60 * 1000;
    }
    const value = Number(match[1]);
    const unit = match[2] as "s" | "m" | "h" | "d";
    const multipliers = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
    return value * multipliers[unit];
  }
}
