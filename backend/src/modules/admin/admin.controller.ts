import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';

import {
  AdminChapterDto,
  AdminLessonDto,
  AdminUsersQueryDto,
  AdminQuestionQueryDto,
  CreateAdminQuestionDto,
  SendNotificationDto,
  ReorderAdminQuestionsDto,
  UpdateAdminQuestionDto,
  AdminQuizAttemptQueryDto,
  CreateAdminQuizAttemptDto,
  UpdateAdminQuizAttemptDto,
} from './dto/admin-content.dto';
import {
  AdminChapterItemDto,
  AdminLessonItemDto,
  AdminQuestionItemDto,
  AdminStatisticsResponseDto,
  AdminUserItemDto,
  AdminUserListResponseDto,
  AdminQuizAttemptItemDto,
  AdminQuizAttemptListResponseDto,
} from './dto/admin-response.dto';

import { ApiResponseDto } from '../../common/api-response.dto';
import { AuthGuard } from '../../common/auth.guard';
import { Roles } from '../../common/roles.decorator';
import { RolesGuard } from '../../common/roles.guard';
import { AdminService } from './admin.service';
import { ApiBearerAuth, ApiBody, ApiExtraModels, ApiOkResponse, ApiParam, ApiQuery, ApiTags, getSchemaPath } from '@nestjs/swagger';

