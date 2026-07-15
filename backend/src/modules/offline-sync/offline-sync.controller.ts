import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthGuard } from '../../common/auth.guard';
import { AuthenticatedUser } from '../../common/current-user';
import { RecordDownloadDto } from './dto/record-download.dto';
import { SyncProgressDto } from './dto/sync-progress.dto';
import { OfflineSyncService } from './offline-sync.service';

@Controller('sync')
@UseGuards(AuthGuard)
export class OfflineSyncController {
  constructor(private readonly offlineSyncService: OfflineSyncService) {}

  @Post('progress')
  async syncProgress(
    @Req() request: { user: AuthenticatedUser },
    @Body() dto: SyncProgressDto,
  ) {
    return ApiResponseDto.ok(
      await this.offlineSyncService.syncProgress(request.user, dto),
    );
  }

  @Post('downloads')
  async recordDownload(
    @Req() request: { user: AuthenticatedUser },
    @Body() dto: RecordDownloadDto,
  ) {
    return ApiResponseDto.ok(
      await this.offlineSyncService.recordDownload(request.user, dto),
    );
  }
}
