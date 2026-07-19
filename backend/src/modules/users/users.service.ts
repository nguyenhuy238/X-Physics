import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import * as bcrypt from "bcrypt";

import { DatabaseRepository } from "../../database/database.repository";
import { ChangePasswordDto } from "./dto/change-password.dto";
import { UpdateUserDto } from "./dto/update-user.dto";

@Injectable()
export class UsersService {
  constructor(private readonly database: DatabaseRepository) {}

  async me(userId: string) {
    const user = await this.database.findUserById(userId);
    if (!user) {
      throw new NotFoundException("User not found");
    }
    return this.database.toPublicUser(user);
  }

  async updateMe(userId: string, dto: UpdateUserDto) {
    const user = await this.database.updateUser(userId, {
      name: dto.name?.trim(),
    });
    return this.database.toPublicUser(user);
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    if (dto.newPassword !== dto.confirmNewPassword) {
      throw new BadRequestException({
        message: "Đổi mật khẩu thất bại.",
        errors: [
          {
            field: "confirmNewPassword",
            message: "Mật khẩu xác nhận không khớp.",
          },
        ],
      });
    }
    const user = await this.database.findUserById(userId);
    if (!user) {
      throw new NotFoundException("User not found");
    }
    const currentPasswordMatches = await bcrypt.compare(
      dto.currentPassword,
      user.passwordHash,
    );
    if (!currentPasswordMatches) {
      throw new BadRequestException({
        message: "Đổi mật khẩu thất bại.",
        errors: [
          {
            field: "currentPassword",
            message: "Mật khẩu hiện tại không đúng.",
          },
        ],
      });
    }
    const samePassword = await bcrypt.compare(
      dto.newPassword,
      user.passwordHash,
    );
    if (samePassword) {
      throw new BadRequestException({
        message: "Đổi mật khẩu thất bại.",
        errors: [
          {
            field: "newPassword",
            message: "Mật khẩu mới phải khác mật khẩu hiện tại.",
          },
        ],
      });
    }
    await this.database.updatePassword(
      userId,
      await bcrypt.hash(dto.newPassword, 10),
    );
    return { passwordChanged: true, requiresLogin: true };
  }
}
