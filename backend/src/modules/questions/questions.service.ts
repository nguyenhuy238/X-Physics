import { Injectable } from '@nestjs/common';

@Injectable()
export class QuestionsService {
  findAll() {
    return [{ id: 'motion-1-q1', question: 'TODO question' }];
  }
}
