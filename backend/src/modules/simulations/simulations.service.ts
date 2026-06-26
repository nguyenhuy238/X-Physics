import { Injectable } from '@nestjs/common';

import { DatabaseRepository } from '../../database/database.repository';

@Injectable()
export class SimulationsService {
  constructor(private readonly database: DatabaseRepository) {}

  findAll() {
    return this.database.listSimulations();
  }
}
