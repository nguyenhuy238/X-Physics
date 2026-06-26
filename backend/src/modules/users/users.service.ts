import { Injectable, NotFoundException } from '@nestjs/common';

import { DatabaseRepository } from '../../database/database.repository';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly database: DatabaseRepository) {}

  async me(userId: string) {
    const user = await this.database.findUserById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return this.database.toPublicUser(user);
  }

  async updateMe(userId: string, dto: UpdateUserDto) {
    const user = await this.database.updateUser(userId, dto);
    return this.database.toPublicUser(user);
  }
}
