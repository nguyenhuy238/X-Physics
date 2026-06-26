import { Injectable } from '@nestjs/common';

import { DatabaseRepository } from '../../database/database.repository';
import { AdminContentDto } from './dto/admin-content.dto';

@Injectable()
export class AdminService {
  constructor(private readonly database: DatabaseRepository) {}

  users() {
    return this.database.adminUsers();
  }

  statistics() {
    return this.database.statistics();
  }

  create(resource: string, dto: AdminContentDto) {
    return { resource, ...dto };
  }

  update(resource: string, id: string, dto: AdminContentDto) {
    return { id, resource, ...dto };
  }

  remove(resource: string, id: string) {
    return { resource, id, deleted: true };
  }
}
