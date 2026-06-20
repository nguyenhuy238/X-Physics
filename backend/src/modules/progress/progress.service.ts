import { Injectable } from '@nestjs/common';

import { UpdateProgressDto } from './dto/update-progress.dto';

@Injectable()
export class ProgressService {
  dashboard() {
    return { coins: 0, completedLessons: 0, totalLessons: 6 };
  }

  me() {
    return [];
  }

  update(dto: UpdateProgressDto) {
    return dto;
  }
}
