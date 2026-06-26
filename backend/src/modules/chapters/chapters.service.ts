import { Injectable } from '@nestjs/common';

import { DatabaseRepository } from '../../database/database.repository';

@Injectable()
export class ChaptersService {
  constructor(private readonly database: DatabaseRepository) {}

  findAll() {
    return this.database.listChapters();
  }

  findOne(id: string) {
    return this.database.findChapter(id);
  }

  lessons(chapterId: string) {
    return this.database.listLessonsByChapter(chapterId);
  }
}
