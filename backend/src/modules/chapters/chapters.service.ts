import { Injectable } from '@nestjs/common';

@Injectable()
export class ChaptersService {
  findAll() {
    return [{ id: 'motion', title: 'Chuyen dong co hoc', lessonCount: 2 }];
  }

  findOne(id: string) {
    return { id, title: 'TODO chapter detail' };
  }

  lessons(chapterId: string) {
    return [{ id: `${chapterId}-1`, chapterId, title: 'TODO lesson' }];
  }
}
