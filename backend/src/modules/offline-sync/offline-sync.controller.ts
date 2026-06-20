import { Body, Controller, Post } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { SyncProgressDto } from './dto/sync-progress.dto';
import { OfflineSyncService } from './offline-sync.service';

@Controller('sync')
export class OfflineSyncController {
  constructor(private readonly offlineSyncService: OfflineSyncService) {}

  @Post('progress')
  syncProgress(@Body() dto: SyncProgressDto) {
    return ApiResponseDto.ok(this.offlineSyncService.syncProgress(dto));
  }
}
