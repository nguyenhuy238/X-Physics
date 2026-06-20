import { Injectable } from '@nestjs/common';

import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  register(dto: RegisterDto) {
    return {
      user: { id: 'TODO', name: dto.name, email: dto.email, role: 'STUDENT' },
      accessToken: 'TODO',
      refreshToken: 'TODO',
    };
  }

  login(dto: LoginDto) {
    return {
      user: { id: 'TODO', name: 'Demo User', email: dto.email, role: 'STUDENT' },
      accessToken: 'TODO',
      refreshToken: 'TODO',
    };
  }
}
