import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AdminContentDto } from './dto/admin-content.dto';
import { AdminService } from './admin.service';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('users')
  users() {
    return ApiResponseDto.ok(this.adminService.users());
  }

  @Get('statistics')
  statistics() {
    return ApiResponseDto.ok(this.adminService.statistics());
  }

  @Post(':resource')
  create(@Param('resource') resource: string, @Body() dto: AdminContentDto) {
    return ApiResponseDto.ok(this.adminService.create(resource, dto), 'Created');
  }

  @Put(':resource/:id')
  update(
    @Param('resource') resource: string,
    @Param('id') id: string,
    @Body() dto: AdminContentDto,
  ) {
    return ApiResponseDto.ok(this.adminService.update(resource, id, dto));
  }

  @Delete(':resource/:id')
  remove(@Param('resource') resource: string, @Param('id') id: string) {
    return ApiResponseDto.ok(this.adminService.remove(resource, id));
  }
}