@ApiTags('Admin')
@Controller('admin')
@UseGuards(AuthGuard, RolesGuard)
@Roles('ADMIN', 'TEACHER')
@ApiBearerAuth()
@ApiExtraModels(ApiResponseDto)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('users')
  @ApiOkResponse({
    description: 'Paginated admin user list with optional search and sorting.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: { $ref: getSchemaPath(AdminUserListResponseDto) },
          },
        },
      ],
    },
  })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'sortBy', required: false, enum: ['createdAt', 'name', 'email'] })
  @ApiQuery({ name: 'sortOrder', required: false, enum: ['ASC', 'DESC'] })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async users(@Query() query: AdminUsersQueryDto) {
    return ApiResponseDto.ok(await this.adminService.users(query));
  }

  @Get('users/:id/progress')
  @ApiParam({ name: 'id', description: 'User ID' })
  async userProgress(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.userProgress(id));
  }

  @Post('users/:id/notify')
  @ApiParam({ name: 'id', description: 'User ID' })
  async sendUserNotification(
    @Param('id') id: string,
    @Body() dto: SendNotificationDto,
  ) {
    return ApiResponseDto.ok(
      await this.adminService.sendNotificationToUser(id, dto.title, dto.message, dto.type),
      'Notification sent',
    );
  }


  @Get('statistics')
  @ApiOkResponse({
    description: 'Admin statistics overview.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: { $ref: getSchemaPath(AdminStatisticsResponseDto) },
          },
        },
      ],
    },
  })
  async statistics() {
    return ApiResponseDto.ok(await this.adminService.statistics());
  }

  @Get('chapters')
  @ApiOkResponse({
    description: 'Admin chapter list with aggregate lesson counts.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: {
              type: 'array',
              items: { $ref: getSchemaPath(AdminChapterItemDto) },
            },
          },
        },
      ],
    },
  })
  async chapters() {
    return ApiResponseDto.ok(await this.adminService.chapters());
  }

  @Get('lessons')
  @ApiOkResponse({
    description: 'Admin lesson list with question counts.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: {
              type: 'array',
              items: { $ref: getSchemaPath(AdminLessonItemDto) },
            },
          },
        },
      ],
    },
  })
  async lessons() {
    return ApiResponseDto.ok(await this.adminService.lessons());
  }

  @Get('questions')
  @ApiOkResponse({
    description: 'Admin question list with correct options.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: {
              type: 'array',
              items: { $ref: getSchemaPath(AdminQuestionItemDto) },
            },
          },
        },
      ],
    },
  })
  async questions(@Query() query: AdminQuestionQueryDto) {
    return ApiResponseDto.ok(await this.adminService.questions(query));
  }

  @Get('questions/:id')
  async question(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.question(id));
  }

  @Put('questions/reorder')
  async reorderQuestions(@Body() dto: ReorderAdminQuestionsDto) {
    return ApiResponseDto.ok(await this.adminService.reorderQuestions(dto));
  }

  @Post('chapters')
  @ApiBody({ type: AdminChapterDto })
  @ApiOkResponse({
    description: 'Create or upsert a chapter.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: { $ref: getSchemaPath(AdminChapterItemDto) },
          },
        },
      ],
    },
  })
  async createChapter(@Body() dto: AdminChapterDto) {
    return ApiResponseDto.ok(
      await this.adminService.createChapter(dto),
      'Created',
    );
  }

  @Put('chapters/:id')
  @ApiParam({ name: 'id', description: 'Chapter ID' })
  @ApiBody({ type: AdminChapterDto })
  async updateChapter(
    @Param('id') id: string,
    @Body() dto: AdminChapterDto,
  ) {
    return ApiResponseDto.ok(await this.adminService.updateChapter(id, dto));
  }

  @Delete('chapters/:id')
  @ApiParam({ name: 'id', description: 'Chapter ID' })
  async removeChapter(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.removeChapter(id));
  }

  @Post('lessons')
  @ApiBody({ type: AdminLessonDto })
  @ApiOkResponse({
    description: 'Create or upsert a lesson.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: { $ref: getSchemaPath(AdminLessonItemDto) },
          },
        },
      ],
    },
  })
  async createLesson(@Body() dto: AdminLessonDto) {
    return ApiResponseDto.ok(
      await this.adminService.createLesson(dto),
      'Created',
    );
  }

  @Put('lessons/:id')
  @ApiParam({ name: 'id', description: 'Lesson ID' })
  @ApiBody({ type: AdminLessonDto })
  async updateLesson(@Param('id') id: string, @Body() dto: AdminLessonDto) {
    return ApiResponseDto.ok(await this.adminService.updateLesson(id, dto));
  }

  @Delete('lessons/:id')
  @ApiParam({ name: 'id', description: 'Lesson ID' })
  async removeLesson(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.removeLesson(id));
  }

  @Post('questions')
  @ApiBody({ type: CreateAdminQuestionDto })
  @ApiOkResponse({
    description: 'Create or upsert a question.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: { $ref: getSchemaPath(AdminQuestionItemDto) },
          },
        },
      ],
    },
  })
  async createQuestion(@Body() dto: CreateAdminQuestionDto) {
    return ApiResponseDto.ok(
      await this.adminService.createQuestion(dto),
      'Created',
    );
  }

  @Put('questions/:id')
  @ApiParam({ name: 'id', description: 'Question ID' })
  @ApiBody({ type: UpdateAdminQuestionDto })
  async updateQuestion(
    @Param('id') id: string,
    @Body() dto: UpdateAdminQuestionDto,
  ) {
    return ApiResponseDto.ok(await this.adminService.updateQuestion(id, dto));
  }

  @Delete('questions/:id')
  @ApiParam({ name: 'id', description: 'Question ID' })
  async removeQuestion(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.removeQuestion(id));
  }

  @Get('quiz-attempts')
  @ApiOkResponse({
    description: 'Paginated list of quiz attempts.',
    type: ApiResponseDto,
    schema: {
      allOf: [
        { $ref: getSchemaPath(ApiResponseDto) },
        {
          properties: {
            data: { $ref: getSchemaPath(AdminQuizAttemptListResponseDto) },
          },
        },
      ],
    },
  })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'lessonId', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async quizAttempts(@Query() query: AdminQuizAttemptQueryDto) {
    return ApiResponseDto.ok(await this.adminService.quizAttempts(query));
  }

  @Get('quiz-attempts/:id')
  @ApiParam({ name: 'id', description: 'Attempt ID' })
  async quizAttempt(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.quizAttempt(id));
  }

  @Post('quiz-attempts')
  @ApiBody({ type: CreateAdminQuizAttemptDto })
  async createQuizAttempt(@Body() dto: CreateAdminQuizAttemptDto) {
    return ApiResponseDto.ok(await this.adminService.createQuizAttempt(dto), 'Created');
  }

  @Put('quiz-attempts/:id')
  @ApiParam({ name: 'id', description: 'Attempt ID' })
  @ApiBody({ type: UpdateAdminQuizAttemptDto })
  async updateQuizAttempt(@Param('id') id: string, @Body() dto: UpdateAdminQuizAttemptDto) {
    return ApiResponseDto.ok(await this.adminService.updateQuizAttempt(id, dto));
  }

  @Delete('quiz-attempts/:id')
  @ApiParam({ name: 'id', description: 'Attempt ID' })
  async removeQuizAttempt(@Param('id') id: string) {
    return ApiResponseDto.ok(await this.adminService.removeQuizAttempt(id));
  }
}
