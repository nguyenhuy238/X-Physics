import { Injectable } from '@nestjs/common';

@Injectable()
export class SimulationsService {
  findAll() {
    return [{ id: 'sim-svt', expression: 'v * t' }];
  }
}
