import { Controller, Get, Patch, Param, Query, UseGuards, Req } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { AuthGuard } from '../../common/auth.guard';
import { AuthenticatedUser } from '../../common/current-user';
import { ApiResponseDto } from '../../common/api-response.dto';

@Controller('notifications')
@UseGuards(AuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  async getNotifications(
    @Req() request: { user: AuthenticatedUser },
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    const result = await this.notificationsService.getNotifications(request.user.id, pageNum, limitNum);
    return ApiResponseDto.ok(result);
  }

  @Patch('read-all')
  async markAllAsRead(@Req() request: { user: AuthenticatedUser }) {
    const result = await this.notificationsService.markAllAsRead(request.user.id);
    return ApiResponseDto.ok(result, 'All notifications marked as read');
  }

  @Patch(':id/read')
  async markAsRead(
    @Param('id') id: string,
    @Req() request: { user: AuthenticatedUser },
  ) {
    const result = await this.notificationsService.markAsRead(id, request.user.id);
    return ApiResponseDto.ok(result, 'Notification marked as read');
  }
}
