import { Injectable } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/current-user';
import { DatabaseRepository } from '../../database/database.repository';

@Injectable()
export class BadgesService {
  constructor(private readonly database: DatabaseRepository) {}

  me(user: AuthenticatedUser) {
    return this.database.listBadgesByUser(user.id);
  }
}
