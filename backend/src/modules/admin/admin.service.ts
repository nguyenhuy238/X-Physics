import { Injectable } from '@nestjs/common';

import { AdminContentDto } from './dto/admin-content.dto';

@Injectable()
export class AdminService {
  users() {
    return [];
  }

  statistics() {
    return { totalUsers: 0, totalAttempts: 0, completionRate: 0 };
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
