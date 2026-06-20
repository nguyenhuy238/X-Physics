import { Controller, Get } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { SimulationsService } from './simulations.service';

@Controller('simulations')
export class SimulationsController {
  constructor(private readonly simulationsService: SimulationsService) {}

  @Get()
  findAll() {
    return ApiResponseDto.ok(this.simulationsService.findAll());
  }
}
