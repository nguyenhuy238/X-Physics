import { Injectable } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/current-user';
import { DatabaseRepository } from '../../database/database.repository';
import { UpdateProgressDto } from './dto/update-progress.dto';

@Injectable()
export class ProgressService {
  constructor(private readonly database: DatabaseRepository) {}

  async dashboard(user: AuthenticatedUser) {
    const [profile, completedLessons, totalLessons, badges] = await Promise.all([
      this.database.findUserById(user.id),
      this.database.countCompletedLessons(user.id),
      this.database.countTotalLessons(),
      this.database.listBadgesByUser(user.id),
    ]);
    return {
      coins: profile?.coins ?? 0,
      completedLessons,
      totalLessons,
      badgeCount: badges.length,
    };
  }

  me(user: AuthenticatedUser) {
    return this.database.listProgress(user.id);
  }

  update(user: AuthenticatedUser, dto: UpdateProgressDto) {
    return this.database.upsertProgress({
      userId: user.id,
      lessonId: dto.lessonId,
      status: dto.status,
      progressPercent: dto.progressPercent,
    });
  }
}
