import { Injectable } from '@nestjs/common';

import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  me() {
    return {
      id: 'usr_student_nam',
      name: 'Nguyen Van Nam',
      email: 'nam@example.com',
      role: 'STUDENT',
      coins: 0,
    };
  }

  updateMe(dto: UpdateUserDto) {
    return { ...this.me(), ...dto };
  }
}
