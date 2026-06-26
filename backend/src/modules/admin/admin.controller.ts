import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthGuard } from '../../common/auth.guard';
import { Roles } from '../../common/roles.decorator';
import { RolesGuard } from '../../common/roles.guard';
import {
  AdminChapterDto,
  AdminLessonDto,
  AdminQuestionDto,
} from './dto/admin-content.dto';
import { AdminService } from './admin.service';

@Controller('admin')
@UseGuards(AuthGuard, RolesGuard)
@Roles('ADMIN', 'TEACHER')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('users')
  async users() {
    return ApiResponseDto.ok(await this.adminService.users());
  }

  @Get('statistics')
  async statistics() {
    return ApiResponseDto.ok(await this.adminService.statistics());
  }

  @Get('chapters')
  async chapters() {
    return ApiResponseDto.ok(await this.adminService.chapters());
  }

  @Get('lessons')
  async lessons() {
    return ApiResponseDto.ok(await this.adminService.lessons());
  }

  @Get('questions')
  async questions() {
    return ApiResponseDto.ok(await this.adminService.questions());
  }

  @Post('chapters')
  async createChapter(@Body() dto: AdminChapterDto) {
    return ApiResponseDto.ok(
      await this.adminService.createChapter(dto),
      'Created',
    );
  }

  @Put('chapters/:id')
  async updateChapter(
    @Param('id') id: string,
    @Body() dto: AdminChapterDto,
  ) {
    return ApiResponseDto.ok(await this.adminService.updateChapter(id, dto));
  }

  @Delete('chapters/:id')
  async removeChapter(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.removeChapter(id));
  }

  @Post('lessons')
  async createLesson(@Body() dto: AdminLessonDto) {
    return ApiResponseDto.ok(
      await this.adminService.createLesson(dto),
      'Created',
    );
  }

  @Put('lessons/:id')
  async updateLesson(@Param('id') id: string, @Body() dto: AdminLessonDto) {
    return ApiResponseDto.ok(await this.adminService.updateLesson(id, dto));
  }

  @Delete('lessons/:id')
  async removeLesson(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.removeLesson(id));
  }

  @Post('questions')
  async createQuestion(@Body() dto: AdminQuestionDto) {
    return ApiResponseDto.ok(
      await this.adminService.createQuestion(dto),
      'Created',
    );
  }

  @Put('questions/:id')
  async updateQuestion(
    @Param('id') id: string,
    @Body() dto: AdminQuestionDto,
  ) {
    return ApiResponseDto.ok(await this.adminService.updateQuestion(id, dto));
  }

  @Delete('questions/:id')
  async removeQuestion(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.removeQuestion(id));
  }
}
